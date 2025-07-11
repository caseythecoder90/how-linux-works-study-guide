#!/bin/bash
# NFS Performance Tuning Script
# File: examples/nfs/nfs-performance-tune.sh

set -euo pipefail

# Configuration
LOG_FILE="/var/log/nfs-performance-tune.log"
BACKUP_DIR="/etc/nfs-tuning-backup-$(date +%Y%m%d-%H%M%S)"
SYSCTL_CONFIG="/etc/sysctl.d/99-nfs-performance.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
        "DEBUG")
            echo -e "${BLUE}[DEBUG] $message${NC}"
            ;;
    esac
}

show_usage() {
    cat << EOF
NFS Performance Tuning Script

Usage: $0 [OPTIONS] <command>

Commands:
    analyze                 Analyze current NFS performance
    tune-server            Apply server-side performance optimizations
    tune-client            Apply client-side performance optimizations
    tune-network           Apply network-level optimizations
    tune-all               Apply all performance optimizations
    benchmark              Run NFS performance benchmarks
    restore                Restore original configuration
    status                 Show current tuning status

Server-side tuning:
    - NFS daemon thread count optimization
    - Kernel buffer size tuning
    - I/O scheduler optimization
    - Memory management tuning

Client-side tuning:
    - Mount option optimization
    - Cache tuning
    - Buffer size optimization
    - Timeout and retry optimization

Network tuning:
    - TCP buffer optimization
    - Network queue optimization
    - Congestion control tuning

Options:
    --workload <type>      Optimize for specific workload (general|database|media|development)
    --network <speed>      Network speed (1gb|10gb|100gb)
    --storage <type>       Storage type (hdd|ssd|nvme)
    --dry-run             Show what would be done without making changes
    --force               Apply changes without prompts
    --backup              Create backup before making changes (default: true)

Examples:
    $0 analyze
    $0 tune-server --workload database --storage ssd
    $0 tune-client --network 10gb
    $0 benchmark
    $0 restore
EOF
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

detect_system_info() {
    log "INFO" "Detecting system information..."

    # CPU information
    local cpu_cores=$(nproc)
    local cpu_threads=$(grep -c ^processor /proc/cpuinfo)

    # Memory information
    local total_mem=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local total_mem_gb=$((total_mem / 1024 / 1024))

    # Storage information
    local storage_type="unknown"
    if [[ -e /sys/block/sda/queue/rotational ]]; then
        if [[ $(cat /sys/block/sda/queue/rotational) == "0" ]]; then
            storage_type="ssd"
        else
            storage_type="hdd"
        fi
    fi

    # Network information
    local network_speed="unknown"
    local primary_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$primary_interface" ]] && [[ -e "/sys/class/net/$primary_interface/speed" ]]; then
        local speed=$(cat "/sys/class/net/$primary_interface/speed" 2>/dev/null || echo "unknown")
        case $speed in
            1000) network_speed="1gb" ;;
            10000) network_speed="10gb" ;;
            100000) network_speed="100gb" ;;
        esac
    fi

    log "INFO" "System detected:"
    log "INFO" "  CPU cores: $cpu_cores, threads: $cpu_threads"
    log "INFO" "  Memory: ${total_mem_gb}GB"
    log "INFO" "  Primary storage: $storage_type"
    log "INFO" "  Network speed: $network_speed"

    # Export for use by other functions
    export DETECTED_CPU_CORES=$cpu_cores
    export DETECTED_CPU_THREADS=$cpu_threads
    export DETECTED_MEMORY_GB=$total_mem_gb
    export DETECTED_STORAGE_TYPE=$storage_type
    export DETECTED_NETWORK_SPEED=$network_speed
}

analyze_current_performance() {
    log "INFO" "Analyzing current NFS performance..."

    echo "NFS Performance Analysis"
    echo "======================="

    # Check if NFS server is running
    if systemctl is-active --quiet nfs-kernel-server; then
        echo "✓ NFS server is running"

        # Current NFS thread count
        if [[ -f /proc/fs/nfsd/threads ]]; then
            local current_threads=$(cat /proc/fs/nfsd/threads)
            echo "  Current NFS threads: $current_threads"
        fi

        # NFS statistics
        if [[ -f /proc/net/rpc/nfsd ]]; then
            echo "  NFS statistics:"
            awk '/^rc/ {print "    RPC calls: " $2}' /proc/net/rpc/nfsd
            awk '/^fh/ {print "    File handle lookups: " $2}' /proc/net/rpc/nfsd
            awk '/^io/ {print "    I/O operations: read=" $2 " write=" $3}' /proc/net/rpc/nfsd
        fi
    else
        echo "✗ NFS server is not running"
    fi

    # Network configuration
    echo
    echo "Network Configuration:"
    local primary_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$primary_interface" ]]; then
        echo "  Primary interface: $primary_interface"

        # TCP buffer sizes
        echo "  TCP buffer sizes:"
        echo "    rmem: $(cat /proc/sys/net/ipv4/tcp_rmem)"
        echo "    wm