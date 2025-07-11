#!/bin/bash
# Comprehensive file sharing services health check and monitoring script
# File: examples/monitoring/file-share-health-check.sh
# Usage: ./file-share-health-check.sh [--verbose] [--json] [--prometheus]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-/etc/file-share-monitor.conf}"
LOG_FILE="${LOG_FILE:-/var/log/file-share-health.log}"
TEMP_DIR="/tmp/file-share-monitor.$$"
EXIT_CODE=0

# Service configurations
SAMBA_SHARES=("shared" "finance" "it" "hr" "public")
NFS_EXPORTS=("/srv/nfs/public" "/srv/nfs/development" "/srv/nfs/finance")
SSHFS_MOUNTS=("/mnt/remote1" "/mnt/remote2")

# Thresholds
DISK_USAGE_WARNING=80
DISK_USAGE_CRITICAL=90
MEMORY_USAGE_WARNING=80
MEMORY_USAGE_CRITICAL=90
LOAD_WARNING=4.0
LOAD_CRITICAL=8.0
RESPONSE_TIME_WARNING=5
RESPONSE_TIME_CRITICAL=10

# Notification settings
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
EMAIL_RECIPIENTS="${EMAIL_RECIPIENTS:-admin@company.com}"
PROMETHEUS_PUSHGATEWAY="${PROMETHEUS_PUSHGATEWAY:-}"

# Parse command line arguments
VERBOSE=false
JSON_OUTPUT=false
PROMETHEUS_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --prometheus)
            PROMETHEUS_OUTPUT=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            show_usage
            exit 1
            ;;
    esac
done

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --verbose, -v    Enable verbose output
    --json          Output results in JSON format
    --prometheus    Send metrics to Prometheus pushgateway
    --help, -h      Show this help message

Environment Variables:
    CONFIG_FILE             Configuration file path (default: /etc/file-share-monitor.conf)
    LOG_FILE               Log file path (default: /var/log/file-share-health.log)
    SLACK_WEBHOOK          Slack webhook URL for notifications
    EMAIL_RECIPIENTS       Email addresses for notifications
    PROMETHEUS_PUSHGATEWAY Prometheus pushgateway URL

Examples:
    $0 --verbose
    $0 --json | jq '.'
    PROMETHEUS_PUSHGATEWAY=http://monitoring:9091 $0 --prometheus
EOF
}

# Logging functions
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"

    if [[ "$VERBOSE" == "true" ]] || [[ "$level" == "ERROR" ]] || [[ "$level" == "WARN" ]]; then
        echo "[$level] $message" >&2
    fi
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; EXIT_CODE=1; }
log_error() { log "ERROR" "$@"; EXIT_CODE=2; }

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Initialize
mkdir -p "$TEMP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Load configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Metrics collection
declare -A METRICS

collect_metric() {
    local name=$1
    local value=$2
    local labels=${3:-""}

    METRICS["$name{$labels}"]=$value
}

# Check if service is running
check_service() {
    local service=$1
    local status_file="$TEMP_DIR/service_${service}.status"

    if systemctl is-active --quiet "$service"; then
        log_info "✓ Service $service is running"
        collect_metric "service_up" "1" "service=\"$service\""
        echo "UP" > "$status_file"
        return 0
    else
        log_error "✗ Service $service is not running"
        collect_metric "service_up" "0" "service=\"$service\""
        echo "DOWN" > "$status_file"
        return 1
    fi
}

# Check service response time
check_service_response() {
    local service=$1
    local test_command=$2
    local timeout=${3:-10}

    local start_time=$(date +%s.%N)
    if timeout "$timeout" bash -c "$test_command" >/dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc -l)
        local response_time_ms=$(echo "$response_time * 1000" | bc -l | cut -d. -f1)

        collect_metric "service_response_time_ms" "$response_time_ms" "service=\"$service\""

        if (( $(echo "$response_time > $RESPONSE_TIME_CRITICAL" | bc -l) )); then
            log_error "✗ $service response time critical: ${response_time}s"
            return 2
        elif (( $(echo "$response_time > $RESPONSE_TIME_WARNING" | bc -l) )); then
            log_warn "⚠ $service response time warning: ${response_time}s"
            return 1
        else
            log_info "✓ $service response time normal: ${response_time}s"
            return 0
        fi
    else
        log_error "✗ $service response test failed"
        collect_metric "service_response_time_ms" "-1" "service=\"$service\""
        return 2
    fi
}

# Check Samba services
check_samba() {
    log_info "Checking Samba services..."
    local samba_status=0

    # Check services
    check_service "smbd" || samba_status=1
    check_service "nmbd" || samba_status=1

    # Test configuration
    if testparm -s >/dev/null 2>&1; then
        log_info "✓ Samba configuration is valid"
        collect_metric "samba_config_valid" "1"
    else
        log_error "✗ Samba configuration has errors"
        collect_metric "samba_config_valid" "0"
        samba_status=1
    fi

    # Check Samba response
    check_service_response "samba" "smbclient -L localhost -N" || samba_status=1

    # Check shares accessibility
    for share in "${SAMBA_SHARES[@]}"; do
        local share_path="/srv/samba/$share"
        if [[ -d "$share_path" ]]; then
            local share_size=$(du -s "$share_path" 2>/dev/null | awk '{print $1}')
            log_info "✓ Share directory exists: $share (${share_size}KB)"
            collect_metric "samba_share_size_kb" "$share_size" "share=\"$share\""

            # Check permissions
            if [[ -r "$share_path" ]]; then
                collect_metric "samba_share_readable" "1" "share=\"$share\""
            else
                log_warn "⚠ Share not readable: $share"
                collect_metric "samba_share_readable" "0" "share=\"$share\""
                samba_status=1
            fi
        else
            log_error "✗ Share directory missing: $share"
            collect_metric "samba_share_exists" "0" "share=\"$share\""
            samba_status=1
        fi
    done

    # Check active connections
    local active_connections=$(smbstatus -b 2>/dev/null | grep -c "^[0-9]" || echo "0")
    local active_locks=$(smbstatus -L 2>/dev/null | grep -c "^[0-9]" || echo "0")

    collect_metric "samba_active_connections" "$active_connections"
    collect_metric "samba_active_locks" "$active_locks"

    log_info "Samba connections: $active_connections, locks: $active_locks"

    return $samba_status
}

# Check NFS services
check_nfs() {
    log_info "Checking NFS services..."
    local nfs_status=0

    # Check services
    check_service "nfs-kernel-server" || nfs_status=1
    check_service "rpcbind" || nfs_status=1

    # Check exports
    if exportfs -v >/dev/null 2>&1; then
        log_info "✓ NFS exports are active"
        collect_metric "nfs_exports_active" "1"

        # Count active exports
        local export_count=$(exportfs -v | grep -c "^/" || echo "0")
        collect_metric "nfs_export_count" "$export_count"
        log_info "Active NFS exports: $export_count"
    else
        log_error "✗ NFS exports are not active"
        collect_metric "nfs_exports_active" "0"
        nfs_status=1
    fi

    # Check NFS response
    check_service_response "nfs" "showmount -e localhost" || nfs_status=1

    # Check export directories
    for export in "${NFS_EXPORTS[@]}"; do
        if [[ -d "$export" ]]; then
            local export_size=$(du -s "$export" 2>/dev/null | awk '{print $1}')
            log_info "✓ Export directory exists: $export (${export_size}KB)"
            collect_metric "nfs_export_size_kb" "$export_size" "export=\"$export\""

            # Check NFS stats
            if [[ -f "/proc/net/rpc/nfsd" ]]; then
                local rpc_calls=$(awk '/^rc/ {print $2}' /proc/net/rpc/nfsd)
                collect_metric "nfs_rpc_calls_total" "$rpc_calls"
            fi
        else
            log_error "✗ Export directory missing: $export"
            collect_metric "nfs_export_exists" "0" "export=\"$export\""
            nfs_status=1
        fi
    done

    return $nfs_status
}

# Check SSHFS mounts
check_sshfs() {
    log_info "Checking SSHFS mounts..."
    local sshfs_status=0

    for mount in "${SSHFS_MOUNTS[@]}"; do
        if mountpoint -q "$mount" 2>/dev/null; then
            # Test mount responsiveness
            if timeout 10 ls "$mount" >/dev/null 2>&1; then
                log_info "✓ SSHFS mount is responsive: $mount"
                collect_metric "sshfs_mount_responsive" "1" "mount=\"$mount\""

                # Check mount statistics
                local mount_size=$(df "$mount" 2>/dev/null | awk 'NR==2 {print $3}' || echo "0")
                collect_metric "sshfs_mount_used_kb" "$mount_size" "mount=\"$mount\""
            else
                log_error "✗ SSHFS mount is unresponsive: $mount"
                collect_metric "sshfs_mount_responsive" "0" "mount=\"$mount\""
                sshfs_status=1
            fi
        else
            log_info "? SSHFS mount not active: $mount"
            collect_metric "sshfs_mount_active" "0" "mount=\"$mount\""
        fi
    done

    return $sshfs_status
}

# Check system resources
check_system_resources() {
    log_info "Checking system resources..."
    local resource_status=0

    # Check disk space
    local paths=("/srv/samba" "/srv/nfs" "/home" "/var/log")

    for path in "${paths[@]}"; do
        if [[ -d "$path" ]]; then
            local usage=$(df "$path" | awk 'NR==2 {print $5}' | sed 's/%//')
            local path_clean=$(echo "$path" | sed 's/[^a-zA-Z0-9]/_/g')

            collect_metric "disk_usage_percent" "$usage" "path=\"$path\""

            if [[ $usage -gt $DISK_USAGE_CRITICAL ]]; then
                log_error "✗ Critical disk usage on $path: ${usage}%"
                resource_status=2
            elif [[ $usage -gt $DISK_USAGE_WARNING ]]; then
                log_warn "⚠ High disk usage on $path: ${usage}%"
                resource_status=1
            else
                log_info "✓ Normal disk usage on $path: ${usage}%"
            fi
        fi
    done

    # Check memory usage
    local mem_info=$(free | grep "^Mem:")
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))

    collect_metric "memory_usage_percent" "$mem_usage"

    if [[ $mem_usage -gt $MEMORY_USAGE_CRITICAL ]]; then
        log_error "✗ Critical memory usage: ${mem_usage}%"
        resource_status=2
    elif [[ $mem_usage -gt $MEMORY_USAGE_WARNING ]]; then
        log_warn "⚠ High memory usage: ${mem_usage}%"
        resource_status=1
    else
        log_info "✓ Normal memory usage: ${mem_usage}%"
    fi

    # Check load average
    local load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | tr -d ' ')
    local load_int=$(echo "$load_1min" | cut -d. -f1)

    collect_metric "load_average_1min" "$load_1min"

    if (( $(echo "$load_1min > $LOAD_CRITICAL" | bc -l) )); then
        log_error "✗ Critical system load: $load_1min"
        resource_status=2
    elif (( $(echo "$load_1min > $LOAD_WARNING" | bc -l) )); then
        log_warn "⚠ High system load: $load_1min"
        resource_status=1
    else
        log_info "✓ Normal system load: $load_1min"
    fi

    # Check network connectivity
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log_info "✓ External network connectivity OK"
        collect_metric "network_connectivity" "1"
    else
        log_warn "⚠ External network connectivity issues"
        collect_metric "network_connectivity" "0"
        resource_status=1
    fi

    return $resource_status
}

# Send notifications
send_notification() {
    local status=$1
    local summary=$2
    local details=$3

    local hostname=$(hostname)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Determine severity and icon
    local severity icon
    case $status in
        0) severity="SUCCESS"; icon="✅" ;;
        1) severity="WARNING"; icon="⚠️" ;;
        *) severity="CRITICAL"; icon="🚨" ;;
    esac

    local message="$icon File Share Health Check - $severity
Host: $hostname
Time: $timestamp
Status: $summary

Details:
$details"

    # Send Slack notification
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        local slack_payload=$(cat << EOF
{
    "text": "$icon File Share Health Check - $severity",
    "attachments": [
        {
            "color": "$( [[ $status -eq 0 ]] && echo "good" || [[ $status -eq 1 ]] && echo "warning" || echo "danger" )",
            "fields": [
                {"title": "Host", "value": "$hostname", "short": true},
                {"title": "Time", "value": "$timestamp", "short": true},
                {"title": "Status", "value": "$summary", "short": false}
            ]
        }
    ]
}
EOF
        )

        curl -s -X POST "$SLACK_WEBHOOK" \
            -H 'Content-type: application/json' \
            -d "$slack_payload" >/dev/null || true
    fi

    # Send email notification
    if command -v mail >/dev/null 2>&1 && [[ -n "$EMAIL_RECIPIENTS" ]]; then
        echo "$message" | mail -s "File Share Health Check - $severity on $hostname" "$EMAIL_RECIPIENTS" || true
    fi
}

# Send metrics to Prometheus
send_prometheus_metrics() {
    if [[ -n "$PROMETHEUS_PUSHGATEWAY" ]]; then
        local metrics_file="$TEMP_DIR/metrics.txt"

        # Generate Prometheus metrics
        for metric in "${!METRICS[@]}"; do
            echo "$metric ${METRICS[$metric]}" >> "$metrics_file"
        done

        # Add timestamp
        echo "# TYPE file_share_health_check_timestamp gauge" >> "$metrics_file"
        echo "file_share_health_check_timestamp $(date +%s)" >> "$metrics_file"

        # Push to gateway
        curl -s --data-binary @"$metrics_file" \
            "$PROMETHEUS_PUSHGATEWAY/metrics/job/file_share_health/instance/$(hostname)" || true

        log_info "Metrics sent to Prometheus pushgateway"
    fi
}

# Generate JSON output
generate_json_output() {
    local status=$1

    cat << EOF > "$TEMP_DIR/output.json"
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "status": $status,
    "status_text": "$( [[ $status -eq 0 ]] && echo "OK" || [[ $status -eq 1 ]] && echo "WARNING" || echo "CRITICAL" )",
    "metrics": {
EOF

    local first=true
    for metric in "${!METRICS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$TEMP_DIR/output.json"
        fi
        echo "        \"$metric\": ${METRICS[$metric]}" >> "$TEMP_DIR/output.json"
    done

    cat << EOF >> "$TEMP_DIR/output.json"
    }
}
EOF

    cat "$TEMP_DIR/output.json"
}

# Main execution
main() {
    log_info "Starting file sharing health check..."

    local check_status=0
    local summary_parts=()

    # Run all checks
    if ! check_samba; then
        summary_parts+=("Samba issues")
        [[ $? -eq 2 ]] && check_status=2 || [[ $check_status -eq 0 ]] && check_status=1
    else
        summary_parts+=("Samba OK")
    fi

    if ! check_nfs; then
        summary_parts+=("NFS issues")
        [[ $? -eq 2 ]] && check_status=2 || [[ $check_status -eq 0 ]] && check_status=1
    else
        summary_parts+=("NFS OK")
    fi

    if ! check_sshfs; then
        summary_parts+=("SSHFS issues")
        [[ $? -eq 2 ]] && check_status=2 || [[ $check_status -eq 0 ]] && check_status=1
    else
        summary_parts+=("SSHFS OK")
    fi

    if ! check_system_resources; then
        summary_parts+=("Resource issues")
        [[ $? -eq 2 ]] && check_status=2 || [[ $check_status -eq 0 ]] && check_status=1
    else
        summary_parts+=("Resources OK")
    fi

    # Generate summary
    local summary=$(IFS=", "; echo "${summary_parts[*]}")

    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        generate_json_output $check_status
    else
        log_info "Health check completed: $summary (exit code: $check_status)"
    fi

    # Send notifications for non-zero status
    if [[ $check_status -ne 0 ]]; then
        local details=$(tail -20 "$LOG_FILE" | grep -E "(ERROR|WARN)")
        send_notification $check_status "$summary" "$details"
    fi

    # Send metrics to Prometheus
    if [[ "$PROMETHEUS_OUTPUT" == "true" ]]; then
        send_prometheus_metrics
    fi

    exit $check_status
}

# Run main function
main "$@"