# Logging Flashcards

## System Logging Concepts

### Card 1
**Q:** What is the difference between syslogd and journald?
**A:** syslogd is the traditional system logging daemon that writes to text files, while journald is the systemd logging daemon that writes to binary logs and has replaced syslogd on many modern systems.

### Card 2
**Q:** Where are journald binary logs stored?
**A:** `/var/log/journal/`

### Card 3
**Q:** What does log rotation accomplish and what tool is commonly used?
**A:** Log rotation prevents logs from consuming all disk space by archiving and removing old log files. The `logrotate` utility is commonly used.

## Commands

### Card 4
**Q:** How do you view the last 4 hours of system logs using journald?
**A:** `journalctl -S -4h`

### Card 5
**Q:** What command shows logs from the previous boot?
**A:** `journalctl -b -1`

### Card 6
**Q:** How do you follow logs in real-time with journald?
**A:** `journalctl -f`

### Card 7
**Q:** How do you filter journald logs by a specific systemd service?
**A:** `journalctl -u service_name` (can omit .service extension)

### Card 8
**Q:** How do you search journald logs with a regular expression?
**A:** `journalctl -g 'pattern'`

### Card 9
**Q:** What command shows all available fields in the journal?
**A:** `journalctl -N`

### Card 10
**Q:** How do you filter journald logs by priority level?
**A:** `journalctl -p level` (where level is 0-7, 0 being most important)