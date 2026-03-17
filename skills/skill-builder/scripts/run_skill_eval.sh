#!/usr/bin/env bash
# Run skill evaluation: with-skill and baseline (without-skill) comparison
# Spawns parallel runs and captures timing/token data
#
# Usage: run_skill_eval.sh <skill-path> <evals.json> [workspace-dir]

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <skill-path> <evals.json> [workspace-dir]" >&2
    echo "" >&2
    echo "evals.json format:" >&2
    echo '  {"skill_name": "my-skill", "evals": [' >&2
    echo '    {"id": 1, "prompt": "task prompt", "expected_output": "description", "files": []}' >&2
    echo '  ]}' >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --iteration N   Iteration number (default: auto-detect)" >&2
    echo "  --model ID      Model for runs (default: claude-sonnet-4-5-20250514)" >&2
    echo "  --max-turns N   Max turns per run (default: 10)" >&2
    echo "  --skip-baseline Skip baseline (without-skill) runs" >&2
    exit 1
fi

# Parse options
ITERATION=""
MODEL="claude-sonnet-4-5-20250514"
MAX_TURNS=10
SKIP_BASELINE=false

while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --iteration) ITERATION="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --max-turns) MAX_TURNS="$2"; shift 2 ;;
        --skip-baseline) SKIP_BASELINE=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

SKILL_PATH="$1"
EVALS_FILE="$2"
WORKSPACE="${3:-$(dirname "$EVALS_FILE")/workspace}"

# Validate inputs
if [[ ! -d "$SKILL_PATH" ]]; then
    echo "Error: Skill path not found: $SKILL_PATH" >&2
    exit 1
fi

if [[ ! -f "$EVALS_FILE" ]]; then
    echo "Error: Evals file not found: $EVALS_FILE" >&2
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

# Extract skill name
SKILL_NAME=$(jq -r '.skill_name' "$EVALS_FILE")
EVAL_COUNT=$(jq '.evals | length' "$EVALS_FILE")

# Auto-detect iteration number
if [[ -z "$ITERATION" ]]; then
    if [[ -d "$WORKSPACE" ]]; then
        ITERATION=$(ls -d "$WORKSPACE"/iteration-* 2>/dev/null | wc -l | tr -d ' ')
        ITERATION=$((ITERATION + 1))
    else
        ITERATION=1
    fi
fi

ITER_DIR="$WORKSPACE/iteration-$ITERATION"
mkdir -p "$ITER_DIR"

echo "=== Skill Evaluation ==="
echo "Skill: $SKILL_NAME ($SKILL_PATH)"
echo "Evals: $EVAL_COUNT test cases"
echo "Iteration: $ITERATION"
echo "Workspace: $ITER_DIR"
echo "Model: $MODEL"
echo "Max turns: $MAX_TURNS"
echo "---"
echo ""

# Track background PIDs
PIDS=()
RUN_DIRS=()

for i in $(seq 0 $((EVAL_COUNT - 1))); do
    EVAL_ID=$(jq -r ".evals[$i].id" "$EVALS_FILE")
    EVAL_PROMPT=$(jq -r ".evals[$i].prompt" "$EVALS_FILE")
    EVAL_NAME=$(jq -r ".evals[$i].expected_output // \"eval-$EVAL_ID\"" "$EVALS_FILE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 40)

    EVAL_DIR="$ITER_DIR/eval-${EVAL_ID}-${EVAL_NAME}"

    echo "[$((i+1))/$EVAL_COUNT] Spawning runs for eval $EVAL_ID: ${EVAL_PROMPT:0:60}..."

    # --- With-skill run ---
    WITH_DIR="$EVAL_DIR/with_skill"
    mkdir -p "$WITH_DIR/outputs"

    # Save eval metadata
    jq -n \
        --argjson eval_id "$EVAL_ID" \
        --arg eval_name "$EVAL_NAME" \
        --arg prompt "$EVAL_PROMPT" \
        --arg skill_path "$SKILL_PATH" \
        --arg model "$MODEL" \
        --arg configuration "with_skill" \
        '{eval_id: $eval_id, eval_name: $eval_name, prompt: $prompt, skill_path: $skill_path, model: $model, configuration: $configuration, assertions: []}' \
        > "$WITH_DIR/eval_metadata.json"

    # Launch with-skill run in background
    (
        START_MS=$(date +%s%N 2>/dev/null || echo "$(($(date +%s) * 1000000000))")
        RESULT=$(claude -p "$EVAL_PROMPT" \
            --output-format json \
            --max-turns "$MAX_TURNS" \
            --model "$MODEL" \
            2>"$WITH_DIR/stderr.log" || echo '[]')
        END_MS=$(date +%s%N 2>/dev/null || echo "$(($(date +%s) * 1000000000))")

        echo "$RESULT" > "$WITH_DIR/transcript.json"

        # Extract text output
        echo "$RESULT" | jq -r '.[] | select(.type == "text") | .text' > "$WITH_DIR/outputs/response.txt" 2>/dev/null || true

        # Calculate timing
        DURATION_NS=$((END_MS - START_MS))
        DURATION_MS=$((DURATION_NS / 1000000))

        # Extract token count from output if available
        TOTAL_TOKENS=$(echo "$RESULT" | jq '[.[] | select(.type == "usage") | .total_tokens // 0] | add // 0' 2>/dev/null || echo 0)

        jq -n \
            --argjson total_tokens "$TOTAL_TOKENS" \
            --argjson duration_ms "$DURATION_MS" \
            --arg configuration "with_skill" \
            '{total_tokens: $total_tokens, duration_ms: $duration_ms, total_duration_seconds: ($duration_ms / 1000), configuration: $configuration}' \
            > "$WITH_DIR/timing.json"

        echo "  [with_skill] eval-$EVAL_ID complete (${DURATION_MS}ms)"
    ) &
    PIDS+=($!)
    RUN_DIRS+=("$WITH_DIR")

    # --- Baseline run (without skill) ---
    if [[ "$SKIP_BASELINE" != "true" ]]; then
        WITHOUT_DIR="$EVAL_DIR/without_skill"
        mkdir -p "$WITHOUT_DIR/outputs"

        jq -n \
            --argjson eval_id "$EVAL_ID" \
            --arg eval_name "$EVAL_NAME" \
            --arg prompt "$EVAL_PROMPT" \
            --arg model "$MODEL" \
            --arg configuration "without_skill" \
            '{eval_id: $eval_id, eval_name: $eval_name, prompt: $prompt, model: $model, configuration: $configuration, assertions: []}' \
            > "$WITHOUT_DIR/eval_metadata.json"

        # Launch baseline run in background (no skill access)
        (
            START_MS=$(date +%s%N 2>/dev/null || echo "$(($(date +%s) * 1000000000))")
            RESULT=$(claude -p "$EVAL_PROMPT" \
                --output-format json \
                --max-turns "$MAX_TURNS" \
                --model "$MODEL" \
                --allowedTools "" \
                2>"$WITHOUT_DIR/stderr.log" || echo '[]')
            END_MS=$(date +%s%N 2>/dev/null || echo "$(($(date +%s) * 1000000000))")

            echo "$RESULT" > "$WITHOUT_DIR/transcript.json"

            echo "$RESULT" | jq -r '.[] | select(.type == "text") | .text' > "$WITHOUT_DIR/outputs/response.txt" 2>/dev/null || true

            DURATION_NS=$((END_MS - START_MS))
            DURATION_MS=$((DURATION_NS / 1000000))
            TOTAL_TOKENS=$(echo "$RESULT" | jq '[.[] | select(.type == "usage") | .total_tokens // 0] | add // 0' 2>/dev/null || echo 0)

            jq -n \
                --argjson total_tokens "$TOTAL_TOKENS" \
                --argjson duration_ms "$DURATION_MS" \
                --arg configuration "without_skill" \
                '{total_tokens: $total_tokens, duration_ms: $duration_ms, total_duration_seconds: ($duration_ms / 1000), configuration: $configuration}' \
                > "$WITHOUT_DIR/timing.json"

            echo "  [baseline] eval-$EVAL_ID complete (${DURATION_MS}ms)"
        ) &
        PIDS+=($!)
        RUN_DIRS+=("$WITHOUT_DIR")
    fi
done

echo ""
echo "Waiting for ${#PIDS[@]} runs to complete..."
echo ""

# Wait for all background processes
FAILED=0
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== Results ==="
echo "Completed: $((${#PIDS[@]} - FAILED))/${#PIDS[@]} runs"

if [[ $FAILED -gt 0 ]]; then
    echo "  $FAILED run(s) had errors - check stderr.log files"
fi

# Print timing summary
echo ""
echo "Timing summary:"
for dir in "${RUN_DIRS[@]}"; do
    if [[ -f "$dir/timing.json" ]]; then
        CONFIG=$(jq -r '.configuration' "$dir/timing.json")
        DURATION=$(jq -r '.total_duration_seconds' "$dir/timing.json")
        TOKENS=$(jq -r '.total_tokens' "$dir/timing.json")
        EVAL_NAME=$(basename "$(dirname "$dir")")
        echo "  $EVAL_NAME ($CONFIG): ${DURATION}s, ${TOKENS} tokens"
    fi
done

echo ""
echo "Results saved to: $ITER_DIR"
echo ""
echo "Next steps:"
echo "  1. Review outputs in $ITER_DIR/eval-*/with_skill/outputs/"
echo "  2. Grade with: claude -p 'Grade these eval results' (use agents/grader.md)"
echo "  3. Improve skill and rerun with --iteration $((ITERATION + 1))"

exit $FAILED
