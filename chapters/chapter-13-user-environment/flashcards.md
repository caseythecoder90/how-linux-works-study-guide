# Chapter 13: User Environments - Flashcards

## Basic Concepts

### Card 1
**Q:** What are startup files and why are they important?
**A:** Configuration files read by shells when they start that set defaults for shells, applications, and interactive programs. They determine how the system behaves when users log in.

### Card 2
**Q:** Why are startup files often called "dot files"?
**A:** Because they nearly always start with a dot (.), which excludes them from the default display of ls and most file managers.

### Card 3
**Q:** What is the difference between login and non-login shell sessions?
**A:** Login shells are started when a user logs in and read login-specific files. Non-login shells are started from within an existing session and typically only read runtime configuration files.

### Card 4
**Q:** What is the golden rule for creating startup files?
**A:** Keep the user in mind - startup files should be simple, well-tested, and work for the "lowest common denominator" user.

---

## Shell Startup File Order

### Card 5
**Q:** What is the startup file order for bash login shells?
**A:** 1. `/etc/profile` (system-wide), then first found: 2. `~/.bash_profile`, 3. `~/.bash_login`, or 4. `~/.profile`

### Card 6
**Q:** What startup files do bash interactive non-login shells read?
**A:** `/etc/bash.bashrc` (system-wide, if it exists) and `~/.bashrc`

### Card 7
**Q:** What is the recommended bash startup file strategy?
**A:** Create `~/.bashrc` with all configuration, then make `~/.bash_profile` source it with: `if [ -f ~/.bashrc ]; then source ~/.bashrc; fi`

### Card 8
**Q:** What are the main tcsh startup files?
**A:** `~/.tcshrc` (preferred) or `~/.cshrc` (fallback), and `/etc/csh.cshrc` (system-wide)

---

## Environment Variables

### Card 9
**Q:** What does the PATH environment variable do?
**A:** It's a colon-separated list of directories where the shell looks for commands, searched in order from left to right.

### Card 10
**Q:** Why should you never include the current directory (.) in your PATH?
**A:** Security risk - it could allow execution of malicious programs in the current directory that have the same name as system commands.

### Card 11
**Q:** What is the difference between `export VAR=value` and `VAR=value`?
**A:** `export` makes the variable available to child processes, while without export, the variable is only available in the current shell.

### Card 12
**Q:** What are the essential environment variables every user should know?
**A:** HOME (user's home directory), PATH (command search path), SHELL (user's login shell), USER (username), EDITOR (default editor), PAGER (default pager)

---

## Aliases and Functions

### Card 13
**Q:** What is the basic syntax for creating an alias?
**A:** `alias name='command'` - creates a shortcut where typing 'name' executes 'command'

### Card 14
**Q:** How do you remove an alias?
**A:** `unalias name` or `unalias -a` to remove all aliases

### Card 15
**Q:** What are the limitations of aliases?
**A:** Cannot contain complex logic, don't support parameters well, cannot change environment variables (run in subshell), limited to simple command substitution

### Card 16
**Q:** When should you use shell functions instead of aliases?
**A:** When you need complex logic, parameter handling, error checking, or the ability to change the current shell's environment

### Card 17
**Q:** How do you create a basic shell function?
**A:** `function_name() { commands; }` or `function function_name { commands; }`

---

## umask and Permissions

### Card 18
**Q:** What does umask do?
**A:** Sets default permissions for newly created files and directories by masking (removing) permissions from the default maximum permissions.

### Card 19
**Q:** What are the default maximum permissions for files and directories?
**A:** Files: 666 (rw-rw-rw-), Directories: 777 (rwxrwxrwx)

### Card 20
**Q:** What permissions result from umask 022?
**A:** Files: 644 (rw-r--r--), Directories: 755 (rwxr-xr-x) - owner can read/write, group and others can read

### Card 21
**Q:** What permissions result from umask 077?
**A:** Files: 600 (rw-------), Directories: 700 (rwx------) - only owner has any access

### Card 22
**Q:** When would you use umask 077?
**A:** On multi-user systems where privacy is important and you don't want other users to access your files

---

## Prompt Configuration

### Card 23
**Q:** What are the four prompt variables in bash?
**A:** PS1 (primary prompt), PS2 (secondary/continuation prompt), PS3 (select prompt), PS4 (debug prompt)

### Card 24
**Q:** What do these PS1 escape sequences mean: \u, \h, \w, \$?
**A:** \u = username, \h = hostname (short), \w = current working directory, \$ = $ for normal user, # for root

### Card 25
**Q:** How do you add colors to your bash prompt?
**A:** Use ANSI escape sequences like `\[\033[01;32m\]` for green text, `\[\033[00m\]` to reset colors

---

## Startup File Pitfalls

### Card 26
**Q:** Why shouldn't you put graphical commands in shell startup files?
**A:** Not all shells run in graphical environments, so these commands will fail in text-only sessions

### Card 27
**Q:** Why should you avoid setting the DISPLAY variable in startup files?
**A:** It can cause graphical sessions to misbehave, as the display should be set by the display manager

### Card 28
**Q:** Why is setting LD_LIBRARY_PATH in startup files problematic?
**A:** It can break system programs and cause hard-to-debug issues. Better to use package managers or configure ldconfig properly

### Card 29
**Q:** What types of commands should you avoid in startup files?
**A:** Commands that print to standard output, as they can break automation and non-interactive scripts

---

## Default Applications

### Card 30
**Q:** Why is bash recommended as the default shell?
**A:** Same shell for interactive and scripting, default on Linux distributions, uses GNU readline, excellent I/O redirection control

### Card 31
**Q:** What editors are recommended for default system use?
**A:** vi/vim (available on virtually every Unix system) or nano (beginner-friendly, often default on Linux distributions)

### Card 32
**Q:** What is the recommended pager and why?
**A:** less - more features than more, widely available, good for viewing long files with search and navigation

---

## System Configuration

### Card 33
**Q:** Where are system-wide startup files typically located?
**A:** `/etc/profile` (system-wide shell defaults), `/etc/bash.bashrc` (system-wide bash config), `/etc/skel/` (template files for new users)

### Card 34
**Q:** What is the purpose of /etc/skel/?
**A:** Contains template files that are copied to new user home directories when accounts are created

### Card 35
**Q:** How do you test startup file syntax without executing it?
**A:** `bash -n ~/.bashrc` - checks syntax without execution

### Card 36
**Q:** How do you trace startup file execution for debugging?
**A:** `bash -x ~/.bashrc` - shows each command as it's executed

---

## Advanced Concepts

### Card 37
**Q:** What is the difference between interactive and non-interactive shells?
**A:** Interactive shells accept user input and typically read startup files. Non-interactive shells run scripts and usually don't read startup files

### Card 38
**Q:** How do you check if a shell is running interactively?
**A:** Check if `$-` contains 'i' or if `$PS1` is set: `case $- in *i*) echo "interactive";; esac`

### Card 39
**Q:** What command shows all current environment variables?
**A:** `env` or `printenv` - displays all environment variables and their values

### Card 40
**Q:** How do you reload your bashrc without starting a new shell?
**A:** `source ~/.bashrc` or `. ~/.bashrc` - executes the file in the current shell context

---

## Security and Best Practices

### Card 41
**Q:** What file permissions should startup files have?
**A:** 644 (readable by all, writable by owner) or 600 (readable/writable by owner only) for better security

### Card 42
**Q:** Why should you avoid hardcoded paths in startup files?
**A:** Reduces portability and can break when directory structures change. Use variables like $HOME instead

### Card 43
**Q:** What is the principle for PATH organization?
**A:** Place trusted directories first, never include current directory (.), avoid world-writable directories

### Card 44
**Q:** How should you handle sensitive information like API keys in startup files?
**A:** Don't store them in startup files. Use dedicated credential management, encrypted keystores, or separate files with proper permissions.

### Card 45
**Q:** What's the best practice for testing startup file changes?
**A:** Test in a separate terminal session or with a test user account before making system-wide changes.

---

## Troubleshooting

### Card 46
**Q:** How do you start a bash shell without reading any startup files?
**A:** `bash --noprofile --norc` - starts a clean session without reading startup files

### Card 47
**Q:** How do you test a specific startup file?
**A:** `bash --rcfile ~/.test_bashrc` - starts bash with a specific configuration file

### Card 48
**Q:** What command shows all currently defined aliases?
**A:** `alias` (with no arguments) - displays all current aliases

### Card 49
**Q:** How do you see all shell functions that are currently defined?
**A:** `declare -f` - shows all defined functions

### Card 50
**Q:** What command shows the current umask value?
**A:** `umask` (with no arguments) - displays current umask in octal notation

---

## Review Notes
- **Difficulty level**: Medium
- **Last reviewed**: [Date]
- **Next review**: [Date]
- **Topics needing more practice**: 
  - Startup file execution order
  - umask calculations
  - Shell function vs alias usage
  - Environment variable scoping
  - Troubleshooting environment issues

---
