#!/usr/bin/env bash
# Optimize a skill's description for better triggering accuracy
# Iteratively improves the description using train/test split evaluation
#
# Usage: optimize_description.sh <skill-path> [eval-set.json]
# If no eval set provided, generates one automatically

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <skill-path> [eval-set.json]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --max-iterations N  Max optimization iterations (default: 5)" >&2
    echo "  --model ID          Model for testing (default: claude-sonnet-4-5-20250514)" >&2
    echo "  --runs N            Runs per query for reliability (default: 1)" >&2
    echo "  --output DIR        Output directory (default: <skill-path>-workspace/)" >&2
    exit 1
fi

# Parse options
MAX_ITERATIONS=5
MODEL="claude-sonnet-4-5-20250514"
RUNS=1
OUTPUT_DIR=""

while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --max-iterations) MAX_ITERATIONS="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --runs) RUNS="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

SKILL_PATH="$1"
EVAL_SET="${2:-}"

if [[ ! -d "$SKILL_PATH" ]]; then
    echo "Error: Skill path not found: $SKILL_PATH" >&2
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found" >&2
    exit 1
fi

# Extract current description
SKILL_NAME=$(grep '^name:' "$SKILL_PATH/SKILL.md" | sed 's/^name: *//' | head -1)
CURRENT_DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_PATH/SKILL.md" | grep '^description:' | sed 's/^description: *//')

if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$(dirname "$SKILL_PATH")/$(basename "$SKILL_PATH")-workspace/description-opt"
fi
mkdir -p "$OUTPUT_DIR"

echo "=== Description Optimization ==="
echo "Skill: $SKILL_NAME"
echo "Current description: ${CURRENT_DESC:0:100}..."
echo "Max iterations: $MAX_ITERATIONS"
echo "Model: $MODEL"
echo "Output: $OUTPUT_DIR"
echo "---"
echo ""

# Step 1: Generate or load eval set
if [[ -z "$EVAL_SET" || ! -f "$EVAL_SET" ]]; then
    echo "Step 1: Generating trigger eval set..."
    echo ""

    EVAL_SET="$OUTPUT_DIR/trigger_eval_set.json"

    # Use Claude to generate eval queries
    GENERATE_PROMPT="Generate a JSON array of 20 trigger evaluation queries for a Claude Code skill.

The skill is: \"$SKILL_NAME\"
Current description: \"$CURRENT_DESC\"

Read the skill at: $SKILL_PATH/SKILL.md

Create 10 should-trigger and 10 should-not-trigger queries. Requirements:
- Queries must be realistic user prompts (specific, with context/file paths/details)
- Should-trigger: different phrasings, casual/formal mix, edge cases
- Should-not-trigger: near-misses that share keywords but need something different
- Avoid obviously irrelevant negatives — make them genuinely tricky

Output ONLY valid JSON, no markdown fences:
[{\"query\": \"realistic user prompt\", \"should_trigger\": true}, ...]"

    claude -p "$GENERATE_PROMPT" \
        --output-format text \
        --max-turns 1 \
        --model "$MODEL" \
        2>/dev/null | \
        jq '.' > "$EVAL_SET" 2>/dev/null || {
            echo "Error: Failed to generate eval set. Create one manually." >&2
            echo "Format: [{\"query\": \"prompt\", \"should_trigger\": true}, ...]" >&2
            exit 1
        }

    QUERY_COUNT=$(jq 'length' "$EVAL_SET")
    echo "Generated $QUERY_COUNT eval queries → $EVAL_SET"
    echo "IMPORTANT: Review and edit the eval set before proceeding!"
    echo ""
else
    QUERY_COUNT=$(jq 'length' "$EVAL_SET")
    echo "Step 1: Using existing eval set ($QUERY_COUNT queries)"
    echo ""
fi

# Step 2: Split into train/test (60/40)
echo "Step 2: Splitting eval set (60% train, 40% test)..."

TRAIN_SIZE=$(echo "$QUERY_COUNT * 60 / 100" | bc)
TEST_SIZE=$((QUERY_COUNT - TRAIN_SIZE))

# Shuffle and split (deterministic with seed)
jq --argjson n "$TRAIN_SIZE" '
  [range(length)] as $indices |
  [$indices[] | . as $i | {idx: $i, sort: ($i * 7 + 3) % length}] |
  sort_by(.sort) | [.[].idx] as $shuffled |
  {
    train: [.[$shuffled[:$n][]]],
    test: [.[$shuffled[$n:][]]],
  }
' "$EVAL_SET" > "$OUTPUT_DIR/split.json"

jq '.train' "$OUTPUT_DIR/split.json" > "$OUTPUT_DIR/train_set.json"
jq '.test' "$OUTPUT_DIR/split.json" > "$OUTPUT_DIR/test_set.json"

echo "  Train: $TRAIN_SIZE queries"
echo "  Test: $TEST_SIZE queries"
echo ""

# Step 3: Evaluate current description
echo "Step 3: Evaluating current description..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run trigger test on both sets
"$SCRIPT_DIR/test_triggers.sh" --runs "$RUNS" --model "$MODEL" \
    "$SKILL_PATH" "$OUTPUT_DIR/train_set.json" > "$OUTPUT_DIR/baseline_train.log" 2>&1 || true

"$SCRIPT_DIR/test_triggers.sh" --runs "$RUNS" --model "$MODEL" \
    "$SKILL_PATH" "$OUTPUT_DIR/test_set.json" > "$OUTPUT_DIR/baseline_test.log" 2>&1 || true

BASELINE_TRAIN_ACC=$(grep "Accuracy:" "$OUTPUT_DIR/baseline_train.log" | head -1 | grep -o '[0-9.]*%' || echo "N/A")
BASELINE_TEST_ACC=$(grep "Accuracy:" "$OUTPUT_DIR/baseline_test.log" | head -1 | grep -o '[0-9.]*%' || echo "N/A")

echo "  Baseline - Train: $BASELINE_TRAIN_ACC, Test: $BASELINE_TEST_ACC"
echo ""

# Step 4: Optimization loop
echo "Step 4: Running optimization loop..."
echo ""

BEST_DESC="$CURRENT_DESC"
BEST_TEST_ACC="$BASELINE_TEST_ACC"

# Save iteration history
HISTORY="[]"

for iter in $(seq 1 "$MAX_ITERATIONS"); do
    echo "--- Iteration $iter/$MAX_ITERATIONS ---"

    # Read failures from last run
    TRAIN_FAILURES=$(grep "Failed queries:" -A 100 "$OUTPUT_DIR/baseline_train.log" 2>/dev/null | tail -n +2 || echo "none")

    # Ask Claude to improve the description
    IMPROVE_PROMPT="You are optimizing a skill description for better triggering accuracy.

Skill name: $SKILL_NAME
Current description: \"$BEST_DESC\"

Training set accuracy: $BASELINE_TRAIN_ACC
Failed queries from training set:
$TRAIN_FAILURES

Improve the description to better match the should-trigger queries and avoid the should-not-trigger queries. The description appears in Claude's system prompt and determines whether Claude invokes this skill.

Tips:
- Include specific trigger phrases and contexts
- Be slightly 'pushy' — list scenarios where the skill should activate
- Add 'even if they don't explicitly ask for X' for edge cases
- Keep under 1024 characters

Output ONLY the new description text, no quotes or explanation."

    NEW_DESC=$(claude -p "$IMPROVE_PROMPT" \
        --output-format text \
        --max-turns 1 \
        --model "$MODEL" \
        2>/dev/null || echo "$BEST_DESC")

    # Remove any leading/trailing quotes
    NEW_DESC=$(echo "$NEW_DESC" | sed 's/^"//;s/"$//' | tr -d '\n')

    echo "  New description: ${NEW_DESC:0:100}..."

    # Temporarily update the skill description
    BACKUP="$OUTPUT_DIR/SKILL.md.backup"
    cp "$SKILL_PATH/SKILL.md" "$BACKUP"

    # Replace description in frontmatter
    sed -i.tmp "s|^description:.*|description: $NEW_DESC|" "$SKILL_PATH/SKILL.md"
    rm -f "$SKILL_PATH/SKILL.md.tmp"

    # Test on both sets
    "$SCRIPT_DIR/test_triggers.sh" --runs "$RUNS" --model "$MODEL" \
        "$SKILL_PATH" "$OUTPUT_DIR/train_set.json" > "$OUTPUT_DIR/iter${iter}_train.log" 2>&1 || true

    "$SCRIPT_DIR/test_triggers.sh" --runs "$RUNS" --model "$MODEL" \
        "$SKILL_PATH" "$OUTPUT_DIR/test_set.json" > "$OUTPUT_DIR/iter${iter}_test.log" 2>&1 || true

    ITER_TRAIN_ACC=$(grep "Accuracy:" "$OUTPUT_DIR/iter${iter}_train.log" | head -1 | grep -o '[0-9.]*%' || echo "N/A")
    ITER_TEST_ACC=$(grep "Accuracy:" "$OUTPUT_DIR/iter${iter}_test.log" | head -1 | grep -o '[0-9.]*%' || echo "N/A")

    echo "  Train: $ITER_TRAIN_ACC, Test: $ITER_TEST_ACC (baseline test: $BASELINE_TEST_ACC)"

    # Track history
    HISTORY=$(echo "$HISTORY" | jq \
        --argjson iter "$iter" \
        --arg description "$NEW_DESC" \
        --arg train_acc "$ITER_TRAIN_ACC" \
        --arg test_acc "$ITER_TEST_ACC" \
        '. + [{"iteration": $iter, "description": $description, "train_accuracy": $train_acc, "test_accuracy": $test_acc}]')

    # Update best if test accuracy improved (select by TEST score to avoid overfitting)
    ITER_TEST_NUM=$(echo "$ITER_TEST_ACC" | tr -d '%' || echo "0")
    BEST_TEST_NUM=$(echo "$BEST_TEST_ACC" | tr -d '%' || echo "0")

    if (( $(echo "$ITER_TEST_NUM >= $BEST_TEST_NUM" | bc -l 2>/dev/null || echo "0") )); then
        BEST_DESC="$NEW_DESC"
        BEST_TEST_ACC="$ITER_TEST_ACC"
        echo "  New best! (test: $BEST_TEST_ACC)"
        # Keep the updated SKILL.md
        cp "$SKILL_PATH/SKILL.md" "$OUTPUT_DIR/best_SKILL.md"
    fi

    # Restore original for next iteration comparison
    cp "$BACKUP" "$SKILL_PATH/SKILL.md"

    # Update the reference for next iteration's failure analysis
    cp "$OUTPUT_DIR/iter${iter}_train.log" "$OUTPUT_DIR/baseline_train.log"
    BASELINE_TRAIN_ACC="$ITER_TRAIN_ACC"

    echo ""
done

# Step 5: Report results
echo "=== Optimization Complete ==="
echo ""
echo "Original description:"
echo "  $CURRENT_DESC"
echo ""
echo "Best description (test: $BEST_TEST_ACC):"
echo "  $BEST_DESC"
echo ""

# Save final results
jq -n \
    --arg skill_name "$SKILL_NAME" \
    --arg original_description "$CURRENT_DESC" \
    --arg best_description "$BEST_DESC" \
    --arg best_test_accuracy "$BEST_TEST_ACC" \
    --arg baseline_test_accuracy "$BASELINE_TEST_ACC" \
    --argjson history "$HISTORY" \
    '{
        skill_name: $skill_name,
        original_description: $original_description,
        best_description: $best_description,
        baseline_test_accuracy: $baseline_test_accuracy,
        best_test_accuracy: $best_test_accuracy,
        iterations: $history,
        timestamp: now | todate
    }' > "$OUTPUT_DIR/optimization_results.json"

echo "Results: $OUTPUT_DIR/optimization_results.json"
echo "Best SKILL.md: $OUTPUT_DIR/best_SKILL.md"
echo ""
echo "To apply: cp $OUTPUT_DIR/best_SKILL.md $SKILL_PATH/SKILL.md"
