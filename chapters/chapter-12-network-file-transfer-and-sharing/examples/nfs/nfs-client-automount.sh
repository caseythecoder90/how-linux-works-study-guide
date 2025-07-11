#!/bin/bash
# NFS Client Automount Configuration Script
# File: examples/nfs/nfs-client-automount.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/nfs-automount-setup.log"
AUTOFS_CONFIG="/etc/auto.master"
AUTOFS_NFS_CONFIG="/etc/auto.nfs"
MOUNT_BASE="/mnt/nfs"

# Default NFS server configuration
DEFAULT_NFS_SERVER="nfs-server.company.com"
DEFAULT_NFS_OPTIONS="vers=4,rsize=32768,wsize=32768,hard,intr,timeo=60,retrans=3"

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
NFS Client Automount Configuration Script

Usage: $0 [OPTIONS] <command>

Commands:
    setup                   Configure automount for NFS shares
    add <share> <path>      Add specific NFS share to automount
    remove <share>          Remove NFS share from automount
    list                    List configured automounts
    test                    Test automount configuration
    cleanup                 Remove all automount configuration
    status                  Show automount service status

Options:
    --server <hostname>     NFS server hostname (default: $DEFAULT_NFS_SERVER)
    --options <opts>        NFS mount options (default: $DEFAULT_NFS_OPTIONS)
    --base <path>           Base mount directory (default: $MOUNT_BASE)
    --force                 Force configuration without prompts
    --dry-run               Show what would be done without making changes

Examples:
    $0 setup
    $0 add shared /srv/nfs/shared
    $0 --server 192.168.1.100 add finance /srv/nfs/finance
    $0 test
    $0 remove shared
    $0 cleanup --force

NFS Shares Configuration:
    The script can configure automount for common NFS shares:
    - shared        Company shared files
    - finance       Finance department files
    - it            IT department files
    - hr            HR department files
    - public        Public read-only files
    - development   Development team files
    - archives      Archive storage
    - backups       Backup storage
EOF
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    log "INFO" "Checking dependencies..."

    local deps=("autofs" "nfs-common")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "INFO" "Installing missing dependencies: ${missing[*]}"
        apt update && apt install -y "${missing[@]}"
    fi

    log "INFO" "All dependencies satisfied"
}

test_nfs_connectivity() {
    local server=$1
    local timeout=${2:-10}

    log "INFO" "Testing connectivity to NFS server: $server"

    # Test basic connectivity
    if ! timeout "$timeout" ping -c 1 "$server" >/dev/null 2>&1; then
        log "ERROR" "Cannot ping NFS server: $server"
        return 1
    fi

    # Test NFS service availability
    if ! timeout "$timeout" showmount -e "$server" >/dev/null 2>&1; then
        log "ERROR" "Cannot access NFS exports on server: $server"
        return 1
    fi

    log "INFO" "✓ NFS server is accessible: $server"
    return 0
}

backup_existing_config() {
    log "INFO" "Backing up existing autofs configuration..."

    local backup_dir="/etc/autofs-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    if [[ -f "$AUTOFS_CONFIG" ]]; then
        cp "$AUTOFS_CONFIG" "$backup_dir/"
        log "INFO" "Backed up: $AUTOFS_CONFIG"
    fi

    if [[ -f "$AUTOFS_NFS_CONFIG" ]]; then
        cp "$AUTOFS_NFS_CONFIG" "$backup_dir/"
        log "INFO" "Backed up: $AUTOFS_NFS_CONFIG"
    fi

    # Backup any existing auto.* files
    for file in /etc/auto.*; do
        if [[ -f "$file" ]]; then
            cp "$file" "$backup_dir/"
        fi
    done

    log "INFO" "Configuration backed up to: $backup_dir"
}

create_mount_base() {
    local base_dir=$1

    log "INFO" "Creating base mount directory: $base_dir"

    mkdir -p "$base_dir"
    chmod 755 "$base_dir"
    chown root:root "$base_dir"
}

configure_autofs_master() {
    local base_dir=$1
    local nfs_config=$2

    log "INFO" "Configuring autofs master file: $AUTOFS_CONFIG"

    # Backup original if it exists
    if [[ -f "$AUTOFS_CONFIG" ]]; then
        cp "$AUTOFS_CONFIG" "${AUTOFS_CONFIG}.backup"
    fi

    # Create autofs master configuration
    cat > "$AUTOFS_CONFIG" << EOF
# Autofs master configuration
# Generated by: $0
# Date: $(date)

# Include additional configurations
+auto.master

# NFS automount configuration
$base_dir $nfs_config --timeout=60 --browse

# Home directories (uncomment if needed)
# /home/remote /etc/auto.home --timeout=60

# Network shares (uncomment if needed)
# /mnt/cifs /etc/auto.cifs --timeout=60

# Removable media (uncomment if needed)
# /misc /etc/auto.misc --timeout=5 --browse
EOF

    log "INFO" "✓ Autofs master configuration created"
}

configure_nfs_shares() {
    local server=$1
    local options=$2
    local config_file=$3

    log "INFO" "Configuring NFS shares: $config_file"

    # Create NFS automount configuration
    cat > "$config_file" << EOF
# NFS Automount Configuration
# Generated by: $0
# Date: $(date)
# Server: $server

# Common company shares
shared          -$options $server:/srv/nfs/shared
public          -$options $server:/srv/nfs/public
archives        -$options $server:/srv/nfs/archives

# Department shares
finance         -$options $server:/srv/nfs/finance
it              -$options $server:/srv/nfs/it
hr              -$options $server:/srv/nfs/hr
marketing       -$options $server:/srv/nfs/marketing
development     -$options $server:/srv/nfs/development

# Project shares
project-alpha   -$options $server:/srv/nfs/projects/alpha
project-beta    -$options $server:/srv/nfs/projects/beta

# Application shares
web             -$options $server:/srv/nfs/web
database        -$options $server:/srv/nfs/database
backups         -$options $server:/srv/nfs/backups

# High-performance shares
rendering       -$options $server:/srv/nfs/rendering
cad             -$options $server:/srv/nfs/cad

# Software repository
software        -$options $server:/srv/nfs/software
EOF

    log "INFO" "✓ NFS shares configuration created"
}

add_custom_share() {
    local share_name=$1
    local remote_path=$2
    local server=$3
    local options=$4
    local config_file=$5

    log "INFO" "Adding custom share: $share_name -> $remote_path"

    # Check if share already exists
    if grep -q "^$share_name[[:space:]]" "$config_file" 2>/dev/null; then
        log "WARN" "Share already exists, updating: $share_name"
        sed -i "/^$share_name[[:space:]]/d" "$config_file"
    fi

    # Add the new share
    echo "$share_name          -$options $server:$remote_path" >> "$config_file"

    log "INFO" "✓ Added share: $share_name"
}

remove_share() {
    local share_name=$1
    local config_file=$2

    log "INFO" "Removing share: $share_name"

    if [[ -f "$config_file" ]]; then
        sed -i "/^$share_name[[:space:]]/d" "$config_file"
        log "INFO" "✓ Removed share: $share_name"
    else
        log "WARN" "Configuration file not found: $config_file"
    fi
}

start_autofs_service() {
    log "INFO" "Starting and enabling autofs service..."

    systemctl daemon-reload
    systemctl enable autofs
    systemctl restart autofs

    # Wait for service to start
    sleep 3

    if systemctl is-active --quiet autofs; then
        log "INFO" "✓ Autofs service is running"
    else
        log "ERROR" "✗ Failed to start autofs service"
        log "INFO" "Check logs with: journalctl -u autofs"
        return 1
    fi
}

test_automount() {
    local base_dir=$1
    local test_shares=("public" "shared")

    log "INFO" "Testing automount functionality..."

    for share in "${test_shares[@]}"; do
        local mount_point="$base_dir/$share"

        log "INFO" "Testing share: $share"

        # Trigger automount by accessing the directory
        if timeout 10 ls "$mount_point" >/dev/null 2>&1; then
            log "INFO" "✓ Successfully mounted: $share"

            # Check if it's actually an NFS mount
            if mount | grep -q "$mount_point.*nfs"; then
                log "INFO" "✓ Confirmed NFS mount: $share"
            else
                log "WARN" "Mount exists but may not be NFS: $share"
            fi
        else
            log "WARN" "✗ Failed to mount or access: $share"
        fi

        # Let autofs unmount after timeout
        sleep 2
    done
}

list_configured_shares() {
    local config_file=$1

    if [[ ! -f "$config_file" ]]; then
        log "WARN" "No NFS automount configuration found: $config_file"
        return 1
    fi

    log "INFO" "Configured NFS shares:"
    echo "======================"

    printf "%-20s %-40s %s\n" "Share Name" "Remote Path" "Options"
    printf "%-20s %-40s %s\n" "----------" "-----------" "-------"

    while read -r line; do
        # Skip comments and empty lines
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z "${line// }" ]] && continue

        # Parse the line
        if [[ $line =~ ^([^[:space:]]+)[[:space:]]+-(.*)[[:space:]]+([^:]+):(.+)$ ]]; then
            local share_name="${BASH_REMATCH[1]}"
            local options="${BASH_REMATCH[2]}"
            local server="${BASH_REMATCH[3]}"
            local remote_path="${BASH_REMATCH[4]}"

            printf "%-20s %-40s %s\n" "$share_name" "$server:$remote_path" "$options"
        fi
    done < "$config_file"

    echo
    log "INFO" "Mount point base: $(dirname "$config_file" | sed 's/etc/mnt/')"
}

show_status() {
    log "INFO" "Autofs service status:"
    systemctl status autofs --no-pager

    echo
    log "INFO" "Active automounts:"
    mount | grep autofs || log "INFO" "No active automounts found"

    echo
    log "INFO" "Autofs maps:"
    automount -f -v 2>/dev/null || log "WARN" "Could not get automount debug info"
}

cleanup_configuration() {
    local force=${1:-false}

    if [[ "$force" != "true" ]]; then
        echo -n "Are you sure you want to remove all autofs configuration? [y/N]: "
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log "INFO" "Cleanup cancelled"
            return 0
        fi
    fi

    log "INFO" "Cleaning up autofs configuration..."

    # Stop autofs service
    systemctl stop autofs 2>/dev/null || true
    systemctl disable autofs 2>/dev/null || true

    # Remove configuration files
    [[ -f "$AUTOFS_CONFIG" ]] && rm -f "$AUTOFS_CONFIG"
    [[ -f "$AUTOFS_NFS_CONFIG" ]] && rm -f "$AUTOFS_NFS_CONFIG"

    # Remove mount directories (empty ones only)
    if [[ -d "$MOUNT_BASE" ]]; then
        find "$MOUNT_BASE" -type d -empty -delete 2>/dev/null || true
    fi

    log "INFO" "✓ Cleanup completed"
}

# Parse command line arguments
NFS_SERVER="$DEFAULT_NFS_SERVER"
NFS_OPTIONS="$DEFAULT_NFS_OPTIONS"
BASE_DIR="$MOUNT_BASE"
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --server)
            NFS_SERVER=$2
            shift 2
            ;;
        --options)
            NFS_OPTIONS=$2
            shift 2
            ;;
        --base)
            BASE_DIR=$2
            shift 2
            ;;
        --force)
            FORCE=true
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

# Update paths based on base directory
AUTOFS_NFS_CONFIG="/etc/auto.nfs"

# Dry run mode
if [[ "$DRY_RUN" == "true" ]]; then
    log "INFO" "DRY RUN MODE - No changes will be made"
    log "INFO" "Command: $COMMAND"
    log "INFO" "NFS Server: $NFS_SERVER"
    log "INFO" "Mount Options: $NFS_OPTIONS"
    log "INFO" "Base Directory: $BASE_DIR"
    exit 0
fi

# Check root permissions for most commands
case $COMMAND in
    list|status|test)
        # These commands don't require root
        ;;
    *)
        check_root
        ;;
esac

# Execute command
case $COMMAND in
    setup)
        log "INFO" "Setting up NFS automount configuration..."
        check_dependencies
        test_nfs_connectivity "$NFS_SERVER"
        backup_existing_config
        create_mount_base "$BASE_DIR"
        configure_autofs_master "$BASE_DIR" "$AUTOFS_NFS_CONFIG"
        configure_nfs_shares "$NFS_SERVER" "$NFS_OPTIONS" "$AUTOFS_NFS_CONFIG"
        start_autofs_service
        test_automount "$BASE_DIR"
        log "INFO" "✓ NFS automount setup completed successfully"
        ;;
    add)
        if [[ $# -lt 2 ]]; then
            log "ERROR" "Usage: $0 add <share_name> <remote_path>"
            exit 1
        fi
        add_custom_share "$1" "$2" "$NFS_SERVER" "$NFS_OPTIONS" "$AUTOFS_NFS_CONFIG"
        systemctl reload autofs
        ;;
    remove)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Usage: $0 remove <share_name>"
            exit 1
        fi
        remove_share "$1" "$AUTOFS_NFS_CONFIG"
        systemctl reload autofs
        ;;
    list)
        list_configured_shares "$AUTOFS_NFS_CONFIG"
        ;;
    test)
        test_automount "$BASE_DIR"
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup_configuration "$FORCE"
        ;;
    *)
        log "ERROR" "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac