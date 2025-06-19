#!/bin/bash
# Chapter 7: System Configuration - Practical Examples

echo "=== CHAPTER 7: SYSTEM CONFIGURATION EXAMPLES ==="
echo

# ====================================
# LOGGING EXAMPLES
# ====================================

echo "=== LOGGING EXAMPLES ==="
echo

echo "1. Basic journalctl usage:"
echo "journalctl                    # View all logs"
echo "journalctl -r                # Reverse order"
echo "journalctl -f                # Follow logs"
echo

echo "2. Time-based filtering:"
echo "journalctl -S -2h            # Last 2 hours"
echo "journalctl -S '2024-01-15 09:00'"
echo "journalctl -U '2024-01-15 17:00'"
echo

echo "3. Service-specific logs:"
echo "journalctl -u sshd.service"
echo "journalctl -u nginx"
echo "journalctl -u cron --since yesterday"
echo

echo "4. Boot-related logs:"
echo "journalctl -b                # Current boot"
echo "journalctl -b -1             # Previous boot"
echo "journalctl --list-boots      # All boot sessions"
echo

echo "5. Priority filtering:"
echo "journalctl -p err            # Error and above"
echo "journalctl -p 3              # Same as above"
echo "journalctl -p 2..4           # Range of priorities"
echo

echo "6. Kernel messages:"
echo "journalctl -k                # Kernel messages only"
echo "journalctl -k -b             # Kernel msgs current boot"
echo

# ====================================
# USER MANAGEMENT EXAMPLES
# ====================================

echo "=== USER MANAGEMENT EXAMPLES ==="
echo

echo "1. Viewing user information:"
echo "cat /etc/passwd | head -5     # First 5 users"
echo "getent passwd username        # Get specific user info"
echo "id username                   # Show user/group IDs"
echo "groups username               # Show user's groups"
echo

echo "2. Creating users (as root):"
echo "adduser newuser               # Interactive user creation"
echo "useradd -m -s /bin/bash newuser"
echo "passwd newuser                # Set password"
echo

echo "3. User modification:"
echo "usermod -s /bin/zsh username  # Change shell"
echo "usermod -G group1,group2 user # Add to groups"
echo "chfn username                 # Change real name"
echo

echo "4. Group management:"
echo "cat /etc/group | grep username"
echo "groupadd newgroup             # Create group"
echo "usermod -a -G newgroup user   # Add user to group"
echo

# ====================================
# CRON EXAMPLES
# ====================================

echo "=== CRON SCHEDULING EXAMPLES ==="
echo

echo "1. Common cron patterns:"
echo "# minute hour day month dow command"
echo "0 2 * * *        # Daily at 2 AM"
echo "30 14 * * 1      # Mondays at 2:30 PM"
echo "0 */6 * * *      # Every 6 hours"
echo "15 9 1 * *       # 1st of month at 9:15 AM"
echo "0 9-17 * * 1-5   # Hourly, 9-5, weekdays"
echo

echo "2. Crontab management:"
echo "crontab -e                    # Edit your crontab"
echo "crontab -l                    # List your crontab"
echo "crontab -r                    # Remove your crontab"
echo "crontab -u user -l            # List another user's crontab"
echo

echo "3. Example cron entries:"
cat << 'EOF'
# Backup home directory daily at 3 AM
0 3 * * * tar -czf /backup/home-$(date +\%Y\%m\%d).tar.gz /home/

# Clear temp files every hour
0 * * * * find /tmp -type f -atime +1 -delete

# Check disk space and email report weekly
0 8 * * 1 df -h | mail -s "Weekly Disk Report" admin@domain.com

# Restart service every Sunday at midnight
0 0 * * 0 systemctl restart myservice
EOF
echo

# ====================================
# SYSTEMD TIMER EXAMPLES
# ====================================

echo "=== SYSTEMD TIMER EXAMPLES ==="
echo

echo "1. Timer unit example (backup.timer):"
cat << 'EOF'
[Unit]
Description=Daily backup timer
Requires=backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
echo

echo "2. Service unit example (backup.service):"
cat << 'EOF'
[Unit]
Description=Daily backup service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-script.sh
User=backup
EOF
echo

echo "3. Timer management commands:"
echo "systemctl daemon-reload       # Reload unit files"
echo "systemctl enable backup.timer # Enable timer"
echo "systemctl start backup.timer  # Start timer"
echo "systemctl list-timers         # List active timers"
echo "systemctl status backup.timer # Check timer status"
echo

echo "4. OnCalendar examples:"
echo "OnCalendar=daily              # Daily at midnight"
echo "OnCalendar=weekly             # Weekly on Monday"
echo "OnCalendar=monthly            # Monthly on 1st"
echo "OnCalendar=*-*-* 02:30:00     # Daily at 2:30 AM"
echo "OnCalendar=Mon *-*-* 09:00:00 # Mondays at 9 AM"
echo "OnCalendar=*:0/15             # Every 15 minutes"
echo

# ====================================
# TIME MANAGEMENT EXAMPLES
# ====================================

echo "=== TIME MANAGEMENT EXAMPLES ==="
echo

echo "1. Viewing time information:"
echo "date                          # Current date/time"
echo "date +%s                      # Unix timestamp"
echo "timedatectl                   # Systemd time info"
echo "hwclock --show                # Hardware clock"
echo

echo "2. Setting timezone:"
echo "timedatectl list-timezones    # List timezones"
echo "timedatectl set-timezone US/Eastern"
echo "ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime"
echo

echo "3. Network time sync:"
echo "timedatectl set-ntp true      # Enable NTP"
echo "systemctl status systemd-timesyncd"
echo "timedatectl show-timesync     # Sync status"
echo

# ====================================
# ONE-TIME SCHEDULING
# ====================================

echo "=== ONE-TIME SCHEDULING EXAMPLES ==="
echo

echo "1. Using at command:"
echo "at 15:30                      # 3:30 PM today"
echo "at 15:30 tomorrow"
echo "at 15:30 01/15/2024"
echo "at now + 1 hour"
echo "at now + 30 minutes"
echo

echo "2. at job management:"
echo "atq                           # List scheduled jobs"
echo "atrm 1                        # Remove job number 1"
echo "at -l                         # Same as atq"
echo

echo "3. systemd-run for one-time tasks:"
echo "systemd-run --on-active=10m echo 'Hello'"
echo "systemd-run --on-calendar='2024-12-25 09:00' /path/to/script"
echo

# ====================================
# PAM CONFIGURATION EXAMPLES
# ====================================

echo "=== PAM CONFIGURATION EXAMPLES ==="
echo

echo "1. Viewing PAM configuration:"
echo "ls /etc/pam.d/                # List PAM configs"
echo "cat /etc/pam.d/login          # Login PAM config"
echo "cat /etc/pam.d/sudo           # Sudo PAM config"
echo

echo "2. Common PAM modules:"
echo "pam_unix.so       # Traditional Unix auth"
echo "pam_shells.so     # Check valid shells"
echo "pam_rootok.so     # Allow root without password"
echo "pam_deny.so       # Always deny"
echo "pam_permit.so     # Always permit"
echo

echo "3. Example PAM config for custom service:"
cat << 'EOF'
# /etc/pam.d/myservice
auth    sufficient  pam_rootok.so
auth    required    pam_shells.so
auth    required    pam_unix.so
account required    pam_unix.so
session required    pam_unix.so
EOF
echo

# ====================================
# PRACTICAL SCENARIOS
# ====================================

echo "=== PRACTICAL SCENARIOS ==="
echo

echo "1. Monitoring log for failed logins:"
echo "journalctl -f | grep 'Failed password'"
echo "journalctl --since yesterday | grep 'authentication failure'"
echo

echo "2. Setting up automatic log cleanup:"
cat << 'EOF'
# Add to crontab for weekly log rotation
0 3 * * 0 /usr/sbin/logrotate /etc/logrotate.conf

# Cleanup old journal entries
journalctl --vacuum-time=30d
journalctl --vacuum-size=1G
EOF
echo

echo "3. User account auditing:"
echo "# Find users with no password"
echo "awk -F: '(\$2 == \"\") {print \$1}' /etc/passwd"
echo
echo "# Find users with UID 0 (should only be root)"
echo "awk -F: '(\$3 == \"0\") {print \$1}' /etc/passwd"
echo

echo "4. Monitoring system resources with cron:"
cat << 'EOF'
# Check disk usage every hour and log
0 * * * * df -h > /var/log/disk-usage.log

# Monitor memory usage
*/5 * * * * free -h >> /var/log/memory-usage.log

# Check for high load
*/10 * * * * uptime >> /var/log/load-average.log
EOF
echo

echo "5. Backup automation with systemd timers:"
cat << 'EOF'
# Create backup.timer
[Unit]
Description=Weekly backup
Requires=backup.service

[Timer]
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target

# Create backup.service
[Unit]
Description=System backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/system-backup.sh
User=backup
Group=backup
EOF