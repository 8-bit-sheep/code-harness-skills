#!/usr/bin/env bash
# Test whether a skill triggers correctly for given prompts
# Uses claude -p in headless mode to check if the skill is invoked
#
# Usage: test_triggers.sh <skill-path> <eval-set.json>
# The eval-set.json should contain an array of objects:
#   [{"query": "user prompt", "should_trigger": true}, ...]

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <skill-path> <eval-set.json>" >&2
    echo "" >&2
    echo "eval-set.json format:" >&2
    echo '  [{"query": "user prompt", "should_trigger": true}, ...]' >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --runs N    Run each query N times (default: 1, use 3 for reliability)" >&2
    echo "  --model ID  Model to test against (default: claude-sonnet-4-5-20250514)" >&2
    exit 1
fi

# Parse options
RUNS=1
MODEL="claude-sonnet-4-5-20250514"
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --runs) RUNS="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

SKILL_PATH="$1"
EVAL_SET="$2"

# Validate inputs
if [[ ! -d "$SKILL_PATH" ]]; then
    echo "Error: Skill path not found: $SKILL_PATH" >&2
    exit 1
fi

if [[ ! -f "$EVAL_SET" ]]; then
    echo "Error: Eval set not found: $EVAL_SET" >&2
    exit 1
fi

# Check dependencies
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found. Install Claude Code first." >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Install with: brew install jq" >&2
    exit 1
fi

# Extract skill name from SKILL.md frontmatter
SKILL_NAME=$(grep '^name:' "$SKILL_PATH/SKILL.md" | sed 's/^name: *//' | head -1)
echo "Testing skill triggers: $SKILL_NAME"
echo "Skill path: $SKILL_PATH"
echo "Eval set: $EVAL_SET"
echo "Runs per query: $RUNS"
echo "Model: $MODEL"
echo "---"
echo ""

# Read eval set
QUERY_COUNT=$(jq 'length' "$EVAL_SET")
SHOULD_TRIGGER_COUNT=$(jq '[.[] | select(.should_trigger == true)] | length' "$EVAL_SET")
SHOULD_NOT_COUNT=$(jq '[.[] | select(.should_trigger == false)] | length' "$EVAL_SET")

echo "Eval set: $QUERY_COUNT queries ($SHOULD_TRIGGER_COUNT should-trigger, $SHOULD_NOT_COUNT should-not-trigger)"
echo ""

# Results tracking
CORRECT=0
INCORRECT=0
RESULTS_JSON="[]"

for i in $(seq 0 $((QUERY_COUNT - 1))); do
    QUERY=$(jq -r ".[$i].query" "$EVAL_SET")
    SHOULD_TRIGGER=$(jq -r ".[$i].should_trigger" "$EVAL_SET")

    echo "[$((i+1))/$QUERY_COUNT] Testing: ${QUERY:0:80}..."
    echo "  Expected: should_trigger=$SHOULD_TRIGGER"

    TRIGGER_COUNT=0
    TOTAL_RUNS=0

    for run in $(seq 1 "$RUNS"); do
        TOTAL_RUNS=$((TOTAL_RUNS + 1))

        # Run claude in headless mode with the skill available
        # Check if the output mentions using/invoking the skill
        START_TIME=$(date +%s%N 2>/dev/null || date +%s)
        OUTPUT=$(claude -p "$QUERY" \
            --output-format json \
            --max-turns 1 \
            --model "$MODEL" \
            2>/dev/null || echo '{"error": true}')
        END_TIME=$(date +%s%N 2>/dev/null || date +%s)

        # Check if the skill was triggered by looking for Skill tool use in the output
        if echo "$OUTPUT" | jq -e '.[] | select(.type == "tool_use" and .tool_name == "Skill")' > /dev/null 2>&1; then
            TRIGGER_COUNT=$((TRIGGER_COUNT + 1))
        elif echo "$OUTPUT" | grep -qi "skill.*$SKILL_NAME" 2>/dev/null; then
            TRIGGER_COUNT=$((TRIGGER_COUNT + 1))
        fi
    done

    # Calculate trigger rate
    TRIGGER_RATE=$(echo "scale=2; $TRIGGER_COUNT / $TOTAL_RUNS" | bc)
    TRIGGERED=$(( TRIGGER_COUNT > TOTAL_RUNS / 2 ))  # Majority vote

    # Check correctness
    if [[ "$SHOULD_TRIGGER" == "true" && $TRIGGERED -eq 1 ]]; then
        echo "  Result: PASS (triggered $TRIGGER_COUNT/$TOTAL_RUNS runs)"
        CORRECT=$((CORRECT + 1))
        STATUS="pass"
    elif [[ "$SHOULD_TRIGGER" == "false" && $TRIGGERED -eq 0 ]]; then
        echo "  Result: PASS (not triggered $((TOTAL_RUNS - TRIGGER_COUNT))/$TOTAL_RUNS runs)"
        CORRECT=$((CORRECT + 1))
        STATUS="pass"
    elif [[ "$SHOULD_TRIGGER" == "true" ]]; then
        echo "  Result: FAIL (should have triggered, only $TRIGGER_COUNT/$TOTAL_RUNS)"
        INCORRECT=$((INCORRECT + 1))
        STATUS="fail"
    else
        echo "  Result: FAIL (should NOT have triggered, triggered $TRIGGER_COUNT/$TOTAL_RUNS)"
        INCORRECT=$((INCORRECT + 1))
        STATUS="fail"
    fi
    echo ""

    # Append to results
    RESULTS_JSON=$(echo "$RESULTS_JSON" | jq \
        --arg query "$QUERY" \
        --argjson should_trigger "$SHOULD_TRIGGER" \
        --argjson trigger_count "$TRIGGER_COUNT" \
        --argjson total_runs "$TOTAL_RUNS" \
        --arg trigger_rate "$TRIGGER_RATE" \
        --arg status "$STATUS" \
        '. + [{"query": $query, "should_trigger": $should_trigger, "trigger_count": $trigger_count, "total_runs": $total_runs, "trigger_rate": $trigger_rate, "status": $status}]')
done

# Summary
TOTAL=$((CORRECT + INCORRECT))
ACCURACY=$(echo "scale=1; $CORRECT * 100 / $TOTAL" | bc)

echo "=== Summary ==="
echo "Accuracy: $CORRECT/$TOTAL ($ACCURACY%)"
echo "  Should-trigger correct: $(echo "$RESULTS_JSON" | jq '[.[] | select(.should_trigger == true and .status == "pass")] | length')/$SHOULD_TRIGGER_COUNT"
echo "  Should-not-trigger correct: $(echo "$RESULTS_JSON" | jq '[.[] | select(.should_trigger == false and .status == "pass")] | length')/$SHOULD_NOT_COUNT"
echo ""

# Save results
RESULTS_DIR=$(dirname "$EVAL_SET")
RESULTS_FILE="$RESULTS_DIR/trigger_results_$(date +%Y%m%d_%H%M%S).json"
jq -n \
    --arg skill_name "$SKILL_NAME" \
    --arg skill_path "$SKILL_PATH" \
    --arg model "$MODEL" \
    --argjson runs "$RUNS" \
    --argjson accuracy "$CORRECT" \
    --argjson total "$TOTAL" \
    --arg accuracy_pct "$ACCURACY" \
    --argjson results "$RESULTS_JSON" \
    '{
        skill_name: $skill_name,
        skill_path: $skill_path,
        model: $model,
        runs_per_query: $runs,
        accuracy: $accuracy,
        total: $total,
        accuracy_pct: $accuracy_pct,
        timestamp: now | todate,
        results: $results
    }' > "$RESULTS_FILE"

echo "Results saved to: $RESULTS_FILE"

if [[ $INCORRECT -gt 0 ]]; then
    echo ""
    echo "Failed queries:"
    echo "$RESULTS_JSON" | jq -r '.[] | select(.status == "fail") | "  - [\(.should_trigger | if . then "should-trigger" else "should-not" end)] \(.query[:80])"'
    exit 1
fi

exit 0
