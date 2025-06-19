# Chapter 7: System Configuration Flashcards

## Logging

### Card 1
**Q:** What is the difference between syslogd and journald?
**A:** syslogd is the traditional system logging daemon that writes to text files, while journald is the systemd logging daemon that writes to binary logs and has replaced syslogd on many modern systems.

### Card 2
**Q:** How do you view the last 4 hours of system logs using journald?
**A:** `journalctl -S -4h`

### Card 3
**Q:** What command shows logs from the previous boot?
**A:** `journalctl -b -1`

### Card 4
**Q:** How do you follow logs in real-time with journald?
**A:** `journalctl -f`

### Card 5
**Q:** What does the 'x' in the password field of /etc/passwd mean?
**A:** The encrypted password is stored in the /etc/shadow file.

### Card 6
**Q:** How do you filter journald logs by a specific systemd service?
**A:** `journalctl -u service_name` (can omit .service extension)

### Card 7
**Q:** What does log rotation accomplish and what tool is commonly used?
**A:** Log rotation prevents logs from consuming all disk space by archiving and removing old log files. The `logrotate` utility is commonly used.

### Card 8
**Q:** Where are journald binary logs stored?
**A:** `/var/log/journal/`

## User Management

### Card 9
**Q:** What are the 7 fields in /etc/passwd in order?
**A:** username:password:UID:GID:GECOS:home_directory:shell

### Card 10
**Q:** What UID does the root user always have?
**A:** 0 (zero)

### Card 11
**Q:** What's the difference between a regular user and a pseudo-user?
**A:** Pseudo-users cannot log in but the system can start processes with their user IDs (often for security reasons).

### Card 12
**Q:** How do you safely edit /etc/passwd?
**A:** Use `vipw` command, which backs up and locks the file while editing.

### Card 13
**Q:** What does an asterisk (*) in the password field mean?
**A:** The user cannot log in.

### Card 14
**Q:** What command shows which groups you belong to?
**A:** `groups`

### Card 15
**Q:** What's the purpose of the nobody user?
**A:** It's an underprivileged user that some processes run as because it cannot normally write to anything on the system (security measure).

## Time Management

### Card 16
**Q:** How does the Linux kernel represent time?
**A:** As the number of seconds since 12:00 midnight on January 1, 1970, UTC (Unix timestamp).

### Card 17
**Q:** What file controls the system's time zone?
**A:** `/etc/localtime`

### Card 18
**Q:** Where are time zone files stored?
**A:** `/usr/share/zoneinfo/`

### Card 19
**Q:** What modern daemon handles network time synchronization?
**A:** `systemd-timesyncd`

### Card 20
**Q:** How do you set the hardware clock from the system clock?
**A:** `hwclock --systohc --utc`

### Card 21
**Q:** How do you set a temporary time zone for one command?
**A:** `TZ=US/Central date`

## Cron and Scheduling

### Card 22
**Q:** What are the 5 time fields in a crontab entry in order?
**A:** minute hour day_of_month month day_of_week

### Card 23
**Q:** What does this cron entry mean: `15 09 * * *`?
**A:** Run at 9:15 AM every day.

### Card 24
**Q:** How do you edit your personal crontab?
**A:** `crontab -e`

### Card 25
**Q:** What's the difference between user crontabs and system crontab?
**A:** System crontab (/etc/crontab) has an additional user field before the command, specifying which user should run the job.

### Card 26
**Q:** What systemd service type should timer-activated services typically use?
**A:** `oneshot` - indicates the service runs and exits, systemd waits for completion.

### Card 27
**Q:** How do you list all active systemd timers?
**A:** `systemctl list-timers`

### Card 28
**Q:** What does `OnCalendar=*-*-* *:00,20,40` mean in a timer unit?
**A:** Run at the top of each hour, 20 minutes past, and 40 minutes past every hour.

## One-Time Scheduling

### Card 29
**Q:** How do you schedule a one-time job for 10:30 PM using at?
**A:** `at 22:30`, then enter the command and press Ctrl-D.

### Card 30
**Q:** How do you list scheduled at jobs?
**A:** `atq`

### Card 31
**Q:** How do you create a one-time systemd timer for a future date?
**A:** `systemd-run --on-calendar='2022-08-14 18:00' command`

## User Security and PAM

### Card 32
**Q:** What are the three types of user IDs associated with a process?
**A:** effective UID (euid), real UID (ruid), and saved UID.

### Card 33
**Q:** What's the difference between effective UID and real UID?
**A:** Effective UID defines access rights/permissions, real UID indicates who initiated the process (who can kill it).

### Card 34
**Q:** What does PAM stand for and what's its purpose?
**A:** Pluggable Authentication Modules - provides flexible authentication by using shared libraries for different authentication methods.

### Card 35
**Q:** Where are PAM configuration files located?
**A:** `/etc/pam.d/`

### Card 36
**Q:** What are the 4 PAM function types?
**A:** auth (authenticate), account (check status), session (session actions), password (change credentials).

### Card 37
**Q:** What's the difference between "sufficient" and "requisite" PAM control arguments?
**A:** sufficient: success = immediate success, failure = continue; requisite: success = continue, failure = immediate failure.

### Card 38
**Q:** What does the pam_unix.so module do for the auth function?
**A:** Checks the user's password using traditional Unix authentication.

## File Locations

### Card 39
**Q:** Where are system configuration files primarily located?
**A:** `/etc/`

### Card 40
**Q:** What's stored in /etc/shadow?
**A:** Encrypted passwords and password expiration information.

### Card 41
**Q:** Where are user crontab files stored?
**A:** `/var/spool/cron/crontabs/`

### Card 42
**Q:** Where would you place custom systemd unit files?
**A:** `/etc/systemd/system/`

## Commands and Utilities

### Card 43
**Q:** How do you change a user's shell?
**A:** `chsh` (change shell)

### Card 44
**Q:** How do you change your real name in the system?
**A:** `chfn` (change finger information)

### Card 45
**Q:** What command shows effective and real user IDs for processes?
**A:** `ps -eo pid,euser,ruser,comm`

### Card 46
**Q:** How do you remove a scheduled at job?
**A:** `atrm` followed by the job number

### Card 47
**Q:** What does the loginctl enable-linger command do?
**A:** Keeps the user's systemd manager running after logout, allowing user timer units to continue running.

### Card 48
**Q:** How do you search journald logs with a regular expression?
**A:** `journalctl -g 'pattern'`

### Card 49
**Q:** What command shows all available fields in the journal?
**A:** `journalctl -N`

### Card 50
**Q:** How do you filter journald logs by priority level?
**A:** `journalctl -p level` (where level is 0-7, 0 being most important)