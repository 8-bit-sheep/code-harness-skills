# Performance Optimization Principles

Comprehensive guide inspired by Abseil's performance tips.

## Core Philosophy

**Balance simplicity with performance.** Knuth's "premature optimization" quote acknowledges that while 97% of code shouldn't be micro-optimized, the remaining 3% matters significantly. Write naturally performant code during development.

## Principle 1: Profile Before Optimizing

**Never optimize without data.** Use profiling tools to identify actual bottlenecks.

**Key insight:** Optimization efforts should target proven hot paths. Many small 1% improvements can collectively yield 20%+ gains.

## Principle 2: Algorithmic Improvements First

**O(n) beats optimized O(n^2).** Always seek better algorithms before micro-optimizing.

| Bad | Better |
|-----|--------|
| Nested loop search O(n^2) | Hash table lookup O(1) |
| Bubble sort O(n^2) | Quick/merge sort O(n log n) |
| String concatenation in loop | StringBuilder/buffer |
| Repeated linear search | Build index first |

## Principle 3: Batch Operations

**Amortize overhead by processing multiple items together.**

**Apply to:**
- Database operations (batch inserts)
- Network requests (multiplexing)
- File I/O (buffered writes)
- API calls (bulk endpoints)

## Principle 4: Memory Layout Matters

**Cache-friendly data structures reduce memory bandwidth.**

**Latency hierarchy:**
| Operation | Time |
|-----------|------|
| L1 cache hit | 0.5 ns |
| L2 cache hit | 7 ns |
| Main memory | 100 ns |
| SSD read | 150 us |
| Disk seek | 10 ms |

**Guidelines:**
- Colocate frequently-accessed fields
- Use arrays over linked lists when possible
- Prefer flat structures over pointer-heavy trees
- Consider struct-of-arrays vs array-of-structs

## Principle 5: Avoid Unnecessary Allocations

**Each allocation has overhead: allocator cost, initialization, new cache line.**

**Techniques:**
- Object pools for frequently allocated objects
- Pre-allocate collections with known capacity
- Use value types for small structs (avoid pointer indirection)
- String builders instead of concatenation

## Principle 6: Fast Paths for Common Cases

**Optimize the typical path; handle edge cases separately.**

## Principle 7: Precompute Expensive Information

**Calculate once, use many times.** Move costly computations to initialization.

## Principle 8: Defer Expensive Work

**Move costly operations outside hot loops; lazy evaluation.**

## Principle 9: Right-Size Data Structures

**Choose containers appropriate to access patterns.**

| Use Case | Best Choice |
|----------|-------------|
| Small fixed set (<10) | Array/slice |
| Frequent lookups | Hash map |
| Ordered iteration | Sorted array |
| Set membership | Hash set |
| Bit flags | Bitset |

## Principle 10: Help the Compiler

**Structure code to enable optimizations.** Use range loops, prove bounds, avoid unnecessary indirection.

## Principle 11: Estimation via Back-of-Envelope

**Quantify before building.** Quick estimates prevent bad designs.

**Quick reference:**
- CPU cycle: ~0.3 ns
- Function call: ~1-5 ns
- Memory allocation: ~25 ns
- Mutex lock/unlock: ~25 ns
- System call: ~1000 ns
- SSD random read: ~150,000 ns
- Network round-trip (local): ~500,000 ns

## Anti-Patterns to Avoid

1. **String formatting in hot loops** - Use structured logging
2. **Reflection in hot paths** - Generate code instead
3. **Dynamic dispatch everywhere** - Lose type info and optimizations
4. **Unbounded caching** - Memory leaks
5. **Premature abstraction** - Adds indirection cost
6. **Ignoring allocations** - GC pressure adds latency spikes
