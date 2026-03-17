# Eval JSON Schemas

Reference for all JSON structures used in skill evaluation.

## evals.json

The eval set definition. Create this before running evals.

```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "A realistic user prompt for testing the skill",
      "expected_output": "Brief description of what good output looks like",
      "files": [],
      "assertions": [
        "Output contains a valid JSON structure",
        "Response includes at least 3 concrete examples",
        "No placeholder text like 'TODO' or 'example' remains"
      ]
    }
  ]
}
```

**Fields:**
- `id` (required): Unique integer identifier
- `prompt` (required): The user prompt to test
- `expected_output` (required): Human-readable description of expected result
- `files` (optional): Array of file paths to provide as context
- `assertions` (optional): Array of verifiable assertion strings (added after initial runs)

## eval_metadata.json

Per-run metadata, saved in each run directory.

```json
{
  "eval_id": 1,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "skill_path": "/path/to/skill",
  "model": "claude-sonnet-4-5-20250514",
  "configuration": "with_skill",
  "assertions": [
    "Output contains valid JSON",
    "Response includes examples"
  ]
}
```

**Fields:**
- `configuration`: One of `"with_skill"`, `"without_skill"`, `"old_skill"`

## timing.json

Timing data captured from each run.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3,
  "configuration": "with_skill"
}
```

**Capture this immediately** when each run completes — the data comes from the process output and isn't persisted elsewhere.

## grading.json

Results from the grader agent evaluating assertions.

```json
{
  "eval_id": 1,
  "configuration": "with_skill",
  "expectations": [
    {
      "text": "Output contains valid JSON",
      "passed": true,
      "evidence": "Found valid JSON in output.txt lines 1-42"
    },
    {
      "text": "Response includes examples",
      "passed": false,
      "evidence": "Output contains generic placeholder text, not concrete examples"
    }
  ],
  "eval_critique": {
    "non_discriminating": ["assertion that always passes"],
    "missing_assertions": ["important thing not tested"],
    "suggestions": ["Consider adding: 'No TODO comments remain'"]
  },
  "overall_notes": "Skill produced correct structure but lacked specificity"
}
```

**Critical**: Use exactly `text`, `passed`, `evidence` — these field names are required.

## comparison.json

Blind A/B comparison results.

```json
{
  "task_prompt": "the original prompt",
  "ratings": {
    "output_a": {"completeness": 4, "correctness": 5, "quality": 3, "efficiency": 4},
    "output_b": {"completeness": 5, "correctness": 5, "quality": 5, "efficiency": 4}
  },
  "winner": "B",
  "reasoning": "B handles edge cases that A misses",
  "key_differences": ["B validates input", "A is more concise"]
}
```

## trigger_eval_set.json

For description optimization. Array of trigger test queries.

```json
[
  {"query": "realistic user prompt that should trigger the skill", "should_trigger": true},
  {"query": "near-miss prompt that shares keywords but needs something different", "should_trigger": false}
]
```

**Guidelines for good eval queries:**
- 10 should-trigger + 10 should-not-trigger (20 total)
- Realistic prompts with context, file paths, details
- Should-trigger: different phrasings, casual/formal, edge cases
- Should-not-trigger: near-misses, not obviously irrelevant
- Bad: `"Format this data"` (too generic)
- Good: `"ok so I have this CSV in ~/Downloads/sales_q4.csv and need to add profit margins..."` (realistic)

## trigger_results.json

Output from `test_triggers.sh`.

```json
{
  "skill_name": "my-skill",
  "skill_path": "/path/to/skill",
  "model": "claude-sonnet-4-5-20250514",
  "runs_per_query": 3,
  "accuracy": 18,
  "total": 20,
  "accuracy_pct": "90.0",
  "timestamp": "2026-03-08T12:00:00Z",
  "results": [
    {
      "query": "user prompt",
      "should_trigger": true,
      "trigger_count": 3,
      "total_runs": 3,
      "trigger_rate": "1.00",
      "status": "pass"
    }
  ]
}
```

## optimization_results.json

Output from `optimize_description.sh`.

```json
{
  "skill_name": "my-skill",
  "original_description": "original description text",
  "best_description": "improved description text",
  "baseline_test_accuracy": "75.0%",
  "best_test_accuracy": "95.0%",
  "iterations": [
    {
      "iteration": 1,
      "description": "iteration 1 description",
      "train_accuracy": "80.0%",
      "test_accuracy": "85.0%"
    }
  ],
  "timestamp": "2026-03-08T12:00:00Z"
}
```

## Directory Structure

```
skill-workspace/
├── evals.json                          # Eval definitions
├── trigger_eval_set.json               # Trigger test queries
└── iteration-1/
    ├── eval-1-descriptive-name/
    │   ├── with_skill/
    │   │   ├── eval_metadata.json
    │   │   ├── transcript.json
    │   │   ├── timing.json
    │   │   ├── grading.json
    │   │   └── outputs/
    │   │       └── response.txt
    │   └── without_skill/
    │       ├── eval_metadata.json
    │       ├── transcript.json
    │       ├── timing.json
    │       ├── grading.json
    │       └── outputs/
    │           └── response.txt
    ├── eval-2-another-name/
    │   └── ...
    ├── benchmark.json                  # Aggregated stats
    └── comparison.json                 # Blind A/B results
```
