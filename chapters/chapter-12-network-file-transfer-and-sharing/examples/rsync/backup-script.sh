#!/bin/bash
# Production rsync backup script with rotation and logging
# File: examples/rsync/backup-script.sh
# Usage: ./backup-script.sh [source] [destination]

set -euo pipefail

# Configuration
BACKUP_SOURCE="${1:-/home}"
BACKUP_BASE="${2:-/backup}"
BACKUP_LOG="/var/log/backup.log"
RETENTION_DAYS=30
EXCLUDE_FILE="/etc/backup-excludes.txt"
MAX_PARALLEL_JOBS=4

# Date formatting
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DEST="${BACKUP_BASE}/${DATE}"
LATEST_LINK="${BACKUP_BASE}/latest"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$BACKUP_LOG"
}

# Error handling
trap 'log "ERROR: Backup script failed on line $LINENO"' ERR

# Check prerequisites
check_prerequisites() {
    if [[ ! -d "$BACKUP_SOURCE" ]]; then
        log "ERROR: Source directory $BACKUP_SOURCE does not exist"
        exit 1
    fi

    if [[ ! -d "$BACKUP_BASE" ]]; then
        log "Creating backup base directory: $BACKUP_BASE"
        mkdir -p "$BACKUP_BASE"
    fi

    # Check available disk space
    local available_space=$(df "$BACKUP_BASE" | awk 'NR==2 {print $4}')
    local source_size=$(du -s "$BACKUP_SOURCE" | awk '{print $1}')

    if [[ $available_space -lt $source_size ]]; then
        log "WARNING: Insufficient disk space. Available: $available_space KB, Required: $source_size KB"
    fi
}

# Create exclude file if it doesn't exist
create_exclude_file() {
    if [[ ! -f "$EXCLUDE_FILE" ]]; then
        log "Creating default exclude file: $EXCLUDE_FILE"
        cat > "$EXCLUDE_FILE" << 'EOF'
# Temporary files
*.tmp
*.temp
*~
.#*
#*#

# Cache directories
cache/
.cache/
__pycache__/
.thumbnails/
*.cache

# Version control
.git/
.svn/
.hg/
.bzr/

# Development files
node_modules/
.venv/
venv/
.pytest_cache/
.coverage
*.pyc
*.pyo

# System files
.DS_Store
Thumbs.db
desktop.ini
$RECYCLE.BIN/
Trash*/
lost+found/

# System directories (if backing up root)
/proc/
/sys/
/dev/
/run/
/tmp/
/var/tmp/

# Log files
*.log
logs/

# Large media files (uncomment if needed)
# *.iso
# *.img
# *.vmdk
# *.vdi
EOF
    fi
}

# Perform the backup
perform_backup() {
    log "Starting backup: $BACKUP_SOURCE -> $BACKUP_DEST"

    # rsync options
    local rsync_opts=(
        -av                          # Archive mode, verbose
        --delete                     # Delete files not in source
        --delete-excluded           # Delete excluded files
        --exclude-from="$EXCLUDE_FILE"
        --human-readable            # Human readable output
        --progress                  # Show progress
        --stats                     # Show statistics
        --partial                   # Keep partially transferred files
        --partial-dir=.rsync-partial # Partial transfer directory
        --numeric-ids               # Don't map uid/gid values
        --sparse                    # Handle sparse files efficiently
        --hard-links               # Preserve hard links
        --acls                     # Preserve ACLs
        --xattrs                   # Preserve extended attributes
    )

    # Add link-dest if previous backup exists
    if [[ -d "$LATEST_LINK" ]]; then
        rsync_opts+=(--link-dest="$LATEST_LINK")
        log "Using link destination: $LATEST_LINK"
    fi

    # Run rsync with error handling
    local start_time=$(date +%s)
    if rsync "${rsync_opts[@]}" "$BACKUP_SOURCE/" "$BACKUP_DEST/"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "Backup completed successfully in ${duration} seconds"

        # Update latest symlink atomically
        local temp_link="${LATEST_LINK}.tmp.$$"
        ln -s "$BACKUP_DEST" "$temp_link"
        mv "$temp_link" "$LATEST_LINK"
        log "Updated latest symlink"

        return 0
    else
        log "ERROR: Backup failed with exit code $?"
        return 1
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days"

    local deleted_count=0
    while IFS= read -r -d '' backup_dir; do
        rm -rf "$backup_dir"
        ((deleted_count++))
        log "Deleted old backup: $(basename "$backup_dir")"
    done < <(find "$BACKUP_BASE" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS -print0)

    log "Deleted $deleted_count old backup(s)"
}

# Generate backup report
generate_report() {
    local status=$1
    local report_file="${BACKUP_BASE}/backup-report-${DATE}.txt"

    cat > "$report_file" << EOF
Backup Report - $(date)
======================

Source: $BACKUP_SOURCE
Destination: $BACKUP_DEST
Status: $status
Log: $BACKUP_LOG

Backup Statistics:
$(tail -20 "$BACKUP_LOG" | grep -E "(files transferred|total size|speedup)")

Disk Usage:
$(df -h "$BACKUP_BASE")

Latest Backups:
$(ls -lah "$BACKUP_BASE" | head -10)
EOF

    log "Backup report generated: $report_file"
}

# Send notification (email or webhook)
send_notification() {
    local status=$1
    local message="Backup $status on $(hostname): $BACKUP_SOURCE -> $BACKUP_DEST"

    # Email notification (if mail is configured)
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "Backup $status" admin@company.com
    fi

    # Slack webhook notification (if configured)
    if [[ -n "${SLACK_WEBHOOK:-}" ]]; then
        curl -X POST "$SLACK_WEBHOOK" \
            -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            2>/dev/null || true
    fi

    # Discord webhook notification (if configured)
    if [[ -n "${DISCORD_WEBHOOK:-}" ]]; then
        curl -H "Content-Type: application/json" \
            -X POST \
            -d "{\"content\":\"$message\"}" \
            "$DISCORD_WEBHOOK" \
            2>/dev/null || true
    fi
}

# Verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."

    # Check if destination exists and is readable
    if [[ ! -d "$BACKUP_DEST" ]]; then
        log "ERROR: Backup destination does not exist"
        return 1
    fi

    # Quick integrity check - compare file counts
    local source_count=$(find "$BACKUP_SOURCE" -type f | wc -l)
    local dest_count=$(find "$BACKUP_DEST" -type f | wc -l)

    if [[ $dest_count -lt $((source_count * 95 / 100)) ]]; then
        log "WARNING: Destination has significantly fewer files than source"
        log "Source files: $source_count, Destination files: $dest_count"
        return 1
    fi

    log "Backup verification passed: $dest_count files backed up"
    return 0
}

# Lock file management
acquire_lock() {
    local lock_file="/var/run/backup.lock"

    if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file")
        if kill -0 "$lock_pid" 2>/dev/null; then
            log "ERROR: Another backup is already running (PID: $lock_pid)"
            exit 1
        else
            log "Removing stale lock file"
            rm -f "$lock_file"
        fi
    fi

    echo $$ > "$lock_file"
    trap 'rm -f "$lock_file"' EXIT
}

# Main execution
main() {
    acquire_lock
    check_prerequisites
    create_exclude_file

    log "========== Backup Started =========="

    if perform_backup && verify_backup; then
        cleanup_old_backups
        generate_report "SUCCESS"
        send_notification "SUCCESS"
        log "========== Backup Completed Successfully =========="
        exit 0
    else
        generate_report "FAILED"
        send_notification "FAILED"
        log "========== Backup Failed =========="
        exit 1
    fi
}

# Run main function
main "$@"