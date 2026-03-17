#!/usr/bin/env bash
# Create a new Anthropic Agent Skill with proper structure

set -euo pipefail

# Auto-detect if running from global context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == "$HOME/.claude/skills/"* ]]; then
    DEFAULT_LOCATION="global"
else
    DEFAULT_LOCATION="project"
fi

# Parse arguments
GLOBAL=false
if [[ "${1:-}" == "--global" ]]; then
    GLOBAL=true
    shift
elif [[ "${1:-}" == "--project" ]]; then
    GLOBAL=false
    shift
elif [[ "$DEFAULT_LOCATION" == "global" ]]; then
    # Running from global location, default to global
    GLOBAL=true
fi

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 [--global|--project] <skill-name> <description>" >&2
    echo "Example: $0 my-skill 'Does something useful. Use when user asks for X.'" >&2
    echo "         $0 --global my-skill 'Available across all projects'" >&2
    echo "         $0 --project my-skill 'Only for this project'" >&2
    exit 1
fi

SKILL_NAME="$1"
DESCRIPTION="$2"

# Validate skill name (lowercase, hyphens only)
if ! [[ "$SKILL_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "Error: Skill name must be lowercase with hyphens only (e.g., 'my-skill')" >&2
    exit 1
fi

# Determine skill directory based on location
if [[ $GLOBAL == true ]]; then
    SKILL_DIR="$HOME/.claude/skills/$SKILL_NAME"
    LOCATION_DESC="global (~/.claude/skills/)"
else
    SKILL_DIR=".claude/skills/$SKILL_NAME"
    LOCATION_DESC="project (.claude/skills/)"
fi

# Check if skill already exists
if [[ -d "$SKILL_DIR" ]]; then
    echo "Error: Skill '$SKILL_NAME' already exists at $SKILL_DIR" >&2
    exit 1
fi

echo "Creating new skill: $SKILL_NAME"
echo "Location: $LOCATION_DESC"
echo "Description: $DESCRIPTION"
echo

# Create directory structure
mkdir -p "$SKILL_DIR/scripts"
mkdir -p "$SKILL_DIR/resources"

# Convert skill-name to Title Case Name
SKILL_TITLE=$(echo "$SKILL_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

# Create SKILL.md
cat > "$SKILL_DIR/SKILL.md" << EOF
---
name: $SKILL_TITLE
description: $DESCRIPTION
---

# $SKILL_TITLE

Brief description of what this skill does.

## Quick Start

**Most common usage:**
\`\`\`bash
# Example of typical usage
# User says: "Do something"
# This skill will:
# 1. First step
# 2. Second step
\`\`\`

## When to Use This Skill

Invoke this skill when:
- User asks for [specific action]
- User mentions [keyword or trigger]
- User wants to [accomplish goal]

## Available Scripts

### \`scripts/example_script.sh\`
Description of what this script does.

**Usage:**
\`\`\`bash
# Via skill invocation (preferred)
# Claude will automatically find and execute the script

# Or directly:
scripts/example_script.sh [args]
\`\`\`

## Workflow

### 1. First Step

Description of first step in the workflow.

### 2. Second Step

Description of second step.

### 3. Final Step

Description of final step.

## Resources

### Reference Guide
See [\`resources/reference.md\`](resources/reference.md) for detailed reference.

## Progressive Disclosure

This skill loads information progressively:

1. **Always loaded**: This SKILL.md file (YAML frontmatter + workflow overview)
2. **Execute as needed**: Scripts in \`scripts/\` directory
3. **Load on demand**: \`resources/reference.md\` (detailed reference)

## Notes

- Add any important notes here
- Prerequisites, dependencies, etc.
EOF

# Create example script
cat > "$SKILL_DIR/scripts/example_script.sh" << 'EOF'
#!/usr/bin/env bash
# Example script - replace with actual implementation

set -euo pipefail

echo "Running example script..."
echo "Replace this with actual logic"
exit 0
EOF

chmod +x "$SKILL_DIR/scripts/example_script.sh"

# Create example resource
cat > "$SKILL_DIR/resources/reference.md" << EOF
# $SKILL_TITLE Reference

Detailed reference information for this skill.

## Section 1

Content here.

## Section 2

More content.

## Examples

\`\`\`bash
# Example usage
\`\`\`
EOF

echo "✓ Created skill structure:"
echo "  $SKILL_DIR/"
echo "  ├── SKILL.md"
echo "  ├── scripts/"
echo "  │   └── example_script.sh"
echo "  └── resources/"
echo "      └── reference.md"
echo

# Update permissions in .claude/settings.json for project skills
if [[ $GLOBAL == false ]]; then
    SETTINGS_FILE=".claude/settings.json"
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Check if jq is available
        if command -v jq &> /dev/null; then
            # Add permission for the new skill's scripts
            PERMISSION_ENTRY="Bash(.claude/skills/$SKILL_NAME/scripts/:*)"
            SKILL_ENTRY="Skill($SKILL_NAME)"

            # Check if permission already exists
            if ! jq -e ".permissions.allow | index(\"$PERMISSION_ENTRY\")" "$SETTINGS_FILE" > /dev/null 2>&1; then
                # Add permission using jq
                TEMP_FILE=$(mktemp)
                jq ".permissions.allow += [\"$PERMISSION_ENTRY\", \"$SKILL_ENTRY\"]" "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"
                echo "✓ Updated $SETTINGS_FILE with permissions:"
                echo "    - $PERMISSION_ENTRY"
                echo "    - $SKILL_ENTRY"
            else
                echo "ℹ Permission already exists in $SETTINGS_FILE"
            fi
        else
            echo "⚠ jq not found - please manually add to $SETTINGS_FILE:"
            echo "    \"Bash(.claude/skills/$SKILL_NAME/scripts/:*)\""
            echo "    \"Skill($SKILL_NAME)\""
        fi
    else
        echo "⚠ $SETTINGS_FILE not found - please create it with permissions for this skill"
    fi
    echo
fi

echo "Next steps:"
echo "  1. Edit $SKILL_DIR/SKILL.md to customize the skill"
echo "  2. Implement scripts in $SKILL_DIR/scripts/"
echo "  3. Add resources to $SKILL_DIR/resources/"
echo "  4. Update .claude/skills/README.md to list the new skill"
echo "  5. Test the skill by asking Claude to use it"
