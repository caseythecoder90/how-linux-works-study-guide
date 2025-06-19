# User Management Flashcards

## User Account Basics

### Card 1
**Q:** What are the 7 fields in /etc/passwd in order?
**A:** username:password:UID:GID:GECOS:home_directory:shell

### Card 2
**Q:** What UID does the root user always have?
**A:** 0 (zero)

### Card 3
**Q:** What does an asterisk (*) in the password field mean?
**A:** The user cannot log in.

### Card 4
**Q:** What does the 'x' in the password field of /etc/passwd mean?
**A:** The encrypted password is stored in the /etc/shadow file.

### Card 5
**Q:** What's the difference between a regular user and a pseudo-user?
**A:** Pseudo-users cannot log in but the system can start processes with their user IDs (often for security reasons).

### Card 6
**Q:** What's the purpose of the nobody user?
**A:** It's an underprivileged user that some processes run as because it cannot normally write to anything on the system (security measure).

## Commands

### Card 7
**Q:** How do you safely edit /etc/passwd?
**A:** Use `vipw` command, which backs up and locks the file while editing.

### Card 8
**Q:** What command shows which groups you belong to?
**A:** `groups`

### Card 9
**Q:** How do you change a user's shell?
**A:** `chsh` (change shell)

### Card 10
**Q:** How do you change your real name in the system?
**A:** `chfn` (change finger information)

## Security

### Card 11
**Q:** What are the three types of user IDs associated with a process?
**A:** effective UID (euid), real UID (ruid), and saved UID.

### Card 12
**Q:** What's the difference between effective UID and real UID?
**A:** Effective UID defines access rights/permissions, real UID indicates who initiated the process (who can kill it).

### Card 13
**Q:** What command shows effective and real user IDs for processes?
**A:** `ps -eo pid,euser,ruser,comm`