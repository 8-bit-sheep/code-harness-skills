---
name: Skill Builder
description: Create new Anthropic Agent Skills, test them with eval-driven iteration, and optimize descriptions for triggering accuracy. Use when user asks to create a new skill, improve an existing skill, test skill quality, optimize skill descriptions, add skill functionality, or wants to build a custom workflow. Also use when analyzing why a skill under-triggers or produces poor results.
---

# Skill Builder

Create, test, and iteratively improve Anthropic Agent Skills.

## Quick Start

```bash
# Create a new skill
scripts/create_skill.sh --project my-skill "Does X. Use when user asks for Y."

# Validate a skill
scripts/validate_skill.sh my-skill

# Test skill triggers
scripts/test_triggers.sh /path/to/skill trigger_eval_set.json

# Run full eval (with-skill vs baseline)
scripts/run_skill_eval.sh /path/to/skill evals.json

# Optimize description for better triggering
scripts/optimize_description.sh /path/to/skill
```

## When to Use This Skill

- User asks to "create a skill" or "make a new skill"
- User wants to **test** or **evaluate** a skill's quality
- User wants to **optimize** a skill's description for better triggering
- User says "the skill isn't triggering" or "the skill gives bad results"
- **During skill execution**: When you discover issues in ANY skill
- **Self-improvement**: When a script fails or could be enhanced

## Core Workflow: Draft → Test → Improve → Repeat

The key to good skills is iteration. Don't just write and ship — test, get feedback, improve.

### 1. Capture Intent

Understand what the skill should do:
- What should this skill enable Claude to do?
- When should this skill trigger? (what user phrases/contexts)
- What's the expected output format?
- Are the outputs objectively verifiable? (→ use automated evals)

### 2. Create Structure

```bash
scripts/create_skill.sh --global|--project <name> "<description with triggers>"
```

Creates: `SKILL.md`, `scripts/example_script.sh`, `resources/reference.md`

### 3. Write the Skill

**Description (most critical):** The description determines triggering. Be slightly "pushy" — list scenarios where the skill should activate, including edge cases. Claude tends to under-trigger, so err on the side of being explicit.

Instead of: `"Manages database migrations."`

Write: `"Manage database migrations including schema changes, rollbacks, and seed data. Use when user mentions migrations, database schema, ALTER TABLE, asks to update the database, or wants to roll back a deployment, even if they don't explicitly say 'migration'."`

**Instructions:** Explain the *why* behind what you're asking the model to do. Today's models are smart — they generalize better from reasoning than from rigid rules. If you find yourself writing ALWAYS or NEVER in caps, reframe it as an explanation of why it matters.

**Progressive disclosure:** Keep SKILL.md under 300 lines. Move detailed references to `resources/`, automation to `scripts/`.

### 4. Write Test Cases

Create 2-3 realistic test prompts in `evals.json`:

```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "realistic user prompt with context and details",
      "expected_output": "what good output looks like",
      "assertions": ["Output contains valid JSON", "No placeholder text remains"]
    }
  ]
}
```

See [resources/schemas.md](resources/schemas.md) for full schema.

### 5. Run Evals

```bash
scripts/run_skill_eval.sh /path/to/skill evals.json
```

This spawns parallel with-skill and baseline runs, captures timing/tokens, saves to `workspace/iteration-N/`.

### 6. Grade Results

Use the grader agent (`agents/grader.md`) to evaluate assertions. For programmatic assertions, write and run a script rather than eyeballing — it's faster and reusable.

### 7. Improve and Repeat

Read transcripts (not just final outputs). Look for:
- Wasted effort the skill is causing (remove those instructions)
- Patterns across test cases (bundle repeated scripts)
- Feedback from users (generalize, don't overfit to examples)

Rerun with `--iteration N+1`. Keep going until feedback is empty or you're not making progress.

### 8. Optimize Description

After the skill is stable:

```bash
scripts/optimize_description.sh /path/to/skill
```

Generates 20 trigger eval queries, splits 60/40 train/test, iteratively improves the description, and selects by test accuracy to avoid overfitting.

### 9. Validate

```bash
scripts/validate_skill.sh my-skill
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `create_skill.sh` | Scaffold new skill structure |
| `validate_skill.sh` | Check skill follows specification |
| `test_triggers.sh` | Test if skill triggers for given prompts |
| `run_skill_eval.sh` | Run with-skill vs baseline comparison |
| `optimize_description.sh` | Iteratively improve description triggering |

## Agent Prompts

Use these when spawning subagents for evaluation:

| Agent | When to Use |
|-------|-------------|
| `agents/grader.md` | Evaluate assertions against outputs with evidence |
| `agents/comparator.md` | Blind A/B comparison between two outputs |
| `agents/analyzer.md` | Find patterns hidden by aggregate stats |

## Resources

| Resource | Content |
|----------|---------|
| [schemas.md](resources/schemas.md) | JSON schemas for evals, grading, triggers |
| [skill_template.md](resources/skill_template.md) | Templates and naming conventions |
| [self_improvement_guide.md](resources/self_improvement_guide.md) | How skills self-improve |
| [long_running_patterns.md](resources/long_running_patterns.md) | Multi-session continuity |

## Best Practices

1. **Pushy descriptions** — Combat under-triggering by listing specific scenarios, including "even if they don't explicitly ask for X"
2. **Explain the why** — Reasoning > rigid rules. Models generalize from understanding, not from ALL CAPS INSTRUCTIONS
3. **Generalize from feedback** — Don't overfit to test cases. Your skill will be used across many different prompts
4. **Keep it lean** — Remove instructions that aren't pulling their weight. Read transcripts to find unproductive steps
5. **Bundle repeated work** — If every test run independently writes a similar helper script, bundle it in `scripts/`
6. **Progressive disclosure** — SKILL.md ≤300 lines. Details in resources/, automation in scripts/
7. **Test before shipping** — Run at least one eval iteration. Untested skills accumulate subtle issues

## Notes

- **Global skills** (`~/.claude/skills/`) are available across all projects
- **Project skills** (`.claude/skills/`) are specific to one project
- Scripts run without loading into context (saves tokens)
- Resources load only when needed
