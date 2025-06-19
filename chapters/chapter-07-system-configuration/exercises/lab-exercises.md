# Chapter 7: System Configuration Lab Exercise

## Prerequisites
- Linux system with root access (VM recommended)
- Basic command line knowledge
- Understanding of text editors (nano, vim, etc.)

## Lab Objectives
By the end of this lab, you will:
1. Master system logging with journald
2. Create and manage user accounts
3. Set up automated tasks with cron and systemd timers
4. Configure time settings
5. Understand PAM basics

---

## Part 1: System Logging Exploration (20 minutes)

### Exercise 1.1: Basic Log Viewing
1. View the last 100 lines of system logs:
   ```bash
   journalctl -n 100
   ```

2. View logs from the last 2 hours:
   ```bash
   journalctl -S -2h
   ```

3. Follow logs in real-time (let it run for 1 minute, then press Ctrl+C):
   ```bash
   journalctl -f
   ```

### Exercise 1.2: Service-Specific Logging
1. View SSH service logs:
   ```bash
   journalctl -u sshd
   ```

2. View logs from a specific boot:
   ```bash
   journalctl -b
   journalctl -b -1  # previous boot if available
   ```

3. Generate a log entry and find it:
   ```bash
   logger "This is a test message from $(whoami)"
   journalctl -g "test message" --since "1 minute ago"
   ```

### Exercise 1.3: Log Analysis
1. Find all error messages from today:
   ```bash
   journalctl -p err --since today
   ```

2. Search for kernel messages:
   ```bash
   journalctl -k --since today
   ```

3. Count log entries by priority:
   ```bash
   journalctl --since today | grep -c "WARN\|ERROR\|CRIT"
   ```

**Questions:**
- What services generate the most log entries on your system?
- Can you identify any errors or warnings that need attention?

---

## Part 2: User Management (25 minutes)

### Exercise 2.1: Examining Current Users
1. View all users in the system:
   ```bash
   cat /etc/passwd
   ```

2. Count total users:
   ```bash
   wc -l /etc/passwd
   ```

3. Find users with login shells:
   ```bash
   grep -v "nologin\|false" /etc/passwd
   ```

### Exercise 2.2: Create a Test User
1. Create a new user (as root):
   ```bash
   sudo adduser testuser
   # Follow the prompts
   ```

2. Verify the user was created:
   ```bash
   grep testuser /etc/passwd
   grep testuser /etc/group
   ```

3. Check the user's home directory:
   ```bash
   ls -la /home/testuser
   ```

### Exercise 2.3: User Modification
1. Change the test user's shell:
   ```bash
   sudo chsh -s /bin/bash testuser
   ```

2. Add user to a group:
   ```bash
   sudo usermod -a -G sudo testuser
   ```

3. Verify changes:
   ```bash
   grep testuser /etc/passwd
   groups testuser
   ```

### Exercise 2.4: Password Management
1. Set a password for testuser:
   ```bash
   sudo passwd testuser
   ```

2. Test login as the new user:
   ```bash
   su - testuser
   whoami
   exit
   ```

3. Examine shadow file (as root):
   ```bash
   sudo grep testuser /etc/shadow
   ```

**Questions:**
- What's the UID of your test user?
- What groups is the test user a member of?
- What does the encrypted password look like in /etc/shadow?

---

## Part 3: Time Configuration (15 minutes)

### Exercise 3.1: Time Information
1. Check current system time:
   ```bash
   date
   timedatectl
   ```

2. View available timezones:
   ```bash
   timedatectl list-timezones | grep -i america
   ```

3. Check hardware clock:
   ```bash
   sudo hwclock --show
   ```

### Exercise 3.2: Timezone Testing
1. Temporarily change timezone for one command:
   ```bash
   TZ=UTC date
   TZ=Asia/Tokyo date
   ```

2. Check NTP synchronization:
   ```bash
   timedatectl show-timesync
   ```

3. View time sync status:
   ```bash
   systemctl status systemd-timesyncd
   ```

**Questions:**
- Is your system using NTP synchronization?
- What's the difference between system time and hardware time?

---

## Part 4: Cron Scheduling (25 minutes)

### Exercise 4.1: Personal Crontab
1. Create a simple script to test:
   ```bash
   echo '#!/bin/bash
   echo "Cron test at $(date)" >> /tmp/crontest.log' > ~/crontest.sh
   chmod +x ~/crontest.sh
   ```

2. Edit your crontab:
   ```bash
   crontab -e
   ```

3. Add this line (runs every minute):
   ```
   * * * * * /home/$(whoami)/crontest.sh
   ```

4. Save and wait 2-3 minutes, then check:
   ```bash
   cat /tmp/crontest.log
   ```

5. List your crontab:
   ```bash
   crontab -l
   ```

### Exercise 4.2: System Crontab
1. Examine system crontab:
   ```bash
   sudo cat /etc/crontab
   ```

2. Check cron directories:
   ```bash
   ls -la /etc/cron.*
   ```

3. Look at a system cron job:
   ```bash
   sudo ls -la /etc/cron.daily/
   sudo cat /etc/cron.daily/logrotate  # if exists
   ```

### Exercise 4.3: Cron Cleanup
1. Remove your test cron job:
   ```bash
   crontab -e
   # Delete the line you added
   ```

2. Verify removal:
   ```bash
   crontab -l
   ```

**Questions:**
- How would you schedule a job to run every weekday at 9 AM?
- What's the difference between user and system crontabs?

---

## Part 5: Systemd Timer Units (30 minutes)

### Exercise 5.1: Create a Simple Timer
1. Create a service unit file:
   ```bash
   sudo nano /etc/systemd/system/hello.service
   ```

2. Add this content:
   ```ini
   [Unit]
   Description=Hello World Service

   [Service]
   Type=oneshot
   ExecStart=/bin/echo "Hello from systemd timer at $(date)"
   ```

3. Create a timer unit file:
   ```bash
   sudo nano /etc/systemd/system/hello.timer
   ```

4. Add this content:
   ```ini
   [Unit]
   Description=Hello Timer
   Requires=hello.service

   [Timer]
   OnCalendar=*:*:0/30
   Persistent=true

   [Install]
   WantedBy=timers.target
   ```

### Exercise 5.2: Activate the Timer
1. Reload systemd:
   ```bash
   sudo systemctl daemon-reload
   ```

2. Enable and start the timer:
   ```bash
   sudo systemctl enable hello.timer
   sudo systemctl start hello.timer
   ```

3. Check timer status:
   ```bash
   sudo systemctl status hello.timer
   sudo systemctl list-timers
   ```

### Exercise 5.3: Monitor Timer Execution
1. Watch the timer execute:
   ```bash
   journalctl -f -u hello.service
   # Wait for it to run (every 30 seconds)
   # Press Ctrl+C after seeing it run
   ```

2. Check execution history:
   ```bash
   journalctl -u hello.service --since "10 minutes ago"
   ```

### Exercise 5.4: Timer Cleanup
1. Stop and disable the timer:
   ```bash
   sudo systemctl stop hello.timer
   sudo systemctl disable hello.timer
   ```

2. Remove the unit files:
   ```bash
   sudo rm /etc/systemd/system/hello.{timer,service}
   sudo systemctl daemon-reload
   ```

**Questions:**
- What does `OnCalendar=*:*:0/30` mean?
- How is the timer execution tracked differently from cron?

---

## Part 6: At Command (10 minutes)

### Exercise 6.1: Schedule One-Time Tasks
1. Schedule a task for 2 minutes from now:
   ```bash
   at now + 2 minutes
   at> echo "Hello from at command" > /tmp/at-test.txt
   at> <Press Ctrl+D>
   ```

2. List scheduled jobs:
   ```bash
   atq
   ```

3. Wait 2+ minutes and check result:
   ```bash
   cat /tmp/at-test.txt
   ```

### Exercise 6.2: systemd-run Alternative
1. Schedule with systemd-run:
   ```bash
   systemd-run --on-active=1m echo "Hello from systemd-run"
   ```

2. Check the transient service:
   ```bash
   systemctl list-units --type=service | grep run-
   ```

---

## Part 7: PAM Exploration (15 minutes)

### Exercise 7.1: Examine PAM Configuration
1. List PAM configuration files:
   ```bash
   ls -la /etc/pam.d/
   ```

2. Examine login PAM configuration:
   ```bash
   sudo cat /etc/pam.d/login
   ```

3. Look at sudo PAM configuration:
   ```bash
   sudo cat /etc/pam.d/sudo
   ```

### Exercise 7.2: Find PAM Modules
1. Locate PAM modules:
   ```bash
   find /lib* -name "pam_*.so" 2>/dev/null | head -10
   ```

2. Get help on PAM modules:
   ```bash
   man pam_unix
   man pam_shells
   ```

**Questions:**
- What PAM modules are used for SSH authentication?
- How does the PAM configuration differ between services?

---

## Part 8: System Cleanup (5 minutes)

### Clean up test artifacts:
1. Remove test user:
   ```bash
   sudo userdel -r testuser
   ```

2. Remove test files:
   ```bash
   rm -f /tmp/crontest.log /tmp/at-test.txt ~/crontest.sh
   ```

3. Verify cleanup:
   ```bash
   grep testuser /etc/passwd  # Should return nothing
   crontab -l  # Should be empty or not contain test jobs
   ```

---

## Lab Summary Questions

1. **Logging**: What's the main advantage of journald over traditional syslog?

2. **User Management**: What's the difference between `adduser` and `useradd`?

3. **Scheduling**: When would you use systemd timers instead of cron?

4. **Time**: Why is it important to keep system time synchronized?

5. **PAM**: How does PAM provide flexibility in authentication?

## Advanced Challenges (Optional)

1. **Log Analysis**: Write a script that analyzes journald logs and reports the top 10 most active services.

2. **User Monitoring**: Create a cron job that checks for users with empty passwords and emails an alert.

3. **System Maintenance**: Design a systemd timer that performs weekly system maintenance (updates, cleanup, etc.).

4. **Security Audit**: Create a script that checks for common security issues (users with UID 0, world-writable files, etc.).

## Further Learning

- Explore more advanced journald features (persistent storage, forwarding)
- Learn about systemd service dependencies and ordering
- Study PAM modules for two-factor authentication
- Investigate log analysis tools like `logwatch` or `fail2ban`
- Set up centralized logging with rsyslog

---

## Lab Completion Checklist

- [ ] Successfully viewed and filtered system logs
- [ ] Created and managed user accounts
- [ ] Set up and tested cron jobs
- [ ] Created and activated systemd timers
- [ ] Explored time configuration
- [ ] Used at command for one-time scheduling
- [ ] Examined PAM configuration
- [ ] Cleaned up all test artifacts
- [ ] Answered summary questions
- [ ] (Optional) Completed advanced challenges