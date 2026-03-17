---
name: Perf Reviewer
description: Review code for performance issues and run benchmarks. Use when user asks to analyze performance, run benchmarks, or review code for optimization opportunities.
---

# Performance Reviewer

Review code for performance issues and run benchmarks.

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `BUILD_CMD` | `make build` | Command to build the project |
| `TEST_CMD` | `make test` | Command to run tests |
| `BENCHMARK_CMD` | `make bench` | Command to run benchmarks |

## Quick Start

```bash
# Run benchmarks
scripts/benchmark.sh

# Run specific benchmark
scripts/benchmark.sh fibonacci

# Review code for performance issues
# Just ask: "review this code for performance"
```

## When to Use This Skill

Invoke this skill when:
- User asks to "benchmark" or "compare performance"
- User asks to "review for performance" or "optimize"
- User mentions "slow", "performance", "bottleneck"
- After implementing compute-intensive code
- Before releases to verify no performance regressions

## Available Scripts

### `scripts/benchmark.sh [benchmark_name]`
Run benchmarks comparing different implementations or configurations.

**Available benchmarks:** `fibonacci`, `sum`, `all`

**Output:** Timing comparisons, speedup ratios, and recommendations.

## Workflow

### 1. Performance Review (Code Analysis)

When reviewing code, check against these principles (see [resources/principles.md](resources/principles.md)):

**Critical checks:**
1. **Algorithmic complexity** - Is there an O(n log n) solution for O(n^2) code?
2. **Batch operations** - Can multiple operations be combined?
3. **Memory allocation** - Are allocations inside hot loops?
4. **Data layout** - Are frequently-accessed fields colocated?

**Quick checklist:**
```
[ ] No O(n^2) where O(n log n) exists
[ ] Batch APIs for repeated operations
[ ] Allocations hoisted outside loops
[ ] Hot paths optimized, edge cases separate
[ ] No unnecessary string formatting in loops
```

### 2. Benchmarking

```bash
# Full benchmark suite
scripts/benchmark.sh all

# Single benchmark
scripts/benchmark.sh fibonacci
```

### 3. Profiling

Use your language's profiling tools to identify actual bottlenecks before optimizing.

## Performance Principles Summary

From [resources/principles.md](resources/principles.md):

| Principle | Action |
|-----------|--------|
| Profile First | Measure before optimizing |
| Algorithms > Micro-opts | O(n) beats optimized O(n^2) |
| Batch Operations | Amortize overhead |
| Memory Layout | Cache-friendly structures |
| Fast Path | Optimize common case |
| Defer Work | Lazy evaluation |
| Right-size Data | Appropriate containers |

## Resources

- [resources/principles.md](resources/principles.md) - Full performance principles (Abseil-inspired)
- [resources/optimization_patterns.md](resources/optimization_patterns.md) - Language-specific optimization patterns

## Notes

- Always profile real workloads, not just microbenchmarks
- Focus on algorithmic improvements before micro-optimizations
- Document performance characteristics for future reference
