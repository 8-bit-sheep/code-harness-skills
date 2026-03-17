# Optimization Patterns

Language-agnostic optimization patterns with examples.

## Memory Management

### Use Object Pools for Frequently Allocated Objects

Reuse objects instead of allocating new ones every time.

### Pre-allocate Collections

When you know the expected size, allocate upfront to avoid resizing.

### Avoid Escape to Heap

Keep small objects on the stack when possible. Avoid returning pointers to local variables unnecessarily.

## String Handling

### Use String Builders

Avoid O(n^2) string concatenation in loops. Use a builder/buffer that grows once.

### Avoid Unnecessary Conversions

Compare bytes directly instead of converting to strings for comparison.

## Concurrency

### Use Buffered Channels/Queues

Reduce synchronization overhead by batching work.

### Avoid Lock Contention

Shard locks when contention is high. Use read-write locks when reads dominate.

## Data Structure Layout

### Order Fields by Size

Reduce struct padding by placing larger fields first.

### Use Value Types for Small Structs

Avoid pointer indirection for structs that fit in a few words.

## Interface Optimization

### Avoid Dynamic Dispatch in Hot Paths

Use concrete types in performance-critical loops. Reserve interfaces for flexibility at boundaries.

## Profiling Commands

### General Approach

1. **Identify**: Use profiling to find the actual bottleneck
2. **Measure**: Get baseline numbers before changing anything
3. **Optimize**: Make targeted changes to the hot path
4. **Verify**: Measure again to confirm improvement
5. **Document**: Record what was changed and why

### Common Tools

- **CPU profiling** - Identify CPU-bound bottlenecks
- **Memory profiling** - Find allocation hotspots
- **Tracing** - Understand execution flow
- **Escape analysis** - Find unnecessary heap allocations

## Benchmarking Best Practices

1. **Setup outside the loop** - Don't count initialization
2. **Report allocations** - Track allocation counts
3. **Prevent dead code elimination** - Use the result
4. **Run multiple iterations** - Average out noise
5. **Compare consistently** - Same machine, same load
