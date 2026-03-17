# Self-Improvement Guide for Skills

Complete guide for building and maintaining self-improving skills.

## Philosophy

Skills should be **living, evolving tools** that improve themselves based on real-world usage. When Claude executes a skill and discovers issues or opportunities for improvement, the skill should proactively improve itself.

## When to Self-Improve

Self-improvement should be triggered when:

**Script Issues:**
- Script fails or produces unclear output
- Script doesn't handle edge cases properly
- Error messages are confusing or unhelpful
- Script could be more efficient
- Missing validation or safety checks

**Workflow Issues:**
- Instructions are ambiguous or incomplete
- Steps are unclear or confusing
- Workflow doesn't match actual execution flow
- Missing prerequisite information
- Examples are outdated or insufficient

**Resource Issues:**
- Resources are missing helpful examples
- Information is outdated or incorrect
- Organization could be clearer
- New use cases aren't documented
- Cross-references are broken

**New Discoveries:**
- User reveals a new use case not anticipated
- Integration with other tools becomes apparent
- Better patterns or approaches are discovered
- Common mistakes or pitfalls are identified

## Self-Improvement Workflow

### 1. Identify

During skill execution, actively look for:
- Errors or failures
- Unclear instructions or confusing output
- Missing features or capabilities
- Opportunities for better user experience

**Be observant:**
- Monitor script exit codes
- Note confusing error messages
- Identify missing edge case handling
- Recognize workflow friction

### 2. Inform

Always inform the user about what you discovered:

**Good examples:**
```
"I discovered an issue in rockwool-git-sync - the pull_all.sh
script doesn't handle empty repositories properly. Let me improve it..."

"While running the impact report, I noticed the script could provide
clearer output. I'll enhance it with better formatting..."

"The workflow instructions in step 3 were ambiguous - I'll clarify
them based on this execution..."
```

**What to communicate:**
- What you found (the issue or opportunity)
- Why it matters (impact on users)
- What you'll do (the proposed fix)

### 3. Propose

For **quick fixes** (< 5 min):
- Inform and implement immediately
- Don't wait for explicit approval
- Examples: typo fixes, clearer error messages, minor script improvements

For **major changes** (> 5 min or changing core behavior):
- Describe the change in detail
- Explain the impact and trade-offs
- Wait for user approval before implementing
- Examples: new features, workflow restructuring, breaking changes

### 4. Implement

Make the necessary changes:

**Editing Scripts:**
```bash
# Use Edit tool to modify scripts
# Update error handling, add features, improve output
# Ensure changes don't break existing functionality
```

**Updating Resources:**
```bash
# Add examples, update documentation, fix errors
# Improve organization and clarity
# Keep resources focused and scannable
```

**Refining SKILL.md:**
```bash
# Clarify workflow steps
# Update triggers in description
# Add learnings from execution
# Keep under 300 lines (move details to resources if needed)
```

### 5. Validate

After making changes, always validate:

```bash
# Run the validation script
~/.claude/skills/skill-builder/scripts/validate_skill.sh <skill-name>
# or for project skills:
.claude/skills/skill-builder/scripts/validate_skill.sh <skill-name>
```

**Check:**
- [ ] Validation passes
- [ ] Scripts are still executable
- [ ] SKILL.md is ≤300 lines
- [ ] YAML frontmatter is correct
- [ ] No syntax errors introduced

### 6. Log

Document the improvement for future reference:

**Create/update CHANGELOG.md:**
```markdown
## 2025-11-24 - Self-Improvement: [Brief Description]

**Issue/Opportunity:**
- What was discovered during execution

**Change:**
- What was modified (file:line)
- Specific improvements made

**Trigger:**
- What user action revealed this
- Context of the discovery

**Impact:**
- How this improves the skill
- What now works better

**Validation:**
- [x] Validated with validate_skill.sh
- [x] Tested with original use case
- [x] User informed of improvement
```

**Or add to SKILL.md Notes section:**
```markdown
## Notes

**Recent Improvements:**
- 2025-11-24: Enhanced error handling in sync script for empty repos
- 2025-11-23: Clarified workflow step 3 based on user execution
```

### 7. Continue

After improving the skill:
- Return to the original task
- Don't let improvement distract from the main goal
- Use the improved skill immediately

**Example:**
```
✓ Updated rockwool-git-sync/scripts/pull_all.sh
✓ Added empty repository handling
✓ Skill re-validated successfully

Continuing with your git sync request...

[Proceeds with original task using improved skill]
```

## Self-Improvement Guidelines

### Be Proactive

**Don't wait** for users to notice issues:
- ✓ Identify and fix during execution
- ✓ Suggest improvements based on usage patterns
- ✓ Update documentation as understanding deepens
- ✗ Ignore issues because they're "minor"
- ✗ Wait for user to report problems

### Be Transparent

**Always inform** users of changes:
- ✓ Explain what you found and why it matters
- ✓ Show what you're changing
- ✓ Confirm improvements were successful
- ✗ Silently modify scripts or resources
- ✗ Make changes without explanation

### Stay Focused

**Balance** improvement with task completion:
- ✓ Quick fixes during execution (1-2 min)
- ✓ Note larger improvements for later
- ✓ Prioritize completing user's request
- ✗ Get distracted by optimization rabbit holes
- ✗ Spend 30 minutes improving when user is waiting

### Preserve Intent

**Maintain** the skill's core purpose:
- ✓ Enhance existing capabilities
- ✓ Fix bugs and improve reliability
- ✓ Clarify and improve documentation
- ✗ Change fundamental behavior without discussion
- ✗ Add unrelated features that bloat the skill
- ✗ Remove functionality users depend on

### Keep Valid

**Ensure** changes maintain compliance:
- ✓ Always run validate_skill.sh after changes
- ✓ Keep SKILL.md ≤300 lines
- ✓ Maintain required sections
- ✗ Break YAML frontmatter
- ✗ Make scripts non-executable
- ✗ Create files that violate spec

### Document Changes

**Track** the evolution over time:
- ✓ Log improvements in CHANGELOG.md
- ✓ Note what triggered the improvement
- ✓ Explain the impact of changes
- ✗ Make undocumented changes
- ✗ Forget to share learnings with user

## Common Self-Improvement Patterns

### Pattern 1: Script Error Handling

**Trigger:** Script fails on edge case

**Improvement:**
1. Identify the edge case that caused failure
2. Add validation to detect the condition
3. Provide clear error message or handle gracefully
4. Update script comments to document the case

**Example:**
```bash
# Before
git pull origin main

# After
if [[ ! -d .git ]]; then
    echo "✗ Not a git repository: $PWD" >&2
    exit 1
fi

git pull origin main || {
    echo "✗ Failed to pull from origin/main" >&2
    echo "  Tip: Check network connection and credentials" >&2
    exit 1
}
```

### Pattern 2: Workflow Clarification

**Trigger:** User confused about a workflow step

**Improvement:**
1. Identify the ambiguous instruction
2. Add clarity based on actual execution
3. Include concrete examples
4. Update SKILL.md with clearer guidance

**Example:**
```markdown
# Before
### 3. Run the validation script

# After
### 3. Run the validation script

**From the skill directory:**
\`\`\`bash
# Make sure you're in the skill directory first
cd .claude/skills/my-skill

# Then run the validation script
../../skill-builder/scripts/validate_skill.sh my-skill
\`\`\`
```

### Pattern 3: Missing Examples

**Trigger:** User asks how to do something not documented

**Improvement:**
1. Add example to appropriate resource file
2. Link from SKILL.md if it's a common use case
3. Update "Quick Start" if it's the primary use case

**Example:**
Add to resources/examples.md:
```markdown
## Example: Handling Multiple Repositories

When working with multiple repos, you can run the script in a loop:

\`\`\`bash
for repo in repo1 repo2 repo3; do
    .claude/skills/my-skill/scripts/process.sh "$repo"
done
\`\`\`
```

### Pattern 4: Better Output

**Trigger:** Script output is unclear or hard to read

**Improvement:**
1. Add progress indicators
2. Use symbols (✓, ✗, ⚠) for clarity
3. Include helpful context in messages
4. Provide actionable next steps

**Example:**
```bash
# Before
echo "Processing files"
process_files
echo "Done"

# After
echo "Processing files..."
TOTAL=$(ls *.txt | wc -l)
COUNT=0

for file in *.txt; do
    COUNT=$((COUNT + 1))
    echo "  [$COUNT/$TOTAL] Processing $file..."
    if process_file "$file"; then
        echo "    ✓ Success"
    else
        echo "    ✗ Failed - check logs in /tmp/process.log"
    fi
done

echo "✓ Processed $COUNT files"
```

## Testing Self-Improvements

After making improvements, test thoroughly:

### Test Original Use Case

Ensure the improvement doesn't break existing functionality:
```bash
# Re-run the original command that revealed the issue
# Verify it now works correctly
```

### Test Edge Cases

If you added edge case handling, test those cases:
```bash
# Test the newly-handled edge case
# Test boundary conditions
# Test error cases
```

### Test Other Scripts

If you modified a shared resource or SKILL.md, verify other scripts still work:
```bash
# Run other scripts that might be affected
# Check that all references are still valid
```

### Validate Skill

Always run the validation script:
```bash
~/.claude/skills/skill-builder/scripts/validate_skill.sh <skill-name>
```

## Self-Improvement Examples

### Example 1: Git Sync Script

**Scenario:** User runs git sync on a newly initialized repo with no commits

**Discovery:**
```
✗ fatal: couldn't find remote ref main
Script failed
```

**Self-Improvement:**
```
Claude: I discovered an issue in rockwool-git-sync - pull_all.sh
doesn't handle repositories with no commits. Let me improve it...

[Edits scripts/pull_all.sh]
- Added check for remote refs before pulling
- Added clear message for empty repositories
- Updated to use 'git remote show origin' for validation

[Validates skill]
✓ Skill re-validated successfully

[Updates CHANGELOG.md]
✓ Logged improvement with context

[Re-runs git sync]
✓ Now handles empty repos gracefully

Continuing with your git sync...
```

### Example 2: Impact Report Formatting

**Scenario:** User finds impact report hard to read

**Discovery:**
User says: "This report is hard to scan quickly"

**Self-Improvement:**
```
Claude: You're right - the impact report could be more scannable.
Let me improve the formatting...

[Edits scripts/impact_report.sh]
- Added section headers with visual separators
- Used bullet points for lists
- Added summary at the top
- Colored output for better readability

[Validates skill]
✓ Skill re-validated successfully

[Regenerates report]
✓ Much more scannable now

[Updates SKILL.md with example output]
✓ Added screenshot of improved format to docs
```

### Example 3: Workflow Documentation

**Scenario:** User confused about when to use global vs project skills

**Discovery:**
During execution, user asks: "Should this be global or project?"

**Self-Improvement:**
```
Claude: Good question - the documentation wasn't clear about this.
Let me add guidance...

[Edits SKILL.md]
- Added "Choosing Global vs Project" section
- Included decision tree diagram
- Added examples of each type
- Updated Quick Start with decision flow

[Validates skill]
✓ Skill re-validated successfully

[Adds to resources/skill_template.md]
✓ Added global vs project guidance to template
```

## Measuring Self-Improvement Success

Track the effectiveness of self-improvements:

**Metrics to consider:**
- Frequency of the same issue occurring (should decrease)
- User satisfaction with skill execution (should increase)
- Number of self-improvements per skill (indicates active evolution)
- Time between issue discovery and fix (should be fast)

**Positive indicators:**
- Users don't encounter the same issue twice
- Skill becomes more robust over time
- Documentation becomes clearer through use
- Scripts handle more edge cases automatically

**Review periodically:**
- Look at CHANGELOG.md to see evolution
- Identify patterns in improvements
- Share learnings across skills
- Update skill-builder based on insights
