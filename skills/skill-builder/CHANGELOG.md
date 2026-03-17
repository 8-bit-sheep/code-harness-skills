# Changelog - Skill Builder

Track improvements and evolution of the skill-builder skill.

## 2026-03-08 - Eval-Driven Iteration and Description Optimization

**Trigger:** Comparison with official Anthropic skill-creator revealed major gaps in testing and optimization capabilities.

**New Scripts (3):**
- `scripts/test_triggers.sh` — Test whether a skill triggers for given prompts using `claude -p`. Supports multiple runs per query for reliability, saves results JSON.
- `scripts/run_skill_eval.sh` — Run with-skill vs baseline (without-skill) comparison. Spawns parallel runs, captures timing/token data, organizes into iteration directories.
- `scripts/optimize_description.sh` — Iteratively improve a skill's description for triggering accuracy. Generates eval queries, splits 60/40 train/test, runs optimization loop, selects best by test score to avoid overfitting.

**New Agent Prompts (3):**
- `agents/grader.md` — Evidence-based assertion evaluation with eval quality critique
- `agents/comparator.md` — Blind A/B comparison between skill outputs
- `agents/analyzer.md` — Surface patterns hidden by aggregate statistics

**New Resources (1):**
- `resources/schemas.md` — JSON schemas for evals.json, grading.json, timing.json, trigger_eval_set.json, and workspace directory structure

**SKILL.md Rewrite:**
- Added core workflow: Draft → Test → Grade → Improve → Repeat
- Added "Pushy Descriptions" guidance (combat under-triggering)
- Added "Explain the Why" philosophy (reasoning > rigid rules)
- Added "Generalize from Feedback" guidance (avoid overfitting to test cases)
- Added description optimization section
- Added agent prompts and eval scripts to Available Scripts table
- Updated description to be more "pushy" itself

**Inspiration:** Official Anthropic skill-creator at `anthropics/claude-plugins-official`

**Validation:**
- [x] All 5 scripts executable
- [x] SKILL.md under 175 lines (well within 300 target)
- [x] Agent prompts follow grading.json field naming convention (text/passed/evidence)
- [x] Schemas cover all JSON formats used by scripts

---

## 2025-11-24 - Self-Improvement: Added Self-Improvement Capabilities

**Issue/Opportunity:**
- User asked: "can you see if it includes instructions that skills should self modify themselves?"
- Discovered that skill-builder did not include guidance for skills to self-improve during execution
- This is a missed opportunity - skills should evolve based on real-world usage

**Change:**
- Added workflow step 11 "Self-Improve During Execution" to SKILL.md:154
- Added best practice #6 for self-improvement to SKILL.md:182
- Updated "When to Use" triggers to include self-improvement scenarios to SKILL.md:29-31
- Created new resource: `resources/self_improvement_guide.md` (395 lines)
  - Complete self-improvement workflow
  - When and how to self-improve
  - Common self-improvement patterns with examples
  - Testing guidelines
  - Real-world scenarios
- Updated `resources/skill_template.md`:
  - Added "Self-Improvement" section to SKILL.md template
  - Added CHANGELOG.md template for tracking improvements
  - Updated checklist to include self-improvement readiness items
- Condensed SKILL.md from 510 lines → 237 lines (under 300 target)
  - Moved detailed workflow to resources
  - Condensed best practices with links to detailed guides

**Trigger:**
- User explicitly requested: "yes please improve it so it can self improve"
- Recognized this as a meta self-improvement: improving the skill that improves skills

**Impact:**
- All new skills created will include self-improvement capabilities
- Skills will now proactively fix issues during execution
- Skills will evolve and improve over time based on real usage
- Better user experience as skills become more robust automatically
- Reduced maintenance burden as skills self-maintain

**Validation:**
- [x] Changes validated with validate_skill.sh
- [x] SKILL.md now 237 lines (target: ≤300) ✓
- [x] All required sections present ✓
- [x] 2 resources found (skill_template.md, self_improvement_guide.md) ✓
- [x] User informed of improvements throughout implementation

**Meta-observation:**
This improvement is itself an example of the self-improvement pattern:
1. ✓ Identified opportunity during execution (answering user question)
2. ✓ Informed user about the finding
3. ✓ Implemented comprehensive self-improvement capabilities
4. ✓ Validated changes
5. ✓ Logged improvement (this CHANGELOG)
6. ✓ Completing original task (answering user's question)

---

## Earlier - Initial Creation

- Created skill-builder structure following Anthropic Agent Skills spec
- Implemented create_skill.sh for scaffolding new skills
- Implemented validate_skill.sh for checking skill compliance
- Created skill_template.md resource with templates and checklists
- Supports both global (~/.claude/skills/) and project (.claude/skills/) skills
