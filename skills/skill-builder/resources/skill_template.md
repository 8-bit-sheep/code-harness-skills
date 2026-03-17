# Skill Template

Use this as a starting point for creating new skills.

## YAML Frontmatter Template

```yaml
---
name: Skill Name
description: Brief description of what this skill does and when to use it (max 1024 chars). Use when user asks for [specific triggers].
---
```

## SKILL.md Structure Template

```markdown
---
name: Skill Name
description: Brief description with triggers.
---

# Skill Name

Brief description of what this skill does.

## Quick Start

**Most common usage:**
\`\`\`bash
# Example of typical usage pattern
# User says: "Do X"
# This skill will:
# 1. Step 1
# 2. Step 2
\`\`\`

## When to Use This Skill

Invoke this skill when:
- User asks for [action]
- User mentions [keyword]
- User wants to [goal]

## Available Scripts

### \`scripts/script_name.sh [args]\`
Description of what this script does.

**Usage:**
\`\`\`bash
.claude/skills/skill-name/scripts/script_name.sh arg1 arg2
\`\`\`

**Output:**
\`\`\`
Expected output format
\`\`\`

## Workflow

### 1. First Step

Description and instructions.

### 2. Second Step

Description and instructions.

### 3. Final Step

Description and instructions.

## Resources

### Resource Name
See [\`resources/resource.md\`](resources/resource.md) for detailed reference.

## Progressive Disclosure

This skill loads information progressively:

1. **Always loaded**: This SKILL.md file (YAML frontmatter + overview)
2. **Execute as needed**: Scripts in \`scripts/\` directory
3. **Load on demand**: Resources in \`resources/\` directory

## Notes

- Prerequisites
- Dependencies
- Important caveats

## Self-Improvement

**This skill is self-improving.** When Claude discovers issues or opportunities for improvement during execution:

1. **Identify** the issue or improvement opportunity
2. **Inform** the user about the finding
3. **Propose** the improvement
4. **Implement** changes to scripts/resources/SKILL.md
5. **Validate** using validate_skill.sh
6. **Log** the improvement in CHANGELOG.md

See skill-builder documentation for full self-improvement workflow.
```

## Script Template

```bash
#!/usr/bin/env bash
# Brief description of what this script does

set -euo pipefail

# Parse arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <arg1> [arg2]" >&2
    echo "Description of what this script does" >&2
    exit 1
fi

ARG1="$1"
ARG2="${2:-default}"

# Main logic
echo "Running script..."

FAILURES=0

# Step 1
echo "1/3 Doing first check..."
if some_command; then
    echo "  ✓ Check passed"
else
    echo "  ✗ Check failed"
    FAILURES=$((FAILURES + 1))
fi

# Summary
if [[ $FAILURES -eq 0 ]]; then
    echo "✓ All steps completed successfully!"
    exit 0
else
    echo "✗ $FAILURES step(s) failed"
    exit 1
fi
```

## Resource Template

```markdown
# Resource Title

Detailed reference information.

## Section 1

Content here.

## Section 2

More content.

## Examples

\`\`\`bash
# Example usage
\`\`\`
```

## CHANGELOG.md Template (Optional but Recommended)

```markdown
# Changelog - Skill Name

Track improvements and evolution of this skill.

## YYYY-MM-DD - Self-Improvement: [Brief Description]

**Issue/Opportunity:**
- Describe what was discovered during execution
- What problem occurred or what could be improved

**Change:**
- What was modified (script/resource/SKILL.md)
- Specific lines or sections affected

**Trigger:**
- What user action or scenario led to the discovery
- Context that revealed the issue

**Impact:**
- How this improves the skill
- What scenarios now work better

**Validation:**
- [ ] Changes validated with validate_skill.sh
- [ ] Tested with original use case
- [ ] User informed of improvement

---

## YYYY-MM-DD - Initial Creation

- Created skill structure
- Implemented core workflow
- Added initial scripts and resources
```

## Checklist for New Skills

**Initial Setup:**
- [ ] Created directory structure (skill-name/scripts/, skill-name/resources/)
- [ ] Created SKILL.md with YAML frontmatter
- [ ] Added 'name' field to frontmatter
- [ ] Added 'description' field with triggers to frontmatter
- [ ] Added "Quick Start" section
- [ ] Added "When to Use This Skill" section
- [ ] Added "Workflow" section
- [ ] Added "Self-Improvement" section to SKILL.md
- [ ] Created scripts (if needed) and made them executable
- [ ] Created resources (if needed)
- [ ] Created CHANGELOG.md for tracking improvements (optional but recommended)
- [ ] Kept SKILL.md ≤300 lines (moved details to resources)

**Testing & Validation:**
- [ ] Tested scripts in isolation
- [ ] Validated skill with validate_skill.sh
- [ ] Updated .claude/skills/README.md (project skills only)
- [ ] Tested skill by asking Claude to use it

**Self-Improvement Readiness:**
- [ ] Scripts have clear error messages that identify issues
- [ ] SKILL.md includes self-improvement workflow guidance
- [ ] Resources are structured to be easily updatable
- [ ] Skill is ready to evolve based on real usage
- [ ] User understands skill will improve itself over time
