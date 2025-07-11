#!/bin/bash
# Samba User Management Script
# File: examples/samba/samba-user-management.sh

set -euo pipefail

# Configuration
LOG_FILE="/var/log/samba-user-management.log"
AVAILABLE_GROUPS=("employees" "finance" "it" "hr" "executives" "contractors" "backup-operators")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
Samba User Management Script

Usage: $0 <command> [options]

Commands:
    add <username> [groups]     Add new user to system and Samba
    remove <username>           Remove user from system and Samba
    disable <username>          Disable Samba user account
    enable <username>           Enable Samba user account
    passwd <username>           Change Samba password for user
    list                        List all Samba users
    groups                      List available groups
    addgroup <username> <group> Add user to group
    rmgroup <username> <group>  Remove user from group
    info <username>             Show user information
    bulk-add <file>            Add users from CSV file
    cleanup                     Remove orphaned accounts
    audit                       Generate user audit report

Options:
    --force                     Force operation without confirmation
    --quiet                     Suppress non-error output
    --home                      Create home directory for new users
    --shell <shell>             Set user shell (default: /bin/bash)

Examples:
    $0 add jdoe employees,it
    $0 remove olduser --force
    $0 passwd jdoe
    $0 addgroup jdoe finance
    $0 bulk-add users.csv
    $0 audit > user-report.txt

CSV Format for bulk-add:
    username,full_name,groups,email
    jdoe,John Doe,"employees,it",jdoe@company.com
EOF
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

validate_username() {
    local username=$1

    if [[ ! $username =~ ^[a-z][a-z0-9_-]{2,31}$ ]]; then
        log "ERROR" "Invalid username: $username"
        log "ERROR" "Username must start with letter, 3-32 chars, lowercase, numbers, dash, underscore only"
        return 1
    fi

    return 0
}

validate_group() {
    local group=$1

    if [[ ! " ${AVAILABLE_GROUPS[*]} " =~ " $group " ]]; then
        log "ERROR" "Invalid group: $group"
        log "ERROR" "Available groups: ${AVAILABLE_GROUPS[*]}"
        return 1
    fi

    if ! getent group "$group" >/dev/null; then
        log "ERROR" "Group does not exist in system: $group"
        return 1
    fi

    return 0
}

generate_password() {
    local length=${1:-12}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length}
}

user_exists_system() {
    local username=$1
    getent passwd "$username" >/dev/null 2>&1
}

user_exists_samba() {
    local username=$1
    pdbedit -L | grep -q "^$username:"
}

add_user() {
    local username=$1
    local groups=${2:-"employees"}
    local force=${3:-false}
    local create_home=${4:-false}
    local shell=${5:-"/bin/bash"}

    validate_username "$username" || return 1

    if user_exists_system "$username" && [[ "$force" != "true" ]]; then
        log "ERROR" "User already exists: $username"
        return 1
    fi

    log "INFO" "Adding user: $username"

    # Create system user
    local useradd_opts=("-m" "-s" "$shell")
    if [[ "$create_home" == "true" ]]; then
        useradd_opts+=("-d" "/home/$username")
    fi

    if ! user_exists_system "$username"; then
        useradd "${useradd_opts[@]}" "$username"
        log "INFO" "Created system user: $username"
    fi

    # Set initial password
    local temp_password=$(generate_password)
    echo "$username:$temp_password" | chpasswd
    log "INFO" "Set temporary system password for: $username"

    # Add to groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)  # Trim whitespace
        if validate_group "$group"; then
            usermod -a -G "$group" "$username"
            log "INFO" "Added $username to group: $group"
        fi
    done

    # Add to Samba
    if ! user_exists_samba "$username"; then
        echo -e "$temp_password\n$temp_password" | smbpasswd -a -s "$username"
        log "INFO" "Added Samba user: $username"
    fi

    # Create user info file
    local user_info_file="/home/$username/.user-info"
    cat > "$user_info_file" << EOF
User Account Information
========================
Username: $username
Created: $(date)
Groups: $groups
Temporary Password: $temp_password

IMPORTANT: Please change your password immediately using:
- System password: passwd
- Samba password: smbpasswd

Contact IT support for assistance: it-support@company.com
EOF

    chown "$username:$username" "$user_info_file" 2>/dev/null || true
    chmod 600 "$user_info_file"

    log "INFO" "User creation completed: $username"
    log "INFO" "Temporary password: $temp_password"
    log "WARN" "User must change password on first login"

    return 0
}

remove_user() {
    local username=$1
    local force=${2:-false}

    validate_username "$username" || return 1

    if ! user_exists_system "$username" && ! user_exists_samba "$username"; then
        log "ERROR" "User does not exist: $username"
        return 1
    fi

    if [[ "$force" != "true" ]]; then
        echo -n "Are you sure you want to remove user '$username'? [y/N]: "
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log "INFO" "User removal cancelled"
            return 0
        fi
    fi

    log "INFO" "Removing user: $username"

    # Remove from Samba
    if user_exists_samba "$username"; then
        smbpasswd -x "$username" 2>/dev/null || true
        log "INFO" "Removed Samba user: $username"
    fi

    # Remove system user
    if user_exists_system "$username"; then
        userdel -r "$username" 2>/dev/null || userdel "$username"
        log "INFO" "Removed system user: $username"
    fi

    # Clean up any remaining files
    find /srv/samba -user "$username" -exec chown nobody:nogroup {} \; 2>/dev/null || true

    log "INFO" "User removal completed: $username"
    return 0
}

disable_user() {
    local username=$1

    validate_username "$username" || return 1

    if ! user_exists_samba "$username"; then
        log "ERROR" "Samba user does not exist: $username"
        return 1
    fi

    smbpasswd -d "$username"
    usermod -L "$username" 2>/dev/null || true

    log "INFO" "Disabled user: $username"
    return 0
}

enable_user() {
    local username=$1

    validate_username "$username" || return 1

    if ! user_exists_samba "$username"; then
        log "ERROR" "Samba user does not exist: $username"
        return 1
    fi

    smbpasswd -e "$username"
    usermod -U "$username" 2>/dev/null || true

    log "INFO" "Enabled user: $username"
    return 0
}

change_password() {
    local username=$1

    validate_username "$username" || return 1

    if ! user_exists_samba "$username"; then
        log "ERROR" "Samba user does not exist: $username"
        return 1
    fi

    log "INFO" "Changing Samba password for: $username"
    smbpasswd "$username"

    log "INFO" "Password changed for: $username"
    return 0
}

list_users() {
    log "INFO" "Samba Users:"
    echo "============"

    if ! pdbedit -L >/dev/null 2>&1; then
        log "WARN" "No Samba users found or pdbedit failed"
        return 1
    fi

    printf "%-20s %-30s %-15s %s\n" "Username" "Full Name" "Status" "Groups"
    printf "%-20s %-30s %-15s %s\n" "--------" "---------" "------" "------"

    while IFS=: read -r username uid full_name; do
        # Get user status
        local status="enabled"
        if smbpasswd -d "$username" 2>/dev/null | grep -q "disabled"; then
            status="disabled"
        fi

        # Get user groups
        local user_groups=""
        if user_exists_system "$username"; then
            user_groups=$(groups "$username" 2>/dev/null | cut -d: -f2 | tr ' ' ',' | sed 's/^,//')
        fi

        printf "%-20s %-30s %-15s %s\n" "$username" "$full_name" "$status" "$user_groups"
    done < <(pdbedit -L | sort)

    return 0
}

list_groups() {
    log "INFO" "Available Groups:"
    echo "================="

    for group in "${AVAILABLE_GROUPS[@]}"; do
        local member_count=0
        if getent group "$group" >/dev/null; then
            member_count=$(getent group "$group" | cut -d: -f4 | tr ',' '\n' | wc -l)
            if [[ -z "$(getent group "$group" | cut -d: -f4)" ]]; then
                member_count=0
            fi
        fi
        printf "%-20s %d members\n" "$group" "$member_count"
    done

    return 0
}

add_user_to_group() {
    local username=$1
    local group=$2

    validate_username "$username" || return 1
    validate_group "$group" || return 1

    if ! user_exists_system "$username"; then
        log "ERROR" "System user does not exist: $username"
        return 1
    fi

    usermod -a -G "$group" "$username"
    log "INFO" "Added $username to group: $group"

    return 0
}

remove_user_from_group() {
    local username=$1
    local group=$2

    validate_username "$username" || return 1
    validate_group "$group" || return 1

    if ! user_exists_system "$username"; then
        log "ERROR" "System user does not exist: $username"
        return 1
    fi

    gpasswd -d "$username" "$group"
    log "INFO" "Removed $username from group: $group"

    return 0
}

show_user_info() {
    local username=$1

    validate_username "$username" || return 1

    echo "User Information: $username"
    echo "=========================="

    # System user info
    if user_exists_system "$username"; then
        echo "System User: YES"
        getent passwd "$username" | while IFS=: read -r user x uid gid gecos home shell; do
            echo "  UID: $uid"
            echo "  GID: $gid"
            echo "  Full Name: $gecos"
            echo "  Home: $home"
            echo "  Shell: $shell"
        done

        echo "  Groups: $(groups "$username" 2>/dev/null | cut -d: -f2 | tr ' ' ',')"
        echo "  Last Login: $(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{print $4, $5, $6, $7}')"
    else
        echo "System User: NO"
    fi

    echo

    # Samba user info
    if user_exists_samba "$username"; then
        echo "Samba User: YES"
        pdbedit -L -v "$username" 2>/dev/null | grep -E "(Account Flags|Logon time|Password)" || true
    else
        echo "Samba User: NO"
    fi

    echo

    # File ownership
    echo "File Ownership:"
    local file_count=$(find /srv/samba -user "$username" 2>/dev/null | wc -l)
    echo "  Files owned in /srv/samba: $file_count"

    return 0
}

bulk_add_users() {
    local csv_file=$1

    if [[ ! -f "$csv_file" ]]; then
        log "ERROR" "CSV file not found: $csv_file"
        return 1
    fi

    log "INFO" "Processing bulk user addition from: $csv_file"

    local line_num=0
    local success_count=0
    local error_count=0

    while IFS=, read -r username full_name groups email; do
        ((line_num++))

        # Skip header line
        if [[ $line_num -eq 1 ]]; then
            continue
        fi

        # Clean up fields
        username=$(echo "$username" | xargs | tr -d '"')
        full_name=$(echo "$full_name" | xargs | tr -d '"')
        groups=$(echo "$groups" | xargs | tr -d '"')
        email=$(echo "$email" | xargs | tr -d '"')

        if [[ -z "$username" ]]; then
            log "WARN" "Line $line_num: Empty username, skipping"
            ((error_count++))
            continue
        fi

        log "INFO" "Processing user: $username"

        if add_user "$username" "$groups" "false" "true"; then
            # Set full name if provided
            if [[ -n "$full_name" ]]; then
                chfn -f "$full_name" "$username" 2>/dev/null || true
            fi

            ((success_count++))
            log "INFO" "Successfully added: $username"
        else
            ((error_count++))
            log "ERROR" "Failed to add: $username"
        fi
    done < "$csv_file"

    log "INFO" "Bulk addition completed: $success_count successful, $error_count errors"
    return 0
}

cleanup_orphaned_accounts() {
    log "INFO" "Cleaning up orphaned accounts..."

    local cleanup_count=0

    # Find Samba users without system accounts
    while IFS=: read -r username uid; do
        if ! user_exists_system "$username"; then
            log "WARN" "Found orphaned Samba user: $username"
            echo -n "Remove orphaned Samba user '$username'? [y/N]: "
            read -r response
            if [[ $response =~ ^[Yy]$ ]]; then
                smbpasswd -x "$username"
                ((cleanup_count++))
                log "INFO" "Removed orphaned Samba user: $username"
            fi
        fi
    done < <(pdbedit -L | cut -d: -f1,2)

    log "INFO" "Cleanup completed: $cleanup_count accounts removed"
    return 0
}

generate_audit_report() {
    local report_file="/tmp/samba-user-audit-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$report_file" << EOF
Samba User Audit Report
Generated: $(date)
=======================

System Information:
- Hostname: $(hostname)
- Samba Version: $(smbd --version 2>/dev/null || echo "Unknown")
- Total System Users: $(getent passwd | wc -l)
- Total Samba Users: $(pdbedit -L | wc -l)

User Summary:
=============
EOF

    # Count users by group
    for group in "${AVAILABLE_GROUPS[@]}"; do
        local count=0
        if getent group "$group" >/dev/null; then
            count=$(getent group "$group" | cut -d: -f4 | tr ',' '\n' | wc -l)
            if [[ -z "$(getent group "$group" | cut -d: -f4)" ]]; then
                count=0
            fi
        fi
        echo "- $group: $count users" >> "$report_file"
    done

    cat >> "$report_file" << EOF

Detailed User List:
==================
EOF

    printf "%-20s %-15s %-30s %s\n" "Username" "Status" "Groups" "Last Login" >> "$report_file"
    printf "%-20s %-15s %-30s %s\n" "--------" "------" "------" "----------" >> "$report_file"

    while IFS=: read -r username uid full_name; do
        local status="enabled"
        if pdbedit -L "$username" 2>/dev/null | grep -q "Account Flags.*D"; then
            status="disabled"
        fi

        local user_groups=""
        if user_exists_system "$username"; then
            user_groups=$(groups "$username" 2>/dev/null | cut -d: -f2 | tr ' ' ',' | sed 's/^,//' | cut -c1-30)
        fi

        local last_login="Never"
        if user_exists_system "$username"; then
            last_login=$(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{print $4, $5}' | head -c20)
            [[ "$last_login" == "**Never" ]] && last_login="Never"
        fi

        printf "%-20s %-15s %-30s %s\n" "$username" "$status" "$user_groups" "$last_login" >> "$report_file"
    done < <(pdbedit -L | sort)

    cat >> "$report_file" << EOF

Security Notes:
===============
- All users should change default passwords immediately
- Disabled accounts should be reviewed regularly
- Users with no recent login activity should be investigated
- Group memberships should be audited quarterly

Recommendations:
================
- Implement password expiration policies
- Enable account lockout after failed attempts
- Monitor file access logs regularly
- Review and update group memberships

Report generated by: $0
For questions, contact: it-support@company.com
EOF

    log "INFO" "Audit report generated: $report_file"
    echo "Report saved to: $report_file"

    return 0
}

# Parse command line arguments
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

COMMAND=$1
shift

# Global options
FORCE=false
QUIET=false
CREATE_HOME=false
SHELL="/bin/bash"

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --home)
            CREATE_HOME=true
            shift
            ;;
        --shell)
            SHELL=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            log "ERROR" "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check root permissions
check_root

# Execute command
case $COMMAND in
    add)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Username required for add command"
            exit 1
        fi
        add_user "$1" "${2:-employees}" "$FORCE" "$CREATE_HOME" "$SHELL"
        ;;
    remove)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Username required for remove command"
            exit 1
        fi
        remove_user "$1" "$FORCE"
        ;;
    disable)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Username required for disable command"
            exit 1
        fi
        disable_user "$1"
        ;;
    enable)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Username required for enable command"
            exit 1
        fi
        enable_user "$1"
        ;;
    passwd)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Username required for passwd command"
            exit 1
        fi
        change_password "$1"
        ;;
    list)
        list_users
        ;;
    groups)
        list_groups
        ;;
    addgroup)
        if [[ $# -lt 2 ]]; then
            log "ERROR" "Username and group required for addgroup command"
            exit 1
        fi
        add_user_to_group "$1" "$2"
        ;;
    rmgroup)
        if [[ $# -lt 2 ]]; then
            log "ERROR" "Username and group required for rmgroup command"
            exit 1
        fi
        remove_user_from_group "$1" "$2"
        ;;
    info)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "Username required for info command"
            exit 1
        fi
        show_user_info "$1"
        ;;
    bulk-add)
        if [[ $# -lt 1 ]]; then
            log "ERROR" "CSV file required for bulk-add command"
            exit 1
        fi
        bulk_add_users "$1"
        ;;
    cleanup)
        cleanup_orphaned_accounts
        ;;
    audit)
        generate_audit_report
        ;;
    *)
        log "ERROR" "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac