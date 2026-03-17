---
name: Design Doc Creator
description: Create design documents in the correct format and location. Use when user asks to create a design doc, plan a feature, or document a design. Handles both planned/ and implemented/ docs with proper structure.
---

# Design Doc Creator

Create well-structured design documents for features following project conventions.

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `DESIGN_DOCS_DIR` | `design_docs` | Root directory for design documents |
| `CHANGELOG_PATH` | `CHANGELOG.md` | Path to changelog file |
| `VERSION_FILE` | `VERSION` | Path to version file (for auto-detecting current version) |

## Quick Start

**Most common usage:**
```bash
# User says: "Create a design doc for better error messages"
# This skill will:
# 1. Search for related existing design docs
# 2. Create ${DESIGN_DOCS_DIR:-design_docs}/planned/better-error-messages.md
# 3. Fill template with proper structure
```

## When to Use This Skill

Invoke this skill when:
- User asks to "create a design doc" or "write a design doc"
- User says "plan a feature" or "design a feature"
- User mentions "document the design" or "create a spec"
- Before starting implementation of a new feature
- After completing a feature (to move to implemented/)

## Available Scripts

### `scripts/create_planned_doc.sh <doc-name> [version]`
Create a new design document in `${DESIGN_DOCS_DIR}/planned/`.

**Usage:**
```bash
# Create doc in planned/ root (no version)
scripts/create_planned_doc.sh m-dx2-better-errors

# Create doc in next version folder
scripts/create_planned_doc.sh reflection-system v1_2_0
```

**What it does:**
- Detects current version from VERSION file or CHANGELOG
- Creates design doc from template
- Places in correct directory
- Fills in creation date

### `scripts/move_to_implemented.sh <doc-name> <version>`
Move a design document from planned/ to implemented/ after completion.

**Usage:**
```bash
scripts/move_to_implemented.sh m-dx1-developer-experience v1_0_0
```

## Workflow

### Creating a Planned Design Doc

**1. Gather Requirements**

Ask user:
- What feature are you designing?
- What version is this targeted for?
- What priority? (P0/P1/P2)
- Estimated effort?
- Any dependencies on other features?

**CRITICAL: Audit for Systemic Issues FIRST**

**Before writing a design doc for a bug fix, ALWAYS ask: "Is this part of a larger pattern?"**

**The Anti-Pattern (incremental special-casing):**
```
v1: Add feature for case A
v2: Bug! Add special case for B
v3: Bug! Add special case for C
...forever patching
```

**The Pattern to Follow (unified solutions):**
```
v1: Bug report for case B
    BEFORE writing design doc:
    1. Search for similar code paths
    2. Check if A, C, D have same gap
    3. Design ONE fix covering ALL cases
v2: Unified fix - no future bugs in this area
```

**Analysis Checklist (do BEFORE writing design doc):**
- [ ] Is this a one-off or part of a pattern?
- [ ] Search codebase for similar code paths
- [ ] Check if other types/cases have the same gap
- [ ] Look at git history - has this area been patched repeatedly?
- [ ] Design fix to cover ALL cases, not just the reported one

**Warning Signs of Fragmented Design:**
- Multiple maps tracking similar things
- Switch statements with growing case lists
- Functions named `handleX`, `handleY`, `handleZ` instead of unified `handle`
- Bug fixes that add `|| specialCase` conditions

**2. Choose Document Name**

**Naming conventions:**
- Use lowercase with hyphens: `feature-name.md`
- For milestone features: `m-XXX-feature-name.md`
- Be specific and descriptive
- Avoid generic names like `improvements.md`

**3. Run Create Script**

```bash
# If version is known
scripts/create_planned_doc.sh feature-name v1_2_0

# If version not decided yet
scripts/create_planned_doc.sh feature-name
```

**4. Customize the Template**

Fill in all sections: header metadata, problem statement, goals, solution design, examples, success criteria, testing strategy, timeline, risks.

**5. Review and Commit**

```bash
git add ${DESIGN_DOCS_DIR:-design_docs}/planned/feature-name.md
git commit -m "Add design doc for feature-name"
```

### Moving to Implemented

**When to move:**
- Feature is complete and shipped
- Tests are passing
- Documentation is updated

```bash
scripts/move_to_implemented.sh feature-name v1_0_0
```

## Design Doc Structure

See [resources/design_doc_structure.md](resources/design_doc_structure.md) for:
- Complete template breakdown
- Section-by-section guide
- Best practices for each section
- Common mistakes to avoid

## Best Practices

### 1. Be Specific
Use metrics, not vague statements. "Reduce build time from 7.5h to 2.5h (-67%)" not "Make development easier."

### 2. Include Metrics
Quantify current state and target improvements with real numbers.

### 3. Break Into Phases
Use checkboxes, estimated hours, and clear definitions of done.

### 4. Link to Examples
Reference real code, existing implementations, and prior art.

### 5. Realistic Estimates
2x your initial estimate. Include buffer for testing and documentation.

## Document Locations

```
${DESIGN_DOCS_DIR:-design_docs}/
├── planned/              # Future features
│   ├── feature.md        # Unversioned (version TBD)
│   └── v1_2_0/           # Targeted for v1.2.0
│       └── feature.md
└── implemented/          # Completed features
    ├── v1_0_0/           # Shipped in v1.0.0
    │   └── feature.md
    └── v1_1_0/           # Shipped in v1.1.0
        └── feature.md
```

**Version folder naming:**
- Use underscores: `v1_0_0` not `v1.0.0`
- Match CHANGELOG tags exactly
- Create folder when first doc needs it

## Progressive Disclosure

This skill loads information progressively:

1. **Always loaded**: This SKILL.md file (workflow overview)
2. **Execute as needed**: Scripts create/move docs
3. **Load on demand**: `resources/design_doc_structure.md` (detailed guide)

## Notes

- All design docs should follow the template structure
- Update CHANGELOG when features ship (separate from design doc)
- Keep design docs focused - split large features into multiple docs
- Use M-XXX naming for milestone/major features
