# Chapter 13: User Environments - Quick Reference

## Essential Commands

### Environment Management
```bash
export VAR=value             # Export variable to child processes
env                          # Show all environment variables
env | sort                   # Show sorted environment variables
echo $VAR                    # Display specific variable value
unset VAR                    # Remove variable
printenv                     # Alternative to env
set                          # Show all shell variables and functions
```

### Alias Management
```bash
alias name='command'         # Create alias
alias ll='ls -l'            # Example alias
unalias name                # Remove specific alias
unalias -a                  # Remove all aliases
alias                       # Show all aliases
type command                # Show if command is alias, function, or binary
```

### Shell Configuration
```bash
source ~/.bashrc            # Reload bashrc
. ~/.bashrc                 # Same as source (POSIX)
bash --noprofile --norc     # Start bash without startup files
bash --rcfile ~/.test       # Use specific config file
bash -n ~/.bashrc          # Check syntax without execution
bash -x ~/.bashrc          # Trace execution for debugging
```

### Function Management
```bash
declare -f                  # Show all functions
declare -f function_name    # Show specific function
unset function_name         # Remove function
type function_name          # Show function definition
```

---

## Important Files & Directories

| Path | Purpose |
|------|---------|
| `~/.bashrc` | Bash runtime configuration (non-login shells) |
| `~/.bash_profile` | Bash login shell configuration |
| `~/.profile` | Generic shell profile (POSIX compliant) |
| `~/.bash_login` | Alternative bash login file |
| `~/.bash_aliases` | Separate file for aliases |
| `~/.tcshrc` | Tcsh shell configuration |
| `~/.cshrc` | C shell configuration |
| `/etc/profile` | System-wide shell defaults |
| `/etc/bash.bashrc` | System-wide bash configuration |
| `/etc/skel/` | Template files for new users |
| `/etc/environment` | System-wide environment variables (Ubuntu/Debian) |

---

## Bash Startup File Execution Order

### Login Shells
```
1. /etc/profile (system-wide)
2. First found from:
   - ~/.bash_profile
   - ~/.bash_login  
   - ~/.profile
```

### Non-login Interactive Shells
```
1. /etc/bash.bashrc (if exists)
2. ~/.bashrc
```

### Recommended Strategy
```bash
# ~/.bash_profile
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
```

---

## Environment Variables

### Essential System Variables
```bash
HOME=/home/username          # User home directory
PATH=/usr/local/bin:/usr/bin:/bin  # Command search path
SHELL=/bin/bash              # User's login shell
USER=username                # Current username
PWD=/current/directory       # Current working directory
OLDPWD=/previous/directory   # Previous working directory
```

### Application Preferences
```bash
EDITOR=vim                   # Default text editor
PAGER=less                   # Default pager
BROWSER=firefox              # Default web browser
TERM=xterm-256color          # Terminal type
LANG=en_US.UTF-8            # System locale
```

### History Control
```bash
HISTFILE=~/.bash_history     # History file location
HISTSIZE=1000               # Commands in memory
HISTFILESIZE=2000           # Commands in history file
HISTCONTROL=ignoreboth      # Ignore duplicates and space-prefixed
```

---

## Prompt Configuration

### PS1 Escape Sequences
| Sequence | Meaning |
|----------|---------|
| `\u` | Username |
| `\h` | Hostname (short) |
| `\H` | Hostname (full) |
| `\w` | Current working directory |
| `\W` | Basename of current directory |
| `\$` | $ for user, # for root |
| `\t` | Time (24-hour HH:MM:SS) |
| `\T` | Time (12-hour HH:MM:SS) |
| `\d` | Date (Weekday Month Date) |
| `\n` | Newline |
| `\[` | Begin non-printing sequence |
| `\]` | End non-printing sequence |

### Common Prompt Examples
```bash
# Simple
PS1='$ '

# User@host with directory
PS1='\u@\h:\w$ '

# Colorful prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# With git branch (requires git prompt support)
PS1='\u@\h:\w$(__git_ps1 " (%s)")$ '
```

---

## umask Reference

### Common umask Values
| umask | File Perms | Dir Perms | Use Case |
|-------|------------|-----------|----------|
| 022 | 644 (rw-r--r--) | 755 (rwxr-xr-x) | General use, allows others to read |
| 027 | 640 (rw-r-----) | 750 (rwxr-x---) | Group can read, others cannot |
| 077 | 600 (rw-------) | 700 (rwx------) | Private, owner only |
| 002 | 664 (rw-rw-r--) | 775 (rwxrwxr-x) | Group writable |

### umask Calculation
```
Default max permissions - umask = Resulting permissions
Files: 666 - 022 = 644
Dirs:  777 - 022 = 755
```

---

## Aliases vs Functions

### When to Use Aliases
```bash
# Simple command shortcuts
alias ll='ls -l'
alias la='ls -la'
alias grep='grep --color=auto'
alias ..='cd ..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```

### When to Use Functions
```bash
# Complex logic
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Parameter handling
backup() {
    cp "$1" "$1.$(date +%Y%m%d_%H%M%S).bak"
}

# Error checking
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.gz) tar xzf "$1" ;;
            *.zip)    unzip "$1" ;;
            *)        echo "Unsupported format" ;;
        esac
    else
        echo "File not found: $1"
    fi
}
```

---

## Startup File Best Practices

### Do's
- Keep files simple and well-documented
- Test thoroughly before deploying
- Use conditional logic for optional features
- Include descriptive comments
- Use variables instead of hardcoded paths
- Set reasonable defaults

### Don'ts
- Don't include graphical commands
- Don't set DISPLAY variable
- Don't set terminal type
- Don't include commands that print output
- Don't set LD_LIBRARY_PATH
- Don't include current directory (.) in PATH
- Don't store sensitive information

---

## Common Patterns

### Conditional PATH Addition
```bash
# Add directory to PATH if it exists and isn't already there
add_to_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
    fi
}

add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"
```

### Interactive Shell Check
```bash
# Only for interactive shells
case $- in
    *i*) 
        # Interactive shell code here
        ;;
    *)
        # Non-interactive shell
        return
        ;;
esac
```

### Safe Sourcing
```bash
# Source file only if it exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```

---

## Troubleshooting Commands

| Problem | Solution |
|---------|----------|
| Syntax errors | `bash -n ~/.bashrc` |
| Execution tracing | `bash -x ~/.bashrc` |
| Clean shell | `bash --noprofile --norc` |
| Test specific file | `bash --rcfile ~/.test` |
| Check current settings | `set -o` |
| Environment dump | `env \| sort` |
| Function list | `declare -f` |
| Variable list | `declare -p` |

---

## Shell Function Templates

### Basic Function
```bash
function_name() {
    # Documentation
    local var="value"
    command "$var"
}
```

### Function with Parameters
```bash
my_function() {
    if [ $# -eq 0 ]; then
        echo "Usage: my_function <arg1> [arg2]"
        return 1
    fi
    
    local arg1="$1"
    local arg2="${2:-default}"
    
    # Function logic here
}
```

### Function with Error Handling
```bash
safe_function() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found" >&2
        return 1
    fi
    
    # Process file
    if command "$file"; then
        echo "Success"
    else
        echo "Error processing file" >&2
        return 1
    fi
}
```

---

## Testing and Debugging

### Quick Tests
```bash
# Test startup file syntax
bash -n ~/.bashrc

# Start with minimal environment
env -i bash --noprofile --norc

# Test specific configuration
cp ~/.bashrc ~/.bashrc.test
# Edit test file
bash --rcfile ~/.bashrc.test
```

### Environment Debugging
```bash
# Show all variables and functions
set | less

# Show only environment variables
env | sort

# Show only exported variables
export | sort

# Show shell options
set -o
```

---

## Security Checklist

- [ ] Remove current directory (.) from PATH
- [ ] Set appropriate umask (022 or 077)
- [ ] Check startup file permissions (644 or 600)
- [ ] Don't store passwords or keys in startup files
- [ ] Use conditional loading for sensitive operations
- [ ] Regularly audit startup files for unnecessary content
- [ ] Test changes in isolated environment first

---
