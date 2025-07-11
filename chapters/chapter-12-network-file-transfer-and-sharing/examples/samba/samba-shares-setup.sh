#!/bin/bash
# Automated Samba shares setup script
# File: examples/samba/samba-shares-setup.sh

set -euo pipefail

# Configuration
SAMBA_BASE="/srv/samba"
SHARES=("shared" "finance" "it" "hr" "public" "backup" "temp" "archive")
GROUPS=("employees" "finance" "it" "hr" "executives" "contractors" "backup-operators")
LOG_FILE="/var/log/samba-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    esac
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    log "INFO" "Checking dependencies..."

    local deps=("samba" "samba-common-bin")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}"
        log "INFO" "Install with: apt update && apt install ${missing[*]}"
        exit 1
    fi

    log "INFO" "All dependencies satisfied"
}

backup_config() {
    local config_file="/etc/samba/smb.conf"

    if [[ -f "$config_file" ]]; then
        local backup_file="$config_file.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$config_file" "$backup_file"
        log "INFO" "Backed up existing configuration to $backup_file"
    fi
}

create_system_groups() {
    log "INFO" "Creating system groups..."

    for group in "${GROUPS[@]}"; do
        if ! getent group "$group" >/dev/null; then
            groupadd "$group"
            log "INFO" "Created group: $group"
        else
            log "INFO" "Group already exists: $group"
        fi
    done
}

create_samba_user() {
    local username="samba-service"

    if ! getent passwd "$username" >/dev/null; then
        useradd -r -s /bin/false -d /nonexistent -c "Samba Service User" "$username"
        log "INFO" "Created service user: $username"
    else
        log "INFO" "Service user already exists: $username"
    fi
}

create_directory_structure() {
    log "INFO" "Creating Samba directory structure..."

    # Create base directory
    mkdir -p "$SAMBA_BASE"
    chown root:root "$SAMBA_BASE"
    chmod 755 "$SAMBA_BASE"

    # Create share directories with appropriate permissions
    for share in "${SHARES[@]}"; do
        local share_path="$SAMBA_BASE/$share"
        mkdir -p "$share_path"

        case "$share" in
            "shared")
                chown root:employees "$share_path"
                chmod 2775 "$share_path"  # Set group sticky bit
                log "INFO" "Created shared directory: $share_path (employees:2775)"
                ;;
            "finance")
                chown root:finance "$share_path"
                chmod 2770 "$share_path"
                log "INFO" "Created finance directory: $share_path (finance:2770)"
                ;;
            "it")
                chown root:it "$share_path"
                chmod 2775 "$share_path"
                log "INFO" "Created IT directory: $share_path (it:2775)"
                ;;
            "hr")
                chown root:hr "$share_path"
                chmod 2770 "$share_path"
                log "INFO" "Created HR directory: $share_path (hr:2770)"
                ;;
            "public")
                chown root:root "$share_path"
                chmod 755 "$share_path"
                log "INFO" "Created public directory: $share_path (root:755)"
                ;;
            "backup")
                chown root:backup-operators "$share_path"
                chmod 2750 "$share_path"
                log "INFO" "Created backup directory: $share_path (backup-operators:2750)"
                ;;
            "temp")
                chown root:employees "$share_path"
                chmod 1777 "$share_path"  # Sticky bit for temp directory
                log "INFO" "Created temp directory: $share_path (employees:1777)"
                ;;
            "archive")
                chown root:employees "$share_path"
                chmod 755 "$share_path"
                log "INFO" "Created archive directory: $share_path (employees:755)"
                ;;
        esac

        # Create subdirectories for organization
        case "$share" in
            "shared")
                mkdir -p "$share_path"/{documents,projects,resources}
                chown -R root:employees "$share_path"/{documents,projects,resources}
                chmod -R 2775 "$share_path"/{documents,projects,resources}
                ;;
            "finance")
                mkdir -p "$share_path"/{reports,budgets,invoices}
                chown -R root:finance "$share_path"/{reports,budgets,invoices}
                chmod -R 2770 "$share_path"/{reports,budgets,invoices}
                ;;
            "it")
                mkdir -p "$share_path"/{scripts,documentation,software}
                chown -R root:it "$share_path"/{scripts,documentation,software}
                chmod -R 2775 "$share_path"/{scripts,documentation,software}
                ;;
        esac
    done
}

setup_selinux() {
    if command -v setsebool >/dev/null 2>&1; then
        log "INFO" "Configuring SELinux for Samba..."

        # Set SELinux booleans
        setsebool -P samba_enable_home_dirs on
        setsebool -P samba_export_all_rw on
        setsebool -P samba_share_fusefs on

        # Set file contexts
        semanage fcontext -a -t samba_share_t "$SAMBA_BASE(/.*)?" 2>/dev/null || true
        restorecon -R "$SAMBA_BASE"

        log "INFO" "SELinux configuration completed"
    else
        log "INFO" "SELinux not detected, skipping SELinux configuration"
    fi
}

configure_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        log "INFO" "Configuring UFW firewall for Samba..."
        ufw allow samba
        log "INFO" "UFW firewall configured"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        log "INFO" "Configuring firewalld for Samba..."
        firewall-cmd --permanent --add-service=samba
        firewall-cmd --reload
        log "INFO" "Firewalld configured"
    else
        log "WARN" "No supported firewall detected. Please configure manually:"
        log "WARN" "  - Allow TCP ports 445 (SMB)"
        log "WARN" "  - Allow UDP ports 137-138 (NetBIOS) if using NetBIOS"
    fi
}

create_log_directories() {
    log "INFO" "Creating Samba log directories..."

    mkdir -p /var/log/samba
    chown root:root /var/log/samba
    chmod 755 /var/log/samba

    # Set up log rotation
    cat > /etc/logrotate.d/samba << 'EOF'
/var/log/samba/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root root
    postrotate
        /bin/kill -HUP `cat /var/run/smbd.pid 2>/dev/null` 2>/dev/null || true
        /bin/kill -HUP `cat /var/run/nmbd.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
EOF

    log "INFO" "Log rotation configured"
}

enable_services() {
    log "INFO" "Enabling and starting Samba services..."

    systemctl enable smbd nmbd
    systemctl start smbd nmbd

    # Wait for services to start
    sleep 3

    if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
        log "INFO" "Samba services started successfully"
    else
        log "ERROR" "Failed to start Samba services"
        log "INFO" "Check logs with: journalctl -u smbd -u nmbd"
        exit 1
    fi
}

create_test_files() {
    log "INFO" "Creating test files and documentation..."

    # Create README files for each share
    for share in "${SHARES[@]}"; do
        local readme_file="$SAMBA_BASE/$share/README.txt"
        cat > "$readme_file" << EOF
Welcome to the $share Samba share!

This directory is part of the company file sharing system.

Share Information:
- Name: $share
- Purpose: $(get_share_description "$share")
- Created: $(date)

Guidelines:
- Please organize your files in appropriate subdirectories
- Follow the company naming conventions
- Report any issues to IT support

For support: it-support@company.com
EOF

        case "$share" in
            "shared"|"public")
                chown root:employees "$readme_file"
                chmod 644 "$readme_file"
                ;;
            "finance")
                chown root:finance "$readme_file"
                chmod 640 "$readme_file"
                ;;
            "it")
                chown root:it "$readme_file"
                chmod 644 "$readme_file"
                ;;
            *)
                chown root:root "$readme_file"
                chmod 644 "$readme_file"
                ;;
        esac
    done
}

get_share_description() {
    local share=$1

    case "$share" in
        "shared") echo "General company files and collaboration" ;;
        "finance") echo "Financial documents and reports" ;;
        "it") echo "IT department files and resources" ;;
        "hr") echo "Human resources documents" ;;
        "public") echo "Public read-only files" ;;
        "backup") echo "Backup storage area" ;;
        "temp") echo "Temporary file transfers" ;;
        "archive") echo "Long-term document storage" ;;
        *) echo "Company file share" ;;
    esac
}

test_configuration() {
    log "INFO" "Testing Samba configuration..."

    if testparm -s >/dev/null 2>&1; then
        log "INFO" "✓ Samba configuration is valid"
    else
        log "ERROR" "✗ Samba configuration has errors"
        log "INFO" "Run 'testparm' to see detailed error information"
        return 1
    fi

    # Test share accessibility
    for share in "${SHARES[@]}"; do
        if [[ -d "$SAMBA_BASE/$share" ]] && [[ -r "$SAMBA_BASE/$share" ]]; then
            log "INFO" "✓ Share accessible: $share"
        else
            log "WARN" "✗ Share not accessible: $share"
        fi
    done
}

generate_summary_report() {
    local report_file="/tmp/samba-setup-report.txt"

    cat > "$report_file" << EOF
Samba Share Setup Report
Generated: $(date)
========================================

Directories Created:
EOF

    for share in "${SHARES[@]}"; do
        echo "  - $SAMBA_BASE/$share" >> "$report_file"
    done

    cat >> "$report_file" << EOF

Groups Created:
EOF

    for group in "${GROUPS[@]}"; do
        echo "  - $group" >> "$report_file"
    done

    cat >> "$report_file" << EOF

Next Steps:
1. Review and customize /etc/samba/smb.conf
2. Add users to appropriate groups:
   usermod -a -G groupname username
3. Create Samba users:
   smbpasswd -a username
4. Test share access:
   smbclient -L localhost -U username
5. Configure client connections

Useful Commands:
- Test configuration: testparm
- View status: smbstatus
- Restart services: systemctl restart smbd nmbd
- View logs: journalctl -u smbd -u nmbd

For detailed logs, check: $LOG_FILE
EOF

    log "INFO" "Setup report generated: $report_file"
    cat "$report_file"
}

main() {
    log "INFO" "Starting Samba shares setup..."

    check_root
    check_dependencies
    backup_config
    create_system_groups
    create_samba_user
    create_directory_structure
    create_log_directories
    setup_selinux
    configure_firewall
    enable_services
    create_test_files
    test_configuration
    generate_summary_report

    log "INFO" "========================================="
    log "INFO" "Samba shares setup completed successfully!"
    log "INFO" "========================================="
    log "INFO" "Next steps:"
    log "INFO" "1. Customize /etc/samba/smb.conf for your needs"
    log "INFO" "2. Add users to groups and create Samba passwords"
    log "INFO" "3. Test connectivity from client machines"
    log "INFO" "For detailed setup log, see: $LOG_FILE"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        cat << EOF
Usage: $0 [OPTIONS]

Options:
    --help, -h    Show this help message
    --dry-run     Show what would be done without making changes
    --force       Force setup even if directories exist

This script sets up a complete Samba file sharing environment with:
- System groups for access control
- Directory structure with proper permissions
- SELinux configuration (if applicable)
- Firewall configuration
- Service enablement
- Test files and documentation

Run as root: sudo $0
EOF
        exit 0
        ;;
    --dry-run)
        log "INFO" "DRY RUN MODE - No changes will be made"
        log "INFO" "Would create directories: ${SHARES[*]}"
        log "INFO" "Would create groups: ${GROUPS[*]}"
        exit 0
        ;;
    --force)
        log "WARN" "Force mode enabled - existing configurations may be overwritten"
        ;;
esac

# Run main function
main "$@"