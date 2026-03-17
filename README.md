# Code Harness Skills

Reusable [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills for software development workflows. Works with any project, any language.

## Installation

### Install the full marketplace

```bash
# In Claude Code
/plugin marketplace add sunholo-data/code-harness-skills
```

### Install individual skills

```bash
/plugin install skill-builder@sunholo-data/code-harness-skills
/plugin install sprint-planner@sunholo-data/code-harness-skills
/plugin install release-manager@sunholo-data/code-harness-skills
# ... etc
```

### Local development

```bash
git clone https://github.com/sunholo-data/code-harness-skills
# In Claude Code:
/plugin marketplace add ./code-harness-skills
```

## Available Skills

### Meta / Tooling

| Skill | Description |
|-------|-------------|
| **skill-builder** | Create, test, evaluate, and optimize Claude Code skills with eval-driven iteration |
| **headless-runner** | Run Claude Code programmatically in headless mode for CI/CD, automation, and agent workflows |
| **cloud-setup** | Set up development environments in cloud/mobile Claude Code sessions |

### Code Quality

| Skill | Description |
|-------|-------------|
| **codebase-organizer** | Monitor file sizes and split large files into AI-friendly modules |
| **test-coverage-guardian** | Analyze test coverage, identify gaps, detect dead code, enforce quality gates |
| **perf-reviewer** | Review code for performance issues, run benchmarks, identify optimizations |

### Project Management

| Skill | Description |
|-------|-------------|
| **sprint-planner** | Analyze design docs, calculate velocity, create realistic sprint plans |
| **sprint-executor** | Execute sprint plans with TDD, milestone tracking, and checkpoint validation |
| **design-doc-creator** | Create structured design documents with systemic analysis |
| **release-manager** | Automate releases with version bumps, changelogs, tags, and CI verification |

### Collaboration

| Skill | Description |
|-------|-------------|
| **github-issue-triage** | Monitor and triage GitHub issues against design docs and implementation status |
| **agent-inbox** | Cross-agent messaging with inbox management and handoff patterns |

## Configuration

Skills use environment variables with sensible defaults. Each skill documents its configuration in a `## Configuration` section within its SKILL.md.

**Common variables:**

| Variable | Default | Used By |
|----------|---------|---------|
| `TEST_CMD` | `make test` | Most skills |
| `LINT_CMD` | `make lint` | Most skills |
| `BUILD_CMD` | `make build` | Most skills |
| `SOURCE_DIR` | `.` | codebase-organizer |
| `DESIGN_DOCS_DIR` | `design_docs/` | design-doc-creator, sprint-planner, github-issue-triage |
| `COVERAGE_TARGET` | `80` | test-coverage-guardian |
| `SPRINT_STATE_DIR` | `.sprint-state` | sprint-planner, sprint-executor |

## Quick Start

### Create your own skill

The **skill-builder** skill is a meta-skill that helps you create, test, and optimize new skills:

```
User: "Create a skill for database migration management"
Claude: [Uses skill-builder to scaffold, test, and iterate on a new skill]
```

### Organize your codebase

```
User: "Check file sizes and split any large files"
Claude: [Uses codebase-organizer to find files >800 lines and propose splits]
```

### Plan and execute a sprint

```
User: "Plan a sprint from the auth-redesign design doc"
Claude: [Uses sprint-planner to analyze velocity and create a milestone-based plan]

User: "Execute the sprint"
Claude: [Uses sprint-executor with TDD, running tests at each checkpoint]
```

## Skill Structure

Each skill follows the progressive disclosure pattern:

```
skill-name/
  SKILL.md        # Always loaded (core docs, <300 lines)
  scripts/        # Execute as needed (automation)
  resources/      # Load on demand (detailed references)
```

## Creating Your Own Skills

See the [skill-builder](skills/skill-builder/SKILL.md) for the complete guide to creating, testing, and optimizing skills.

Key principles:
- **Pushy descriptions**: List specific trigger scenarios to combat under-triggering
- **Progressive disclosure**: Keep SKILL.md lean, details in resources/
- **Eval-driven**: Test with the skill-builder's eval framework before shipping

## Contributing

1. Fork this repository
2. Create a new skill in `skills/your-skill-name/`
3. Include a `SKILL.md` with YAML frontmatter (`name` + `description`)
4. Add `scripts/` and `resources/` as needed
5. Run `skill-builder/scripts/validate_skill.sh skills/your-skill-name/`
6. Submit a PR

## License

MIT
