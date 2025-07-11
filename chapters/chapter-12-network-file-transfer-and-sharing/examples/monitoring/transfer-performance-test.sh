#!/bin/bash
# File Transfer Performance Testing Script
# File: examples/monitoring/transfer-performance-test.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/file-transfer-test-$$"
RESULTS_DIR="/var/log/file-transfer-tests"
LOG_FILE="$RESULTS_DIR/performance-test-$(date +%Y%m%d-%H%M%S).log"

# Test parameters
DEFAULT_TEST_SIZE="100M"
DEFAULT_ITERATIONS=3
DEFAULT_TIMEOUT=300

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"

    case $level in
        "ERROR")
            echo -e "${RED}[ERROR] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[INFO] $message${NC}"
            ;;
        "RESULT")
            echo -e "${CYAN}[RESULT] $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG] $message${NC}"
            ;;
    esac
}

show_usage() {
    cat << EOF
File Transfer Performance Testing Script

Usage: $0 [OPTIONS] <test-type> [target]

Test Types:
    samba <//server/share>      Test Samba/CIFS performance
    nfs <server:/export>        Test NFS performance
    sshfs <user@host:/path>     Test SSHFS performance
    rsync <user@host:/path>     Test rsync performance
    scp <user@host:/path>       Test SCP performance
    local <path>                Test local filesystem performance
    all <config-file>           Run all configured tests
    compare                     Compare multiple protocols to same server

Options:
    --size <size>               Test file size (default: $DEFAULT_TEST_SIZE)
                               Examples: 10M, 100M, 1G
    --iterations <n>            Number of test iterations (default: $DEFAULT_ITERATIONS)
    --timeout <seconds>         Timeout for each test (default: $DEFAULT_TIMEOUT)
    --output-format <format>    Output format: text|csv|json (default: text)
    --results-dir <path>        Results directory (default: $RESULTS_DIR)
    --cleanup                   Clean up test files after completion
    --verbose                   Enable verbose output
    --parallel                  Run multiple tests in parallel
    --profile <name>            Save results to named profile

Test Categories:
    Sequential Read/Write       Large file transfers
    Random I/O                  Small file operations
    Metadata Operations         File creation/deletion
    Mixed Workload             Realistic usage patterns
    Bandwidth Saturation       Maximum throughput test
    Latency Test               Small operation response time

Examples:
    # Test NFS performance with 1GB files
    $0 --size 1G nfs server:/srv/nfs/test

    # Compare protocols to same server
    $0 compare server.example.com

    # Test Samba with custom options
    $0 --iterations 5 --verbose samba //server/share

    # Run comprehensive test suite
    $0 --output-format json all test-config.conf

    # Test local filesystem baseline
    $0 --size 500M local /tmp

Configuration File Format (for 'all' tests):
    [samba]
    target = //server/share
    mount_options = username=user,password=pass

    [nfs]
    target = server:/srv/nfs/export
    mount_options = vers=4,rsize=32768

    [sshfs]
    target = user@server:/remote/path
    ssh_key = /home/user/.ssh/id_rsa
EOF
}

# Cleanup function
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        log "INFO" "Cleaned up test directory: $TEST_DIR"
    fi

    # Unmount any test mounts
    for mount_point in /tmp/perf-test-*; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            umount "$mount_point" 2>/dev/null || fusermount -u "$mount_point" 2>/dev/null || true
            rmdir "$mount_point" 2>/dev/null || true
        fi
    done
}

trap cleanup EXIT

# Initialize test environment
init_test_env() {
    mkdir -p "$TEST_DIR"
    mkdir -p "$RESULTS_DIR"

    # Check required tools
    local required_tools=("dd" "time" "bc" "awk")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null; then
            log "ERROR" "Required tool not found: $tool"
            exit 1
        fi
    done

    log "INFO" "Initialized test environment: $TEST_DIR"
}

# Convert size to bytes
size_to_bytes() {
    local size=$1
    local bytes

    case ${size: -1} in
        M|m) bytes=$(echo "${size%?} * 1024 * 1024" | bc) ;;
        G|g) bytes=$(echo "${size%?} * 1024 * 1024 * 1024" | bc) ;;
        K|k) bytes=$(echo "${size%?} * 1024" | bc) ;;
        *) bytes=$size ;;
    esac

    echo "$bytes"
}

# Generate test file
generate_test_file() {
    local size=$1
    local filename=$2
    local pattern=${3:-"zero"}

    log "DEBUG" "Generating test file: $filename ($size)"

    case $pattern in
        "zero")
            dd if=/dev/zero of="$filename" bs=1M count=$(($(size_to_bytes "$size") / 1024 / 1024)) 2>/dev/null
            ;;
        "random")
            dd if=/dev/urandom of="$filename" bs=1M count=$(($(size_to_bytes "$size") / 1024 / 1024)) 2>/dev/null
            ;;
        "pattern")
            # Create repeating pattern for better compression testing
            echo "PERFORMANCE TEST DATA BLOCK 1234567890" > "$filename.pattern"
            while [[ $(stat -c%s "$filename.pattern") -lt $(size_to_bytes "$size") ]]; do
                cat "$filename.pattern" "$filename.pattern" > "$filename.tmp"
                mv "$filename.tmp" "$filename.pattern"
            done
            head -c "$(size_to_bytes "$size")" "$filename.pattern" > "$filename"
            rm -f "$filename.pattern"
            ;;
    esac

    log "DEBUG" "Generated test file: $(stat -c%s "$filename") bytes"
}

# Measure execution time and throughput
measure_performance() {
    local description=$1
    shift
    local command="$*"

    log "DEBUG" "Measuring: $description"
    log "DEBUG" "Command: $command"

    # Clear filesystem caches
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    local start_time=$(date +%s.%N)

    # Execute command with timeout
    if timeout "$TIMEOUT" bash -c "$command"; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)

        echo "$duration"
        return 0
    else
        log "ERROR" "Command timed out or failed: $description"
        echo "-1"
        return 1
    fi
}

# Calculate statistics
calculate_stats() {
    local values=("$@")
    local count=${#values[@]}

    if [[ $count -eq 0 ]]; then
        echo "0 0 0 0"
        return
    fi

    # Calculate mean
    local sum=0
    for value in "${values[@]}"; do
        sum=$(echo "$sum + $value" | bc -l)
    done
    local mean=$(echo "scale=3; $sum / $count" | bc -l)

    # Calculate min and max
    local min=${values[0]}
    local max=${values[0]}
    for value in "${values[@]}"; do
        if (( $(echo "$value < $min" | bc -l) )); then
            min=$value
        fi
        if (( $(echo "$value > $max" | bc -l) )); then
            max=$value
        fi
    done

    # Calculate standard deviation
    local variance_sum=0
    for value in "${values[@]}"; do
        local diff=$(echo "$value - $mean" | bc -l)
        local squared_diff=$(echo "$diff * $diff" | bc -l)
        variance_sum=$(echo "$variance_sum + $squared_diff" | bc -l)
    done
    local variance=$(echo "scale=6; $variance_sum / $count" | bc -l)
    local stddev=$(echo "scale=3; sqrt($variance)" | bc -l)

    echo "$mean $min $max $stddev"
}

# Test sequential write performance
test_sequential_write() {
    local target_dir=$1
    local test_name="Sequential Write"

    log "INFO" "Testing: $test_name"

    local write_times=()
    local write_speeds=()

    for ((i=1; i<=$ITERATIONS; i++)); do
        log "DEBUG" "Write iteration $i/$ITERATIONS"

        local test_file="$target_dir/write_test_$i"
        local bytes=$(size_to_bytes "$TEST_SIZE")

        # Measure write time
        local write_time=$(measure_performance "Sequential write $i" \
            "dd if=/dev/zero of='$test_file' bs=1M count=$((bytes / 1024 / 1024)) oflag=sync")

        if [[ "$write_time" != "-1" ]]; then
            write_times+=("$write_time")
            local speed=$(echo "scale=2; $bytes / $write_time / 1024 / 1024" | bc -l)
            write_speeds+=("$speed")
            log "DEBUG" "Write $i: ${write_time}s, ${speed} MB/s"
        fi
    done

    # Calculate statistics
    local stats=($(calculate_stats "${write_speeds[@]}"))

    log "RESULT" "$test_name Results:"
    log "RESULT" "  Average Speed: ${stats[0]} MB/s"
    log "RESULT" "  Min Speed: ${stats[1]} MB/s"
    log "RESULT" "  Max Speed: ${stats[2]} MB/s"
    log "RESULT" "  Std Dev: ${stats[3]} MB/s"

    # Store results for later use
    WRITE_STATS=("${stats[@]}")
}

# Test sequential read performance
test_sequential_read() {
    local target_dir=$1
    local test_name="Sequential Read"

    log "INFO" "Testing: $test_name"

    # Use files from write test or create new ones
    local test_files=()
    for ((i=1; i<=$ITERATIONS; i++)); do
        local test_file="$target_dir/read_test_$i"
        if [[ ! -f "$test_file" ]]; then
            generate_test_file "$TEST_SIZE" "$test_file"
        fi
        test_files+=("$test_file")
    done

    local read_times=()
    local read_speeds=()

    for ((i=0; i<$ITERATIONS; i++)); do
        log "DEBUG" "Read iteration $((i+1))/$ITERATIONS"

        local test_file="${test_files[$i]}"
        local bytes=$(stat -c%s "$test_file")

        # Measure read time
        local read_time=$(measure_performance "Sequential read $((i+1))" \
            "dd if='$test_file' of=/dev/null bs=1M")

        if [[ "$read_time" != "-1" ]]; then
            read_times+=("$read_time")
            local speed=$(echo "scale=2; $bytes / $read_time / 1024 / 1024" | bc -l)
            read_speeds+=("$speed")
            log "DEBUG" "Read $((i+1)): ${read_time}s, ${speed} MB/s"
        fi
    done

    # Calculate statistics
    local stats=($(calculate_stats "${read_speeds[@]}"))

    log "RESULT" "$test_name Results:"
    log "RESULT" "  Average Speed: ${stats[0]} MB/s"
    log "RESULT" "  Min Speed: ${stats[1]} MB/s"
    log "RESULT" "  Max Speed: ${stats[2]} MB/s"
    log "RESULT" "  Std Dev: ${stats[3]} MB/s"

    # Store results for later use
    READ_STATS=("${stats[@]}")
}

# Test random I/O performance (many small files)
test_random_io() {
    local target_dir=$1
    local test_name="Random I/O (Small Files)"
    local file_count=1000
    local file_size="1K"

    log "INFO" "Testing: $test_name ($file_count files of $file_size each)"

    local create_times=()
    local read_times=()
    local delete_times=()

    for ((i=1; i<=$ITERATIONS; i++)); do
        log "DEBUG" "Random I/O iteration $i/$ITERATIONS"

        local test_subdir="$target_dir/random_io_$i"
        mkdir -p "$test_subdir"

        # Test file creation
        local create_time=$(measure_performance "Create $file_count small files" \
            "for j in {1..$file_count}; do echo 'test data' > '$test_subdir/file_\$j.txt'; done")

        if [[ "$create_time" != "-1" ]]; then
            create_times+=("$create_time")
            local create_iops=$(echo "scale=2; $file_count / $create_time" | bc -l)
            log "DEBUG" "Create $i: ${create_time}s, ${create_iops} IOPS"
        fi

        # Test file reading
        local read_time=$(measure_performance "Read $file_count small files" \
            "for j in {1..$file_count}; do cat '$test_subdir/file_\$j.txt' > /dev/null; done")

        if [[ "$read_time" != "-1" ]]; then
            read_times+=("$read_time")
            local read_iops=$(echo "scale=2; $file_count / $read_time" | bc -l)
            log "DEBUG" "Read $i: ${read_time}s, ${read_iops} IOPS"
        fi

        # Test file deletion
        local delete_time=$(measure_performance "Delete $file_count small files" \
            "rm -f '$test_subdir'/file_*.txt")

        if [[ "$delete_time" != "-1" ]]; then
            delete_times+=("$delete_time")
            local delete_iops=$(echo "scale=2; $file_count / $delete_time" | bc -l)
            log "DEBUG" "Delete $i: ${delete_time}s, ${delete_iops} IOPS"
        fi

        rmdir "$test_subdir" 2>/dev/null || true
    done

    # Calculate statistics for each operation
    local create_iops=()
    local read_iops=()
    local delete_iops=()

    for time in "${create_times[@]}"; do
        create_iops+=($(echo "scale=2; $file_count / $time" | bc -l))
    done

    for time in "${read_times[@]}"; do
        read_iops+=($(echo "scale=2; $file_count / $time" | bc -l))
    done

    for time in "${delete_times[@]}"; do
        delete_iops+=($(echo "scale=2; $file_count / $time" | bc -l))
    done

    local create_stats=($(calculate_stats "${create_iops[@]}"))
    local read_stats=($(calculate_stats "${read_iops[@]}"))
    local delete_stats=($(calculate_stats "${delete_iops[@]}"))

    log "RESULT" "$test_name Results:"
    log "RESULT" "  Create IOPS: ${create_stats[0]} (min: ${create_stats[1]}, max: ${create_stats[2]})"
    log "RESULT" "  Read IOPS: ${read_stats[0]} (min: ${read_stats[1]}, max: ${read_stats[2]})"
    log "RESULT" "  Delete IOPS: ${delete_stats[0]} (min: ${delete_stats[1]}, max: ${delete_stats[2]})"

    # Store results
    CREATE_STATS=("${create_stats[@]}")
    SMALL_READ_STATS=("${read_stats[@]}")
    DELETE_STATS=("${delete_stats[@]}")
}

# Test metadata operations
test_metadata_operations() {
    local target_dir=$1
    local test_name="Metadata Operations"
    local operation_count=1000

    log "INFO" "Testing: $test_name ($operation_count operations)"

    local mkdir_times=()
    local stat_times=()
    local rmdir_times=()

    for ((i=1; i<=$ITERATIONS; i++)); do
        log "DEBUG" "Metadata iteration $i/$ITERATIONS"

        local base_dir="$target_dir/metadata_$i"
        mkdir -p "$base_dir"

        # Test directory creation
        local mkdir_time=$(measure_performance "Create $operation_count directories" \
            "for j in {1..$operation_count}; do mkdir '$base_dir/dir_\$j'; done")

        if [[ "$mkdir_time" != "-1" ]]; then
            mkdir_times+=("$mkdir_time")
            local mkdir_ops=$(echo "scale=2; $operation_count / $mkdir_time" | bc -l)
            log "DEBUG" "Mkdir $i: ${mkdir_time}s, ${mkdir_ops} ops/s"
        fi

        # Test stat operations
        local stat_time=$(measure_performance "Stat $operation_count directories" \
            "for j in {1..$operation_count}; do stat '$base_dir/dir_\$j' >/dev/null; done")

        if [[ "$stat_time" != "-1" ]]; then
            stat_times+=("$stat_time")
            local stat_ops=$(echo "scale=2; $operation_count / $stat_time" | bc -l)
            log "DEBUG" "Stat $i: ${stat_time}s, ${stat_ops} ops/s"
        fi

        # Test directory removal
        local rmdir_time=$(measure_performance "Remove $operation_count directories" \
            "for j in {1..$operation_count}; do rmdir '$base_dir/dir_\$j'; done")

        if [[ "$rmdir_time" != "-1" ]]; then
            rmdir_times+=("$rmdir_time")
            local rmdir_ops=$(echo "scale=2; $operation_count / $rmdir_time" | bc -l)
            log "DEBUG" "Rmdir $i: ${rmdir_time}s, ${rmdir_ops} ops/s"
        fi

        rmdir "$base_dir" 2>/dev/null || true
    done

    # Calculate statistics
    local mkdir_ops=()
    local stat_ops=()
    local rmdir_ops=()

    for time in "${mkdir_times[@]}"; do
        mkdir_ops+=($(echo "scale=2; $operation_count / $time" | bc -l))
    done

    for time in "${stat_times[@]}"; do
        stat_ops+=($(echo "scale=2; $operation_count / $time" | bc -l))
    done

    for time in "${rmdir_times[@]}"; do
        rmdir_ops+=($(echo "scale=2; $operation_count / $time" | bc -l))
    done

    local mkdir_stats=($(calculate_stats "${mkdir_ops[@]}"))
    local stat_stats=($(calculate_stats "${stat_ops[@]}"))
    local rmdir_stats=($(calculate_stats "${rmdir_ops[@]}"))

    log "RESULT" "$test_name Results:"
    log "RESULT" "  Mkdir ops/s: ${mkdir_stats[0]} (min: ${mkdir_stats[1]}, max: ${mkdir_stats[2]})"
    log "RESULT" "  Stat ops/s: ${stat_stats[0]} (min: ${stat_stats[1]}, max: ${stat_stats[2]})"
    log "RESULT" "  Rmdir ops/s: ${rmdir_stats[0]} (min: ${rmdir_stats[1]}, max: ${rmdir_stats[2]})"

    # Store results
    MKDIR_STATS=("${mkdir_stats[@]}")
    STAT_STATS=("${stat_stats[@]}")
    RMDIR_STATS=("${rmdir_stats[@]}")
}

# Test latency (small operations)
test_latency() {
    local target_dir=$1
    local test_name="Latency Test"
    local test_count=100

    log "INFO" "Testing: $test_name ($test_count small operations)"

    local latencies=()

    for ((i=1; i<=test_count; i++)); do
        local test_file="$target_dir/latency_test_$i"

        # Measure time for single small file operation
        local latency=$(measure_performance "Single file operation $i" \
            "echo 'test' > '$test_file' && cat '$test_file' >/dev/null && rm '$test_file'")

        if [[ "$latency" != "-1" ]]; then
            # Convert to milliseconds
            local latency_ms=$(echo "scale=3; $latency * 1000" | bc -l)
            latencies+=("$latency_ms")
        fi
    done

    # Calculate statistics
    local stats=($(calculate_stats "${latencies[@]}"))

    log "RESULT" "$test_name Results:"
    log "RESULT" "  Average Latency: ${stats[0]} ms"
    log "RESULT" "  Min Latency: ${stats[1]} ms"
    log "RESULT" "  Max Latency: ${stats[2]} ms"
    log "RESULT" "  Std Dev: ${stats[3]} ms"

    # Store results
    LATENCY_STATS=("${stats[@]}")
}

# Test protocol-specific functionality
test_samba_performance() {
    local target=$1
    local mount_point="/tmp/perf-test-samba-$$"

    log "INFO" "Testing Samba performance: $target"

    mkdir -p "$mount_point"

    # Mount Samba share
    if ! mount -t cifs "$target" "$mount_point" -o guest 2>/dev/null; then
        log "ERROR" "Failed to mount Samba share: $target"
        rmdir "$mount_point"
        return 1
    fi

    # Run tests
    run_filesystem_tests "$mount_point"

    # Unmount
    umount "$mount_point"
    rmdir "$mount_point"
}

test_nfs_performance() {
    local target=$1
    local mount_point="/tmp/perf-test-nfs-$$"

    log "INFO" "Testing NFS performance: $target"

    mkdir -p "$mount_point"

    # Mount NFS share
    if ! mount -t nfs "$target" "$mount_point" 2>/dev/null; then
        log "ERROR" "Failed to mount NFS share: $target"
        rmdir "$mount_point"
        return 1
    fi

    # Run tests
    run_filesystem_tests "$mount_point"

    # Unmount
    umount "$mount_point"
    rmdir "$mount_point"
}

test_sshfs_performance() {
    local target=$1
    local mount_point="/tmp/perf-test-sshfs-$$"

    log "INFO" "Testing SSHFS performance: $target"

    mkdir -p "$mount_point"

    # Mount SSHFS
    if ! sshfs "$target" "$mount_point" -o cache=yes,compression=yes 2>/dev/null; then
        log "ERROR" "Failed to mount SSHFS: $target"
        rmdir "$mount_point"
        return 1
    fi

    # Run tests
    run_filesystem_tests "$mount_point"

    # Unmount
    fusermount -u "$mount_point"
    rmdir "$mount_point"
}

test_rsync_performance() {
    local target=$1

    log "INFO" "Testing rsync performance: $target"

    # Create test data
    local test_data="$TEST_DIR/rsync_test_data"
    mkdir -p "$test_data"
    generate_test_file "$TEST_SIZE" "$test_data/large_file"

    # Create many small files
    for i in {1..100}; do
        echo "test data $i" > "$test_data/small_$i.txt"
    done

    local rsync_times=()

    for ((i=1; i<=$ITERATIONS; i++)); do
        log "DEBUG" "Rsync iteration $i/$ITERATIONS"

        # Test rsync transfer
        local rsync_time=$(measure_performance "Rsync transfer $i" \
            "rsync -av '$test_data/' '$target/rsync_test_$i/'")

        if [[ "$rsync_time" != "-1" ]]; then
            rsync_times+=("$rsync_time")
            local total_size=$(du -sb "$test_data" | awk '{print $1}')
            local speed=$(echo "scale=2; $total_size / $rsync_time / 1024 / 1024" | bc -l)
            log "DEBUG" "Rsync $i: ${rsync_time}s, ${speed} MB/s"
        fi
    done

    # Calculate statistics
    local total_size=$(du -sb "$test_data" | awk '{print $1}')
    local speeds=()

    for time in "${rsync_times[@]}"; do
        speeds+=($(echo "scale=2; $total_size / $time / 1024 / 1024" | bc -l))
    done

    local stats=($(calculate_stats "${speeds[@]}"))

    log "RESULT" "Rsync Performance Results:"
    log "RESULT" "  Average Speed: ${stats[0]} MB/s"
    log "RESULT" "  Min Speed: ${stats[1]} MB/s"
    log "RESULT" "  Max Speed: ${stats[2]} MB/s"
    log "RESULT" "  Std Dev: ${stats[3]} MB/s"
}

test_scp_performance() {
    local target=$1

    log "INFO" "Testing SCP performance: $target"

    # Create test file
    local test_file="$TEST_DIR/scp_test_file"
    generate_test_file "$TEST_SIZE" "$test_file"

    local scp_times=()

    for ((i=1; i<=$ITERATIONS; i++)); do
        log "DEBUG" "SCP iteration $i/$ITERATIONS"

        # Test SCP transfer
        local scp_time=$(measure_performance "SCP transfer $i" \
            "scp '$test_file' '$target/scp_test_$i'")

        if [[ "$scp_time" != "-1" ]]; then
            scp_times+=("$scp_time")
            local file_size=$(stat -c%s "$test_file")
            local speed=$(echo "scale=2; $file_size / $scp_time / 1024 / 1024" | bc -l)
            log "DEBUG" "SCP $i: ${scp_time}s, ${speed} MB/s"
        fi
    done

    # Calculate statistics
    local file_size=$(stat -c%s "$test_file")
    local speeds=()

    for time in "${scp_times[@]}"; do
        speeds+=($(echo "scale=2; $file_size / $time / 1024 / 1024" | bc -l))
    done

    local stats=($(calculate_stats "${speeds[@]}"))

    log "RESULT" "SCP Performance Results:"
    log "RESULT" "  Average Speed: ${stats[0]} MB/s"
    log "RESULT" "  Min Speed: ${stats[1]} MB/s"
    log "RESULT" "  Max Speed: ${stats[2]} MB/s"
    log "RESULT" "  Std Dev: ${stats[3]} MB/s"
}

test_local_performance() {
    local target_dir=$1

    log "INFO" "Testing local filesystem performance: $target_dir"

    # Ensure directory exists
    mkdir -p "$target_dir"

    # Run standard filesystem tests
    run_filesystem_tests "$target_dir"
}

# Run all filesystem tests
run_filesystem_tests() {
    local target_dir=$1

    log "INFO" "Running comprehensive filesystem tests on: $target_dir"

    # Create test subdirectory
    local test_subdir="$target_dir/perf_test_$$"
    mkdir -p "$test_subdir"

    # Run all test types
    test_sequential_write "$test_subdir"
    test_sequential_read "$test_subdir"
    test_random_io "$test_subdir"
    test_metadata_operations "$test_subdir"
    test_latency "$test_subdir"

    # Generate summary
    generate_test_summary

    # Cleanup
    rm -rf "$test_subdir" 2>/dev/null || true
}

# Generate test summary
generate_test_summary() {
    log "RESULT" "============================================"
    log "RESULT" "PERFORMANCE TEST SUMMARY"
    log "RESULT" "============================================"
    log "RESULT" "Test Parameters:"
    log "RESULT" "  File Size: $TEST_SIZE"
    log "RESULT" "  Iterations: $ITERATIONS"
    log "RESULT" "  Timeout: $TIMEOUT seconds"
    log "RESULT" ""

    if [[ -n "${WRITE_STATS:-}" ]]; then
        log "RESULT" "Sequential Write: ${WRITE_STATS[0]} MB/s (avg)"
    fi

    if [[ -n "${READ_STATS:-}" ]]; then
        log "RESULT" "Sequential Read:  ${READ_STATS[0]} MB/s (avg)"
    fi

    if [[ -n "${CREATE_STATS:-}" ]]; then
        log "RESULT" "Small File Create: ${CREATE_STATS[0]} IOPS (avg)"
    fi

    if [[ -n "${SMALL_READ_STATS:-}" ]]; then
        log "RESULT" "Small File Read:   ${SMALL_READ_STATS[0]} IOPS (avg)"
    fi

    if [[ -n "${LATENCY_STATS:-}" ]]; then
        log "RESULT" "Average Latency:   ${LATENCY_STATS[0]} ms"
    fi

    log "RESULT" "============================================"
}

# Output results in different formats
output_results() {
    local format=$1
    local profile_name=${2:-"default"}

    case $format in
        "csv")
            output_csv_results "$profile_name"
            ;;
        "json")
            output_json_results "$profile_name"
            ;;
        *)
            # Text format already output during tests
            ;;
    esac
}

output_csv_results() {
    local profile_name=$1
    local csv_file="$RESULTS_DIR/results-$profile_name-$(date +%Y%m%d-%H%M%S).csv"

    cat > "$csv_file" << EOF
Profile,Test,Metric,Average,Min,Max,StdDev
$profile_name,Sequential Write,MB/s,${WRITE_STATS[0]:-0},${WRITE_STATS[1]:-0},${WRITE_STATS[2]:-0},${WRITE_STATS[3]:-0}
$profile_name,Sequential Read,MB/s,${READ_STATS[0]:-0},${READ_STATS[1]:-0},${READ_STATS[2]:-0},${READ_STATS[3]:-0}
$profile_name,Small File Create,IOPS,${CREATE_STATS[0]:-0},${CREATE_STATS[1]:-0},${CREATE_STATS[2]:-0},${CREATE_STATS[3]:-0}
$profile_name,Small File Read,IOPS,${SMALL_READ_STATS[0]:-0},${SMALL_READ_STATS[1]:-0},${SMALL_READ_STATS[2]:-0},${SMALL_READ_STATS[3]:-0}
$profile_name,Latency,ms,${LATENCY_STATS[0]:-0},${LATENCY_STATS[1]:-0},${LATENCY_STATS[2]:-0},${LATENCY_STATS[3]:-0}
EOF

    log "INFO" "CSV results saved to: $csv_file"
}

output_json_results() {
    local profile_name=$1
    local json_file="$RESULTS_DIR/results-$profile_name-$(date +%Y%m%d-%H%M%S).json"

    cat > "$json_file" << EOF
{
  "profile": "$profile_name",
  "timestamp": "$(date -Iseconds)",
  "test_parameters": {
    "file_size": "$TEST_SIZE",
    "iterations": $ITERATIONS,
    "timeout": $TIMEOUT
  },
  "results": {
    "sequential_write": {
      "average": ${WRITE_STATS[0]:-0},
      "min": ${WRITE_STATS[1]:-0},
      "max": ${WRITE_STATS[2]:-0},
      "stddev": ${WRITE_STATS[3]:-0},
      "unit": "MB/s"
    },
    "sequential_read": {
      "average": ${READ_STATS[0]:-0},
      "min": ${READ_STATS[1]:-0},
      "max": ${READ_STATS[2]:-0},
      "stddev": ${READ_STATS[3]:-0},
      "unit": "MB/s"
    },
    "small_file_create": {
      "average": ${CREATE_STATS[0]:-0},
      "min": ${CREATE_STATS[1]:-0},
      "max": ${CREATE_STATS[2]:-0},
      "stddev": ${CREATE_STATS[3]:-0},
      "unit": "IOPS"
    },
    "small_file_read": {
      "average": ${SMALL_READ_STATS[0]:-0},
      "min": ${SMALL_READ_STATS[1]:-0},
      "max": ${SMALL_READ_STATS[2]:-0},
      "stddev": ${SMALL_READ_STATS[3]:-0},
      "unit": "IOPS"
    },
    "latency": {
      "average": ${LATENCY_STATS[0]:-0},
      "min": ${LATENCY_STATS[1]:-0},
      "max": ${LATENCY_STATS[2]:-0},
      "stddev": ${LATENCY_STATS[3]:-0},
      "unit": "ms"
    }
  }
}
EOF

    log "INFO" "JSON results saved to: $json_file"
}

# Parse command line arguments
TEST_SIZE="$DEFAULT_TEST_SIZE"
ITERATIONS="$DEFAULT_ITERATIONS"
TIMEOUT="$DEFAULT_TIMEOUT"
OUTPUT_FORMAT="text"
CLEANUP_FILES=false
VERBOSE=false
PARALLEL=false
PROFILE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --size)
            TEST_SIZE=$2
            shift 2
            ;;
        --iterations)
            ITERATIONS=$2
            shift 2
            ;;
        --timeout)
            TIMEOUT=$2
            shift 2
            ;;
        --output-format)
            OUTPUT_FORMAT=$2
            shift 2
            ;;
        --results-dir)
            RESULTS_DIR=$2
            shift 2
            ;;
        --cleanup)
            CLEANUP_FILES=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --profile)
            PROFILE_NAME=$2
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        -*)
            log "ERROR" "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

TEST_TYPE=$1
TARGET=${2:-}

# Set default profile name if not specified
[[ -z "$PROFILE_NAME" ]] && PROFILE_NAME="$TEST_TYPE-$(date +%Y%m%d-%H%M%S)"

# Initialize test environment
init_test_env

# Log test parameters
log "INFO" "Starting performance test: $TEST_TYPE"
log "INFO" "Parameters: size=$TEST_SIZE, iterations=$ITERATIONS, timeout=${TIMEOUT}s"

# Execute the appropriate test
case $TEST_TYPE in
    samba)
        [[ -z "$TARGET" ]] && { log "ERROR" "Samba target required"; exit 1; }
        test_samba_performance "$TARGET"
        ;;
    nfs)
        [[ -z "$TARGET" ]] && { log "ERROR" "NFS target required"; exit 1; }
        test_nfs_performance "$TARGET"
        ;;
    sshfs)
        [[ -z "$TARGET" ]] && { log "ERROR" "SSHFS target required"; exit 1; }
        test_sshfs_performance "$TARGET"
        ;;
    rsync)
        [[ -z "$TARGET" ]] && { log "ERROR" "Rsync target required"; exit 1; }
        test_rsync_performance "$TARGET"
        ;;
    scp)
        [[ -z "$TARGET" ]] && { log "ERROR" "SCP target required"; exit 1; }
        test_scp_performance "$TARGET"
        ;;
    local)
        [[ -z "$TARGET" ]] && TARGET="/tmp"
        test_local_performance "$TARGET"
        ;;
    *)
        log "ERROR" "Unknown test type: $TEST_TYPE"
        show_usage
        exit 1
        ;;
esac

# Output results in requested format
output_results "$OUTPUT_FORMAT" "$PROFILE_NAME"

log "INFO" "Performance test completed successfully"
log "INFO" "Results saved to: $RESULTS_DIR"