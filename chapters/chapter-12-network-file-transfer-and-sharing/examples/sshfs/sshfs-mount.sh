#!/bin/bash
# SSHFS mounting script with advanced features
# File: examples/sshfs/sshfs-mount.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${HOME}/.sshfs-mounts.conf"
LOG_FILE="/var/log/sshfs-mount.log"
MOUNT_BASE_DIR="${MOUNT_BASE_DIR:-$HOME/mounts}"
DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa"

# Default SSHFS options for different use cases
PERFORMANCE_OPTS="cache=yes,compression=yes,large_read,auto_cache,kernel_cache"
SECURITY_OPTS="compression=no,cache=no,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"
DEVELOPMENT_OPTS="cache=yes,compression=yes,reconnect,follow_symlinks,workaround=rename"
MEDIA_OPTS="cache=yes,compression=no,large_read,auto_cache,big_writes"

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
SSHFS Mount Management Script

Usage: $0 [OPTIONS] <command> [arguments]

Commands:
    mount <name>                Mount a configured connection
    umount <name>               Unmount a connection
    add <name> <user@host:path> Add new connection configuration
    remove <name>               Remove connection configuration
    list                        List all configured connections
    status                      Show mount status for all connections
    test <name>                 Test SSH connectivity for a connection
    edit <name>                 Edit connection configuration
    mount-all                   Mount all configured connections
    umount-all                  Unmount all active connections
    cleanup                     Clean up stale mount points

Mount Options:
    --key <path>                SSH private key file (default: ~/.ssh/id_rsa)
    --port <port>               SSH port (default: 22)
    --options <opts>            Custom SSHFS options
    --profile <profile>         Use predefined profile (performance|security|development|media)
    --local-path <path>         Override local mount path
    --reconnect                 Enable automatic reconnection
    --readonly                  Mount read-only
    --background                Mount in background (daemon mode)

Global Options:
    --config <file>             Configuration file (default: ~/.sshfs-mounts.conf)
    --base-dir <path>           Base directory for mount points
    --verbose                   Enable verbose output
    --dry-run                   Show what would be done without executing

Examples:
    # Add a new connection
    $0 add work user@work-server.com:/home/user/documents

    # Mount with performance profile
    $0 --profile performance mount work

    # Mount with custom options
    $0 --options "cache=yes,compression=yes" mount work

    # Add development server with custom key
    $0 --key ~/.ssh/dev_key add dev dev@dev-server:/var/www

    # Mount all configured connections
    $0 mount-all

    # Check status of all mounts
    $0 status

Configuration File Format (~/.sshfs-mounts.conf):
    [connection_name]
    remote = user@hostname:/remote/path
    local = /local/mount/point
    key = /path/to/ssh/key
    port = 22
    options = cache=yes,compression=yes
    description = Connection description
EOF
}

init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "INFO" "Creating configuration file: $CONFIG_FILE"

        cat > "$CONFIG_FILE" << EOF
# SSHFS Mount Configuration
# Generated by: $0
# Date: $(date)

# Example configuration:
# [work]
# remote = user@work-server.com:/home/user/documents
# local = \$HOME/mounts/work
# key = \$HOME/.ssh/id_rsa
# port = 22
# options = cache=yes,compression=yes,reconnect
# description = Work server documents

# [development]
# remote = dev@dev-server:/var/www
# local = \$HOME/mounts/dev
# key = \$HOME/.ssh/dev_key
# port = 2222
# options = cache=yes,follow_symlinks,reconnect
# description = Development server web root
EOF

        log "INFO" "✓ Configuration file created. Edit it to add your connections."
    fi
}

read_config() {
    local connection_name=$1

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR" "Configuration file not found: $CONFIG_FILE"
        return 1
    fi

    # Parse INI-style configuration
    local in_section=false
    local section=""

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Check for section header
        if [[ $line =~ ^\[([^]]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            if [[ "$section" == "$connection_name" ]]; then
                in_section=true
            else
                in_section=false
            fi
            continue
        fi

        # Read key-value pairs in the target section
        if [[ "$in_section" == "true" ]] && [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]// /}"
            local value="${BASH_REMATCH[2]}"

            # Expand environment variables
            value=$(eval echo "$value")

            case $key in
                "remote") REMOTE_PATH="$value" ;;
                "local") LOCAL_PATH="$value" ;;
                "key") SSH_KEY="$value" ;;
                "port") SSH_PORT="$value" ;;
                "options") SSHFS_OPTIONS="$value" ;;
                "description") DESCRIPTION="$value" ;;
            esac
        fi
    done < "$CONFIG_FILE"

    # Check if we found the connection
    if [[ -z "${REMOTE_PATH:-}" ]]; then
        log "ERROR" "Connection not found in configuration: $connection_name"
        return 1
    fi

    # Set defaults for missing values
    LOCAL_PATH="${LOCAL_PATH:-$MOUNT_BASE_DIR/$connection_name}"
    SSH_KEY="${SSH_KEY:-$DEFAULT_SSH_KEY}"
    SSH_PORT="${SSH_PORT:-22}"
    SSHFS_OPTIONS="${SSHFS_OPTIONS:-cache=yes,compression=yes,reconnect}"
    DESCRIPTION="${DESCRIPTION:-SSHFS mount for $connection_name}"

    return 0
}

validate_connection() {
    local connection_name=$1

    # Read configuration
    if ! read_config "$connection_name"; then
        return 1
    fi

    # Validate remote path format
    if [[ ! $REMOTE_PATH =~ ^[^@]+@[^:]+:.+ ]]; then
        log "ERROR" "Invalid remote path format: $REMOTE_PATH"
        log "ERROR" "Expected format: user@hostname:/path"
        return 1
    fi

    # Extract components
    local user_host="${REMOTE_PATH%:*}"
    local remote_dir="${REMOTE_PATH#*:}"
    local user="${user_host%@*}"
    local host="${user_host#*@}"

    # Validate SSH key
    if [[ ! -f "$SSH_KEY" ]]; then
        log "ERROR" "SSH key not found: $SSH_KEY"
        return 1
    fi

    # Check key permissions
    local key_perms=$(stat -c %a "$SSH_KEY")
    if [[ "$key_perms" != "600" ]]; then
        log "WARN" "SSH key has incorrect permissions: $key_perms (should be 600)"
        log "INFO" "Fixing permissions: chmod 600 $SSH_KEY"
        chmod 600 "$SSH_KEY"
    fi

    # Export parsed values for use by other functions
    export PARSED_USER="$user"
    export PARSED_HOST="$host"
    export PARSED_REMOTE_DIR="$remote_dir"

    return 0
}

test_ssh_connectivity() {
    local connection_name=$1
    local timeout=${2:-10}

    log "INFO" "Testing SSH connectivity for: $connection_name"

    if ! validate_connection "$connection_name"; then
        return 1
    fi

    # Test SSH connectivity
    local ssh_cmd="ssh"
    [[ "$SSH_PORT" != "22" ]] && ssh_cmd="$ssh_cmd -p $SSH_PORT"
    ssh_cmd="$ssh_cmd -i $SSH_KEY -o ConnectTimeout=$timeout -o BatchMode=yes"
    ssh_cmd="$ssh_cmd $PARSED_USER@$PARSED_HOST"

    log "DEBUG" "Testing: $ssh_cmd 'echo SSH connection successful'"

    if $ssh_cmd "echo 'SSH connection successful'" >/dev/null 2>&1; then
        log "INFO" "✓ SSH connectivity test passed for: $connection_name"

        # Test remote directory accessibility
        if $ssh_cmd "test -d '$PARSED_REMOTE_DIR'" >/dev/null 2>&1; then
            log "INFO" "✓ Remote directory accessible: $PARSED_REMOTE_DIR"
        else
            log "WARN" "⚠ Remote directory may not exist: $PARSED_REMOTE_DIR"
        fi

        return 0
    else
        log "ERROR" "✗ SSH connectivity test failed for: $connection_name"
        log "ERROR" "Check SSH key, hostname, and network connectivity"
        return 1
    fi
}

mount_sshfs() {
    local connection_name=$1
    local profile=${2:-""}
    local custom_options=${3:-""}
    local readonly=${4:-false}
    local background=${5:-false}

    log "INFO" "Mounting SSHFS connection: $connection_name"

    if ! validate_connection "$connection_name"; then
        return 1
    fi

    # Check if already mounted
    if mountpoint -q "$LOCAL_PATH" 2>/dev/null; then
        log "WARN" "Already mounted: $LOCAL_PATH"
        return 0
    fi

    # Create local mount point
    if [[ ! -d "$LOCAL_PATH" ]]; then
        mkdir -p "$LOCAL_PATH"
        log "INFO" "Created mount point: $LOCAL_PATH"
    fi

    # Build SSHFS options
    local sshfs_opts="$SSHFS_OPTIONS"

    # Apply profile-specific options
    case "$profile" in
        "performance")
            sshfs_opts="$PERFORMANCE_OPTS"
            ;;
        "security")
            sshfs_opts="$SECURITY_OPTS"
            ;;
        "development")
            sshfs_opts="$DEVELOPMENT_OPTS"
            ;;
        "media")
            sshfs_opts="$MEDIA_OPTS"
            ;;
    esac

    # Add custom options
    if [[ -n "$custom_options" ]]; then
        sshfs_opts="$custom_options"
    fi

    # Add SSH-specific options
    sshfs_opts="$sshfs_opts,IdentityFile=$SSH_KEY"
    [[ "$SSH_PORT" != "22" ]] && sshfs_opts="$sshfs_opts,Port=$SSH_PORT"
    [[ "$readonly" == "true" ]] && sshfs_opts="$sshfs_opts,ro"

    # Build SSHFS command
    local sshfs_cmd="sshfs -o $sshfs_opts $REMOTE_PATH $LOCAL_PATH"

    log "DEBUG" "SSHFS command: $sshfs_cmd"

    # Execute mount
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "DRY RUN: Would execute: $sshfs_cmd"
        return 0
    fi

    if [[ "$background" == "true" ]]; then
        # Mount in background
        nohup $sshfs_cmd >/dev/null 2>&1 &
        local mount_pid=$!

        # Wait a moment and check if mount succeeded
        sleep 2
        if mountpoint -q "$LOCAL_PATH" 2>/dev/null; then
            log "INFO" "✓ Successfully mounted in background: $connection_name"
            log "INFO" "  Local path: $LOCAL_PATH"
            log "INFO" "  Remote path: $REMOTE_PATH"
            echo "$mount_pid" > "$LOCAL_PATH/.sshfs-pid"
        else
            log "ERROR" "✗ Background mount failed: $connection_name"
            return 1
        fi
    else
        # Mount in foreground
        if $sshfs_cmd; then
            log "INFO" "✓ Successfully mounted: $connection_name"
            log "INFO" "  Local path: $LOCAL_PATH"
            log "INFO" "  Remote path: $REMOTE_PATH"
            log "INFO" "  Description: $DESCRIPTION"
        else
            log "ERROR" "✗ Mount failed: $connection_name"
            rmdir "$LOCAL_PATH" 2>/dev/null || true
            return 1
        fi
    fi

    return 0
}

unmount_sshfs() {
    local connection_name=$1
    local force=${2:-false}

    log "INFO" "Unmounting SSHFS connection: $connection_name"

    if ! validate_connection "$connection_name"; then
        return 1
    fi

    # Check if mounted
    if ! mountpoint -q "$LOCAL_PATH" 2>/dev/null; then
        log "WARN" "Not mounted: $LOCAL_PATH"
        return 0
    fi

    # Try graceful unmount first
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "DRY RUN: Would unmount: $LOCAL_PATH"
        return 0
    fi

    if fusermount -u "$LOCAL_PATH" 2>/dev/null; then
        log "INFO" "✓ Successfully unmounted: $connection_name"
    elif [[ "$force" == "true" ]]; then
        log "WARN" "Graceful unmount failed, trying force unmount..."
        if fusermount -uz "$LOCAL_PATH" 2>/dev/null; then
            log "INFO" "✓ Force unmount successful: $connection_name"
        else
            log "ERROR" "✗ Force unmount failed: $connection_name"
            return 1
        fi
    else
        log "ERROR" "✗ Unmount failed: $connection_name"
        log "INFO" "Try with --force option or check for open files: lsof +D $LOCAL_PATH"
        return 1
    fi

    # Clean up PID file if it exists
    [[ -f "$LOCAL_PATH/.sshfs-pid" ]] && rm -f "$LOCAL_PATH/.sshfs-pid"

    # Remove empty mount point
    rmdir "$LOCAL_PATH" 2>/dev/null || true

    return 0
}

add_connection() {
    local name=$1
    local remote_path=$2
    local description=${3:-"SSHFS connection to $name"}

    log "INFO" "Adding connection: $name"

    # Validate remote path format
    if [[ ! $remote_path =~ ^[^@]+@[^:]+:.+ ]]; then
        log "ERROR" "Invalid remote path format: $remote_path"
        log "ERROR" "Expected format: user@hostname:/path"
        return 1
    fi

    # Initialize config if needed
    init_config

    # Check if connection already exists
    if grep -q "^\[$name\]" "$CONFIG_FILE" 2>/dev/null; then
        log "WARN" "Connection already exists: $name"
        echo -n "Overwrite existing connection? [y/N]: "
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log "INFO" "Operation cancelled"
            return 0
        fi

        # Remove existing section
        sed -i "/^\[$name\]/,/^$/d" "$CONFIG_FILE"
    fi

    # Add new connection
    cat >> "$CONFIG_FILE" << EOF

[$name]
remote = $remote_path
local = $MOUNT_BASE_DIR/$name
key = $DEFAULT_SSH_KEY
port = 22
options = cache=yes,compression=yes,reconnect
description = $description
EOF

    log "INFO" "✓ Connection added: $name"
    log "INFO" "Edit $CONFIG_FILE to customize the configuration"

    return 0
}

remove_connection() {
    local name=$1

    log "INFO" "Removing connection: $name"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR" "Configuration file not found: $CONFIG_FILE"
        return 1
    fi

    if ! grep -q "^\[$name\]" "$CONFIG_FILE"; then
        log "ERROR" "Connection not found: $name"
        return 1
    fi

    # Check if currently mounted
    if read_config "$name" 2>/dev/null && mountpoint -q "$LOCAL_PATH" 2>/dev/null; then
        log "WARN" "Connection is currently mounted: $LOCAL_PATH"
        echo -n "Unmount and remove connection? [y/N]: "
        read -r response
        if [[ $response =~ ^[Yy]$ ]]; then
            unmount_sshfs "$name"
        else
            log "INFO" "Operation cancelled"
            return 0
        fi
    fi

    # Remove section from config
    sed -i "/^\[$name\]/,/^$/d" "$CONFIG_FILE"

    log "INFO" "✓ Connection removed: $name"

    return 0
}

list_connections() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "INFO" "No configuration file found. Use 'add' command to create connections."
        return 0
    fi

    log "INFO" "Configured SSHFS connections:"
    echo "============================="

    printf "%-15s %-20s %-20s %s\n" "Name" "Status" "Local Path" "Remote Path"
    printf "%-15s %-20s %-20s %s\n" "----" "------" "----------" "-----------"

    # Parse configuration file
    local current_section=""
    local connections=()

    while IFS= read -r line; do
        if [[ $line =~ ^\[([^]]+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            connections+=("$current_section")
        fi
    done < "$CONFIG_FILE"

    # Display each connection
    for conn in "${connections[@]}"; do
        if read_config "$conn" 2>/dev/null; then
            local status="unmounted"
            if mountpoint -q "$LOCAL_PATH" 2>/dev/null; then
                status="mounted"
            fi

            printf "%-15s %-20s %-20s %s\n" "$conn" "$status" "$LOCAL_PATH" "$REMOTE_PATH"
        fi
    done

    return 0
}

show_status() {
    log "INFO" "SSHFS mount status:"
    echo "=================="

    # Show all SSHFS mounts
    local sshfs_mounts=($(mount | grep fuse.sshfs | awk '{print $3}'))

    if [[ ${#sshfs_mounts[@]} -eq 0 ]]; then
        echo "No SSHFS mounts found"
        return 0
    fi

    printf "%-30s %-20s %s\n" "Mount Point" "Status" "Remote"
    printf "%-30s %-20s %s\n" "-----------" "------" "------"

    for mount_point in "${sshfs_mounts[@]}"; do
        local remote=$(mount | grep "on $mount_point " | awk '{print $1}')
        local status="active"

        # Test if mount is responsive
        if ! timeout 5 ls "$mount_point" >/dev/null 2>&1; then
            status="unresponsive"
        fi

        printf "%-30s %-20s %s\n" "$mount_point" "$status" "$remote"
    done

    return 0
}

mount_all_connections() {
    log "INFO" "Mounting all configured connections..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR" "No configuration file found"
        return 1
    fi

    local connections=()
    local current_section=""

    # Get list of all connections
    while IFS= read -r line; do
        if [[ $line =~ ^\[([^]]+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            connections+=("$current_section")
        fi
    done < "$CONFIG_FILE"

    if [[ ${#connections[@]} -eq 0 ]]; then
        log "WARN" "No connections configured"
        return 0
    fi

    local success_count=0
    local error_count=0

    for conn in "${connections[@]}"; do
        if mount_sshfs "$conn" "$PROFILE" "$CUSTOM_OPTIONS" "$READONLY" "$BACKGROUND"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done

    log "INFO" "Mount all completed: $success_count successful, $error_count failed"
    return 0
}

unmount_all_connections() {
    log "INFO" "Unmounting all SSHFS connections..."

    local sshfs_mounts=($(mount | grep fuse.sshfs | awk '{print $3}'))

    if [[ ${#sshfs_mounts[@]} -eq 0 ]]; then
        log "INFO" "No SSHFS mounts found"
        return 0
    fi

    local success_count=0
    local error_count=0

    for mount_point in "${sshfs_mounts[@]}"; do
        if fusermount -u "$mount_point" 2>/dev/null; then
            log "INFO" "✓ Unmounted: $mount_point"
            ((success_count++))
        else
            log "ERROR" "✗ Failed to unmount: $mount_point"
            ((error_count++))
        fi
    done

    log "INFO" "Unmount all completed: $success_count successful, $error_count failed"
    return 0
}

cleanup_stale_mounts() {
    log "INFO" "Cleaning up stale mount points..."

    local cleaned=0

    # Find directories in mount base that aren't mounted
    if [[ -d "$MOUNT_BASE_DIR" ]]; then
        for dir in "$MOUNT_BASE_DIR"/*; do
            if [[ -d "$dir" ]] && ! mountpoint -q "$dir" 2>/dev/null; then
                # Check if directory is empty
                if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
                    rmdir "$dir"
                    log "INFO" "Removed empty directory: $dir"
                    ((cleaned++))
                else
                    log "WARN" "Directory not empty, skipping: $dir"
                fi
            fi
        done
    fi

    log "INFO" "Cleanup completed: $cleaned directories removed"
    return 0
}

edit_connection() {
    local name=$1

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR" "Configuration file not found: $CONFIG_FILE"
        return 1
    fi

    if ! grep -q "^\[$name\]" "$CONFIG_FILE"; then
        log "ERROR" "Connection not found: $name"
        return 1
    fi

    # Use preferred editor
    local editor="${EDITOR:-nano}"

    log "INFO" "Opening configuration for editing: $name"
    log "INFO" "Use your editor to modify the [$name] section"

    # Open editor at the specific section
    "$editor" "$CONFIG_FILE"

    return 0
}

# Parse command line arguments
PROFILE=""
CUSTOM_OPTIONS=""
READONLY=false
BACKGROUND=false
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --key)
            DEFAULT_SSH_KEY=$2
            shift 2
            ;;
        --port)
            DEFAULT_SSH_PORT=$2
            shift 2
            ;;
        --options)
            CUSTOM_OPTIONS=$2
            shift 2
            ;;
        --profile)
            PROFILE=$2
            shift 2
            ;;
        --local-path)
            LOCAL_PATH_OVERRIDE=$2
            shift 2
            ;;
        --config)
            CONFIG_FILE=$2
            shift 2
            ;;
        --base-dir)
            MOUNT_BASE_DIR=$2
            shift 2
            ;;
        --reconnect)
            CUSTOM_OPTIONS="${CUSTOM_OPTIONS:+$CUSTOM_OPTIONS,}reconnect"
            shift
            ;;
        --readonly)
            READONLY=true
            shift
            ;;
        --background)
            BACKGROUND=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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

COMMAND=$1
shift

# Create mount base directory
mkdir -p "$MOUNT_BASE_DIR"

# Initialize logging
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Execute command
case $COMMAND in
    mount)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Connection name required for mount command"
            exit 1
        fi
        mount_sshfs "$1" "$PROFILE" "$CUSTOM_OPTIONS" "$READONLY" "$BACKGROUND"
        ;;
    umount|unmount)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Connection name required for unmount command"
            exit 1
        fi
        unmount_sshfs "$1"
        ;;
    add)
        if [[ $# -lt 2 ]]; then
            log "ERROR" "Usage: $0 add <name> <user@host:path> [description]"
            exit 1
        fi
        add_connection "$1" "$2" "${3:-}"
        ;;
    remove)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Connection name required for remove command"
            exit 1
        fi
        remove_connection "$1"
        ;;
    list)
        list_connections
        ;;
    status)
        show_status
        ;;
    test)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Connection name required for test command"
            exit 1
        fi
        test_ssh_connectivity "$1"
        ;;
    edit)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Connection name required for edit command"
            exit 1
        fi
        edit_connection "$1"
        ;;
    mount-all)
        mount_all_connections
        ;;
    umount-all|unmount-all)
        unmount_all_connections
        ;;
    cleanup)
        cleanup_stale_mounts
        ;;
    *)
        log "ERROR" "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac