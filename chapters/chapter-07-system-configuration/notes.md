# Chapter 7: System Configuration - Logging, System Time, Batch Jobs, and Users

## Overview
This chapter covers the infrastructure that makes user-space software available, including:
- System logging
- Configuration files for server and user information
- Server programs (daemons) that run at boot
- Configuration utilities
- Time configuration
- Periodic task scheduling

---

## 7.1 System Logging

### Key Concepts
- **System Logger**: Most system programs write diagnostic output to the syslog service
- **Modern Logging**: journald (systemd) has largely replaced traditional syslogd
- **Log Location**: Traditional logs in `/var/log`, journald logs in `/var/log/journal`

### Log Message Format
```
Aug 19 17:59:48 duplex sshd[484]: Server listening on 0.0.0.0 port 22.
```
Contains: timestamp, hostname, process name, process ID, message

### Checking Your Log Setup
1. **Check for journald**: Run `journalctl` - if active, shows paged log messages
2. **Check for rsyslogd**: Look for process and `/etc/rsyslog.conf`
3. **Check for syslog-ng**: Look for `/etc/syslog-ng` directory
4. **Check log files**: Examine `/var/log` for log files

### Using journalctl

#### Basic Usage
```bash
journalctl                    # All messages (paged)
journalctl -r                # Reverse chronological order
journalctl -f                # Follow (like tail -f)
```

#### Filtering by Time
```bash
journalctl -S -4h            # Last 4 hours
journalctl -S 06:00:00       # Since 6 AM today
journalctl -S 2020-01-14     # Since specific date
journalctl -S '2020-01-14 14:30:00'  # Date and time
journalctl -U <time>         # Until specific time
```

#### Filtering by Unit
```bash
journalctl -u cron.service   # Specific service
journalctl -u cron          # Can omit .service
journalctl -F _SYSTEMD_UNIT # List all units in journal
```

#### Other Filters
```bash
journalctl -N               # List all available fields
journalctl _PID=8792       # By process ID
journalctl -g 'kernel.*memory'  # Regex search
journalctl -b              # Current boot
journalctl -b -1           # Previous boot
journalctl --list-boots    # Show boot IDs
journalctl -k              # Kernel messages
journalctl -p 3            # Priority 0-3 (most important)
journalctl -p 2..3         # Priority range
```

### Log Rotation (Traditional syslog)
- **Purpose**: Prevent logs from consuming all disk space
- **Tool**: `logrotate` utility
- **Process**: 
  1. Remove oldest file (e.g., `auth.log.3`)
  2. Rename files: `auth.log.2` → `auth.log.3`, etc.
  3. Current log becomes `auth.log.1`
- **Compression**: Often compresses rotated files (`.gz`)

### Journal Maintenance (journald)
- **Self-managing**: journald automatically removes old messages
- **Criteria**: Based on filesystem space, percentage, maximum size, age
- **Configuration**: See `journald.conf(5)` manual page

---

## 7.2 The Structure of /etc

### Organization
- **Purpose**: System configuration files
- **Evolution**: Individual files → subdirectories for better organization
- **Examples**: `/etc/systemd`, `/etc/grub.d`

### Configuration Guidelines
- **Machine-specific**: User info (`/etc/passwd`), network details go in `/etc`
- **Application defaults**: Usually found elsewhere (e.g., `/usr/lib/systemd`)
- **Customizations**: Separate files in subdirectories to avoid upgrade overwrites

---

## 7.3 User Management Files

### 7.3.1 /etc/passwd File
**Format**: Seven colon-separated fields per line
```
username:password:UID:GID:GECOS:home_directory:shell
```

**Example**:
```
juser:x:3119:1000:J. Random User:/home/juser:/bin/bash
```

**Fields**:
1. **Username**: Login name
2. **Password**: `x` = shadow file, `*` = cannot login, `::` = no password (dangerous)
3. **UID**: User ID (kernel representation)
4. **GID**: Primary group ID
5. **GECOS**: Real name, contact info
6. **Home Directory**: User's home path
7. **Shell**: Login shell

### 7.3.2 Special Users
- **root**: UID 0, GID 0 (superuser)
- **daemon**: No login privileges
- **nobody**: Underprivileged user for security
- **Pseudo-users**: Cannot log in but can run processes

### 7.3.3 /etc/shadow File
- **Purpose**: Stores encrypted passwords and expiration info
- **Security**: Only readable by root
- **Integration**: Works with PAM for authentication

### 7.3.4 User Management Commands
```bash
passwd                       # Change your password
passwd user                  # Change user's password (as root)
chfn                        # Change real name
chsh                        # Change shell
adduser                     # Add user
userdel                     # Delete user
vipw                        # Edit /etc/passwd safely
vipw -s                     # Edit /etc/shadow safely
```

### 7.3.5 Groups (/etc/group)
**Format**: Four colon-separated fields
```
group_name:password:GID:user_list
```

**Example**:
```
disk:*:6:juser,beazley
```

**Commands**:
```bash
groups                      # Show your groups
```

---

## 7.4 getty and login

### Process Flow
1. **getty**: Attaches to terminals, displays login prompt
2. **login**: Handles password authentication
3. **Shell**: Replaces login process after successful auth

### Modern Usage
- **Virtual terminals**: CTRL-ALT-F1
- **Graphical login**: gdm, lightdm, etc.
- **Remote login**: SSH (doesn't use getty/login)

---

## 7.5 Setting the Time

### Time Components
- **System Clock**: Kernel-maintained time
- **RTC**: Battery-backed real-time clock (hardware)
- **Time Drift**: Difference between kernel time and true time

### Time Management
```bash
date                        # Show current time
date +%s                    # Unix timestamp
hwclock --systohc --utc     # Set RTC from system clock
```

### Time Zones
- **Kernel Time**: Seconds since January 1, 1970 UTC
- **Local Time File**: `/etc/localtime` (binary)
- **Zone Files**: `/usr/share/zoneinfo/`
- **Commands**:
```bash
tzselect                    # Interactive timezone selection
export TZ=US/Central        # Set timezone for session
TZ=US/Central date         # One-time timezone
```

### Network Time
- **Modern**: `systemd-timesyncd` (default on most distributions)
- **Traditional**: `ntpd`
- **Configuration**: `timesyncd.conf(5)`
- **Offline**: `chronyd` for disconnected systems

---

## 7.6 Scheduling Recurring Tasks

### 7.6.1 Cron

#### Crontab Format
```
minute hour day_of_month month day_of_week command
```
- **Fields**: 0-59 min, 0-23 hour, 1-31 day, 1-12 month, 0-7 day_of_week
- **Wildcards**: `*` = every value
- **Multiple values**: `5,14` = 5th and 14th
- **Example**: `15 09 * * * /home/user/script` (daily at 9:15 AM)

#### Crontab Management
```bash
crontab file                # Install crontab from file
crontab -l                  # List current crontab
crontab -e                  # Edit crontab
crontab -r                  # Remove crontab
```

#### System Crontabs
- **File**: `/etc/crontab`
- **Format**: Additional user field before command
- **Additional**: Files in `/etc/cron.d/`
- **Directories**: `/etc/cron.daily/`, `/etc/cron.weekly/`, etc.

### 7.6.2 Systemd Timer Units

#### Timer Unit Example (`loggertest.timer`)
```ini
[Unit]
Description=Example timer unit

[Timer]
OnCalendar=*-*-* *:00,20,40
Unit=loggertest.service

[Install]
WantedBy=timers.target
```

#### Service Unit Example (`loggertest.service`)
```ini
[Unit]
Description=Example Test Service

[Service]
Type=oneshot
ExecStart=/usr/bin/logger -p local3.debug I\'m a logger
```

#### Time Format
- **Syntax**: `year-month-day hour:minute:second`
- **Wildcards**: `*` for any value
- **Multiple**: Comma-separated
- **Periodic**: `/` syntax (e.g., `*:00/20` = every 20 minutes)

### 7.6.3 Cron vs Timer Units

#### Cron Advantages
- Simpler configuration
- Third-party compatibility
- Easier user installation

#### Timer Unit Advantages
- Better process tracking (cgroups)
- Excellent logging in journal
- More activation options
- Systemd integration

---

## 7.7 One-Time Task Scheduling

### Using `at`
```bash
at 22:30                    # Schedule for 10:30 PM
at> command
# CTRL-D to end

atq                         # List scheduled jobs
atrm                        # Remove job
at 22:30 30.09.15          # Include date
```

### Timer Unit Alternative
```bash
systemd-run --on-calendar='2022-08-14 18:00' /bin/echo "test"
systemd-run --on-active=30m /bin/echo "test"  # 30 minutes from now
```

---

## 7.8 User Timer Units

### Running as Regular User
```bash
systemd-run --user --on-calendar='...' command
```

### Persistent User Services
```bash
loginctl enable-linger         # Keep user manager after logout
loginctl enable-linger user    # For another user (as root)
```

---

## 7.9 User Access and Security

### 7.9.1 User ID Types
- **Effective UID (euid)**: Defines access rights/permissions
- **Real UID (ruid)**: Who initiated the process (can kill it)
- **Saved UID**: Can switch euid to ruid or saved UID

### 7.9.2 Process Ownership
```bash
ps -eo pid,euser,ruser,comm  # Show effective and real users
```

### 7.9.3 Security Principles
- **Identification**: Who users are (numeric UIDs)
- **Authentication**: Proving identity (passwords, etc.)
- **Authorization**: What users can do (permissions)

### 7.9.4 Library Functions
- **getuid()**: Get user ID
- **geteuid()**: Get effective user ID
- **getpwuid()**: Get username from UID

---

## 7.10 Pluggable Authentication Modules (PAM)

### Purpose
- **Flexibility**: Support multiple authentication methods
- **Modularity**: Shared libraries for different auth types
- **Standardization**: Common interface for applications

### Configuration Location
- **Directory**: `/etc/pam.d/`
- **Per-application**: Separate files for each service

### Configuration Format
```
function_type control_argument module [arguments]
```

#### Function Types
- **auth**: Authenticate user
- **account**: Check account status/authorization
- **session**: Session-specific actions
- **password**: Change passwords/credentials

#### Control Arguments
- **sufficient**: Success = immediate success, failure = continue
- **requisite**: Success = continue, failure = immediate failure
- **required**: Continue regardless, but failure = eventual failure

#### Example Configuration
```
auth sufficient pam_rootok.so
auth requisite pam_shells.so
auth sufficient pam_unix.so
auth required pam_deny.so
```

### Common Modules
- **pam_unix.so**: Traditional Unix authentication
- **pam_shells.so**: Check if shell is in `/etc/shells`
- **pam_rootok.so**: Allow root without password
- **pam_deny.so**: Always deny (default fallback)

### Module Arguments
```
auth sufficient pam_unix.so nullok    # Allow empty passwords
```

---

## Important Files and Directories

| Path | Purpose |
|------|---------|
| `/var/log/` | Traditional log files |
| `/var/log/journal/` | journald binary logs |
| `/etc/passwd` | User account information |
| `/etc/shadow` | Encrypted passwords |
| `/etc/group` | Group definitions |
| `/etc/localtime` | System timezone |
| `/usr/share/zoneinfo/` | Timezone database |
| `/etc/crontab` | System-wide cron jobs |
| `/var/spool/cron/crontabs/` | User crontab files |
| `/etc/pam.d/` | PAM configuration |

---

## Key Commands Summary

### Logging
```bash
journalctl [options]        # View system logs
systemctl status unit       # Service status and recent logs
```

### User Management
```bash
id                          # Show user/group IDs
whoami                      # Current username
su - user                   # Switch user
sudo command                # Run as another user
```

### Time
```bash
date                        # Show/set system time
timedatectl                 # Modern time control
hwclock                     # Hardware clock
```

### Scheduling
```bash
crontab -e                  # Edit user crontab
systemctl list-timers       # Show active timers
at time                     # Schedule one-time job
```