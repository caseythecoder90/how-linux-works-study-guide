#!/bin/bash
# Complete bashrc example with best practices
# This file demonstrates a well-structured user bashrc

# ============================================================================
# BASIC SHELL SETTINGS
# ============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth:erasedups

# Set history length
HISTSIZE=1000
HISTFILESIZE=2000

# Append to the history file, don't overwrite it
shopt -s histappend

# Check the window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# Enable recursive globbing with **
shopt -s globstar 2>/dev/null

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

# Core applications
export EDITOR=vim
export PAGER=less
export BROWSER=firefox

# Development tools
export JAVA_HOME=/usr/lib/jvm/default-java
export GOPATH="$HOME/go"

# Pager options
export LESS="-R -M -i -j5"
# -R: Raw control characters (colors)
# -M: Verbose prompt
# -i: Case-insensitive search
# -j5: Target line for search results

# Grep colors
export GREP_COLOR='1;31'
export GREP_OPTIONS='--color=auto'

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

# Function to safely add directories to PATH
add_to_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
    fi
}

# Add user directories
add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"

# Add development tools if they exist
add_to_path "$GOPATH/bin"
add_to_path "$HOME/.cargo/bin"  # Rust
add_to_path "$HOME/.gem/ruby/2.7.0/bin"  # Ruby gems

# ============================================================================
# PROMPT CONFIGURATION
# ============================================================================

# Check if we can use colors
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
else
    color_prompt=
fi

# Git prompt support (if available)
if [ -f /usr/share/git/completion/git-prompt.sh ]; then
    source /usr/share/git/completion/git-prompt.sh
    export GIT_PS1_SHOWDIRTYSTATE=1
    export GIT_PS1_SHOWSTASHSTATE=1
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWUPSTREAM="auto"
fi

# Set colorful PS1 with git branch support
if [ "$color_prompt" = yes ]; then
    if type __git_ps1 >/dev/null 2>&1; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " \[\033[01;33m\](%s)\[\033[00m\]")\$ '
    else
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    fi
else
    PS1='\u@\h:\w\$ '
fi

# Set terminal title
case "$TERM" in
xterm*|rxvt*|screen*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# ============================================================================
# COMPLETION SETTINGS
# ============================================================================

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ============================================================================
# ALIASES
# ============================================================================

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -altr'  # Sort by time, newest last
alias lh='ls -alh'   # Human readable sizes

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# System information
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias psg='ps aux | grep'
alias ports='netstat -tulanp'

# Network utilities
alias ping='ping -c 5'
alias fastping='ping -c 100 -s.2'
alias wget='wget -c'  # Resume downloads

# Text processing
alias grep='grep --color=auto'
alias less='less -R'  # Handle colors properly

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'

# Python utilities
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'

# ============================================================================
# FUNCTIONS
# ============================================================================

# Create directory and change into it
mkcd() {
    if [ $# -ne 1 ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ $# -ne 1 ]; then
        echo "Usage: extract <archive>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.Z)              uncompress "$1" ;;
        *.7z)             7z x "$1" ;;
        *.deb)            ar x "$1" ;;
        *.tar.lz)         lzip -d "$1" ;;
        *.lz)             lzip -d "$1" ;;
        *)                echo "Error: '$1' cannot be extracted via extract()" ;;
    esac
}

# Create a backup of a file with timestamp
backup() {
    if [ $# -ne 1 ]; then
        echo "Usage: backup <file>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: '$1' does not exist"
        return 1
    fi
    
    local backup_name="${1}.$(date +%Y%m%d_%H%M%S).bak"
    cp "$1" "$backup_name" && echo "Backup created: $backup_name"
}

# Find files containing text
findtext() {
    if [ $# -lt 1 ]; then
        echo "Usage: findtext <pattern> [directory]"
        return 1
    fi
    
    local pattern="$1"
    local dir="${2:-.}"
    
    grep -r "$pattern" "$dir" --include="*.txt" --include="*.md" --include="*.py" --include="*.sh" --include="*.conf" 2>/dev/null
}

# Show disk usage of current directory
dusage() {
    du -sh * 2>/dev/null | sort -hr
}

# Quick calculator
calc() {
    if [ $# -eq 0 ]; then
        bc -l
    else
        echo "$*" | bc -l
    fi
}

# Weather function (requires curl)
weather() {
    local city="${1:-}"
    if [ -n "$city" ]; then
        curl -s "wttr.in/$city?format=3"
    else
        curl -s "wttr.in/?format=3"
    fi
}

# Process management helper
psgrep() {
    if [ $# -ne 1 ]; then
        echo "Usage: psgrep <pattern>"
        return 1
    fi
    ps aux | head -1  # Show header
    ps aux | grep "$1" | grep -v grep
}

# Network information
myip() {
    echo "Local IP addresses:"
    ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'
    echo
    echo "Public IP address:"
    curl -s ifconfig.me 2>/dev/null || echo "Unable to determine public IP"
}

# System load information
loadavg() {
    echo "System Load Average:"
    uptime
    echo
    echo "Memory Usage:"
    free -h
    echo
    echo "Disk Usage:"
    df -h | grep -E '^/dev/'
}

# Clean temporary files
cleantemp() {
    echo "Cleaning temporary files..."
    
    # Clean user temp files (be careful!)
    find "$HOME" -name "*.tmp" -type f -mtime +7 -delete 2>/dev/null
    find "$HOME" -name "*~" -type f -mtime +7 -delete 2>/dev/null
    
    # Clean common cache directories
    if [ -d "$HOME/.cache" ]; then
        find "$HOME/.cache" -type f -mtime +30 -delete 2>/dev/null
    fi
    
    echo "Cleanup complete."
}

# Git repository status
gstatus() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "=== Git Repository Status ==="
        echo "Branch: $(git branch --show-current)"
        echo "Remote: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
        echo
        git status --short
        echo
        echo "Recent commits:"
        git log --oneline -5
    else
        echo "Not in a git repository"
    fi
}

# ============================================================================
# DEVELOPMENT ENVIRONMENT SETUP
# ============================================================================

# Node.js version manager (lazy loading)
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    # Lazy load nvm to improve shell startup time
    nvm() {
        unset -f nvm
        source "$HOME/.nvm/nvm.sh"
        nvm "$@"
    }
fi

# Ruby version manager
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
fi

# Python virtual environment helper
vactivate() {
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f "env/bin/activate" ]; then
        source env/bin/activate
    elif [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    else
        echo "No virtual environment found in current directory"
        return 1
    fi
}

# ============================================================================
# SYSTEM-SPECIFIC CONFIGURATIONS
# ============================================================================

# macOS specific settings
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Use GNU tools if available (installed via Homebrew)
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    
    # macOS specific aliases
    alias ls='ls -G'  # Color support for macOS ls
    alias finder='open -a Finder'
    alias preview='open -a Preview'
fi

# Linux specific settings
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Set LS_COLORS for better file type visualization
    if [ -x /usr/bin/dircolors ]; then
        eval "$(dircolors -b)"
    fi
fi

# ============================================================================
# SECURITY SETTINGS
# ============================================================================

# Set restrictive umask
umask 022

# Clear sensitive history on exit (uncomment if needed)
# trap 'history -c' EXIT

# Timeout for inactive shells (in seconds)
# export TMOUT=1800

# ============================================================================
# CUSTOM USER CONFIGURATIONS
# ============================================================================

# Load additional configurations if they exist
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

if [ -f ~/.bash_local ]; then
    source ~/.bash_local
fi

if [ -f ~/.bash_work ]; then
    source ~/.bash_work
fi

# ============================================================================
# FINAL SETUP
# ============================================================================

# Clean up functions
unset -f add_to_path

# Welcome message (only for interactive shells)
if [[ $- == *i* ]]; then
    echo "Welcome back, $USER!"
    echo "Today is $(date '+%A, %B %d, %Y at %I:%M %p')"
    
    # Show system info on login
    if command -v neofetch >/dev/null 2>&1; then
        neofetch
    elif command -v screenfetch >/dev/null 2>&1; then
        screenfetch
    else
        echo "System: $(uname -sr)"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    fi
fi

# ============================================================================
# END OF BASHRC
# ============================================================================
