#!/usr/bin/env bash
# Performance benchmark runner
#
# Usage:
#   ./benchmark.sh [benchmark_name] [iterations]
#
# Available benchmarks: fibonacci, sum, all
# Default: all benchmarks with 5 iterations each
#
# This is a generic benchmark framework. Customize the benchmark
# creation functions for your specific project and languages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="/tmp/perf-benchmark-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BENCHMARK="${1:-all}"
ITERATIONS="${2:-5}"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$WORK_DIR"

echo -e "${BOLD}Performance Benchmark${NC}"
echo "============================================================"
echo ""

# Check prerequisites
check_prereqs() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 not found (needed for timing)${NC}"
        exit 1
    fi
}

# Time a command and return milliseconds
time_cmd() {
    local start end elapsed
    start=$(python3 -c 'import time; print(int(time.time() * 1000))')
    eval "$@" > /dev/null 2>&1
    end=$(python3 -c 'import time; print(int(time.time() * 1000))')
    elapsed=$((end - start))
    echo "$elapsed"
}

# Run benchmark multiple times and get average
run_benchmark() {
    local name="$1"
    local cmd="$2"
    local total=0

    for ((i=1; i<=ITERATIONS; i++)); do
        t=$(time_cmd "$cmd")
        total=$((total + t))
    done

    local avg=$((total / ITERATIONS))
    echo "$avg"
}

# Create benchmark files - customize these for your project
create_fibonacci_benchmarks() {
    # Python version
    cat > "$WORK_DIR/fib.py" << 'PYTHON_EOF'
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

if __name__ == "__main__":
    result = fib(30)
PYTHON_EOF

    echo "fibonacci (n=30)"
}

create_sum_benchmarks() {
    # Python version
    cat > "$WORK_DIR/sum.py" << 'PYTHON_EOF'
def sum_squares(n):
    acc = 0
    for i in range(1, n + 1):
        acc += i * i
    return acc

if __name__ == "__main__":
    result = sum_squares(100000)
PYTHON_EOF

    echo "sum of squares (n=100000)"
}

# Run a single benchmark
run_single_benchmark() {
    local name="$1"
    local py_file="$WORK_DIR/${name}.py"

    echo -e "\n${BOLD}Benchmark: $name${NC}"
    echo "---------------------------------------------"

    # Python baseline
    if [[ -f "$py_file" ]]; then
        echo -ne "  Python:    "
        local python_time
        python_time=$(run_benchmark "$name" "python3 $py_file")
        echo -e "${GREEN}${python_time}ms${NC}"
    fi

    # Add your project's implementations here
    # Example:
    # echo -ne "  MyProject: "
    # local my_time
    # my_time=$(run_benchmark "$name" "my-cmd run $WORK_DIR/${name}.ext")
    # echo -e "${GREEN}${my_time}ms${NC}"

    echo "$name,$python_time" >> "$WORK_DIR/results.csv"
}

# Main
check_prereqs

echo "Configuration:"
echo "  Iterations per test: $ITERATIONS"
echo "  Work directory: $WORK_DIR"
echo ""

echo "benchmark,python_ms" > "$WORK_DIR/results.csv"

case "$BENCHMARK" in
    fibonacci|fib)
        create_fibonacci_benchmarks
        run_single_benchmark "fib"
        ;;
    sum)
        create_sum_benchmarks
        run_single_benchmark "sum"
        ;;
    all)
        create_fibonacci_benchmarks
        create_sum_benchmarks
        run_single_benchmark "fib"
        run_single_benchmark "sum"
        ;;
    *)
        echo -e "${RED}Unknown benchmark: $BENCHMARK${NC}"
        echo "Available: fibonacci, sum, all"
        exit 1
        ;;
esac

echo ""
echo -e "${BOLD}Summary${NC}"
echo "============================================================"
echo ""
echo "Results saved to: $WORK_DIR/results.csv"
echo ""
cat "$WORK_DIR/results.csv" | column -t -s','
echo ""
echo "Customize this script to add benchmarks for your project."
