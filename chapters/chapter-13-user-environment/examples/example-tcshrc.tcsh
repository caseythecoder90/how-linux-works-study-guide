#!/bin/tcsh
# Example .tcshrc configuration file
# This demonstrates tcsh shell configuration

# ============================================================================
# BASIC SHELL SETTINGS
# ============================================================================

# History settings
set history = 1000
set savehist = (1000 merge)
set histdup = erase

# Auto-completion settings
set autolist = ambiguous
set complete = enhance
set autocorrect
set correct = cmd

# Shell behavior
set notify
set noclobber
set ignoreeof

# ============================================================================
# PROMPT CONFIGURATION
# ============================================================================

# Color definitions
set red="%{\033[1;31m%}"
set green="%{\033[1;32m%}"
set yellow="%{\033[1;33m%}"
set blue="%{\033[1;34m%}"
set magenta="%{\033[1;35m%}"
set cyan="%{\033[1;36m%}"
set white="%{\033[1;37m%}"
set end="%{\033[0m%}"

# Set colorful prompt
if ($?tcsh) then
    set prompt = "${green}%n${end}@${blue}%m${end}:${yellow}%c${end}%# "
else
    set prompt = "%n@%m:%c%# "
endif

# Set terminal title
if ($?TERM) then
    switch ($TERM)
        case "xterm*":
        case "rxvt*":
        case "screen*":
            alias cwdcmd 'echo -n "\033]0;${USER}@${HOST}: ${cwd}\007"'
            breaksw
    endsw
endif

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

# Core applications
setenv EDITOR vim
setenv PAGER less
setenv BROWSER firefox

# Development tools
setenv JAVA_HOME /usr/lib/jvm/default-java

# Pager options
setenv LESS "-R -M -i -j5"

# Language and locale
setenv LANG en_US.UTF-8
setenv LC_ALL en_US.UTF-8

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

# Save original PATH
if (!$?ORIGINAL_PATH) then
    setenv ORIGINAL_PATH "$PATH"
endif

# Build new PATH
set path = ()

# Add user directories if they exist
if (-d ~/bin) then
    set path = ($path ~/bin)
endif

if (-d ~/.local/bin) then
    set path = ($path ~/.local/bin)
endif

# Add system directories
set path = ($path /usr/local/bin /usr/bin /bin)

# Add development tools if they exist
if (-d ~/go/bin) then
    set path = ($path ~/go/bin)
endif

if (-d ~/.cargo/bin) then
    set path = ($path ~/.cargo/bin)
endif

# ============================================================================
# ALIASES
# ============================================================================

# ls aliases
alias ls 'ls --color=auto'
alias ll 'ls -alF'
alias la 'ls -A'
alias l 'ls -CF'
alias lt 'ls -altr'
alias lh 'ls -alh'

# Safety aliases
alias rm 'rm -i'
alias cp 'cp -i'
alias mv 'mv -i'
alias ln 'ln -i'

# Navigation aliases
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias cd.. 'cd ..'
alias back 'cd -'

# System information
alias df 'df -h'
alias du 'du -h'
alias free 'free -h'
alias ps 'ps aux'
alias psg 'ps aux | grep'
alias ports 'netstat -tulanp'

# Network utilities
alias ping 'ping -c 5'
alias wget 'wget -c'

# Text processing
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'
alias less 'less -R'

# Git shortcuts
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit'
alias gp 'git push'
alias gl 'git log --oneline'
alias gd 'git diff'
alias gb 'git branch'

# Python utilities
alias py 'python3'
alias pip 'pip3'

# System shortcuts
alias h 'history'
alias j 'jobs'
alias which 'which'
alias cls 'clear'
alias q 'exit'

# Date and time
alias now 'date "+%Y-%m-%d %H:%M:%S"'
alias today 'date "+%Y-%m-%d"'

# Disk usage
alias ducks 'du -cks * | sort -rn | head'

# ============================================================================
# FUNCTIONS (tcsh doesn't have functions, use aliases with parameters)
# ============================================================================

# Make directory and change into it
alias mkcd 'mkdir -p \!* && cd \!*'

# Quick backup
alias backup 'cp \!* \!*.`date +%Y%m%d_%H%M%S`.bak'

# Find files
alias ff 'find . -name "\!*" -print'

# Search in files
alias ftext 'grep -r "\!*" .'

# Show directory tree (if tree is available)
if (-X tree) then
    alias tree 'tree'
else
    alias tree 'find . -type d | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'
endif

# Quick system info
alias sysinfo 'echo "=== System Info ==="; uname -a; echo; echo "=== Uptime ==="; uptime; echo; echo "=== Memory ==="; free -h; echo; echo "=== Disk ==="; df -h'

# Network info
alias myip 'curl -s ifconfig.me && echo'

# Process tree
if (-X pstree) then
    alias pst 'pstree -p'
else
    alias pst 'ps auxf'
endif

# ============================================================================
# COMPLETION SETTINGS
# ============================================================================

# Command completion
complete cd 'p/1/d/'
complete rmdir 'p/1/d/'
complete pushd 'p/1/d/'
complete man 'p/*/c/'
complete which 'p/*/c/'
complete where 'p/*/c/'
complete kill 'p/*/`ps ax | awk \{print\ \$1\}`/'
complete killall 'p/*/`ps ax | awk \{print\ \$5\} | sort | uniq`/'

# File completion for common commands
complete vim 'f:*.{c,h,cpp,hpp,txt,md,py,sh,conf,cfg}:'
complete emacs 'f:*.{c,h,cpp,hpp,txt,md,py,sh,conf,cfg}:'
complete cat 'f:*.{txt,md,log,conf,cfg}:'
complete less 'f:*.{txt,md,log,conf,cfg}:'
complete more 'f:*.{txt,md,log,conf,cfg}:'

# Archive completion
complete tar 'f:*.{tar,tar.gz,tar.bz2,tgz,tbz2}:'
complete unzip 'f:*.zip:'
complete unrar 'f:*.rar:'

# Git completion (basic)
complete git 'p/1/(status add commit push pull clone branch checkout merge log diff)/'

# SSH completion (if .ssh/config exists)
if (-r ~/.ssh/config) then
    complete ssh 'p/1/`grep "^Host " ~/.ssh/config | awk \{print\ \$2\}`/'
    complete scp 'p/1/`grep "^Host " ~/.ssh/config | awk \{print\ \$2\}`/'
endif

# ============================================================================
# SYSTEM-SPECIFIC SETTINGS
# ============================================================================

# Operating system specific settings
switch (`uname`)
    case Linux:
        # Linux specific settings
        alias ls 'ls --color=auto --group-directories-first'
        setenv LS_COLORS 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43'
        breaksw
    case Darwin:
        # macOS specific settings
        alias ls 'ls -G'
        setenv LSCOLORS 'ExFxBxDxCxegedabagacad'
        breaksw
    case FreeBSD:
        # FreeBSD specific settings
        alias ls 'ls -G'
        breaksw
endsw

# ============================================================================
# SECURITY SETTINGS
# ============================================================================

# Set restrictive umask
umask 022

# Clear command history on exit (uncomment if needed)
# alias logout 'history -c; logout'

# Set shell timeout (uncomment if needed)
# set autologout = 30

# ============================================================================
# CUSTOM USER CONFIGURATIONS
# ============================================================================

# Load additional configurations if they exist
if (-r ~/.tcsh_local) then
    source ~/.tcsh_local
endif

if (-r ~/.tcsh_work) then
    source ~/.tcsh_work
endif

# ============================================================================
# FINAL SETUP
# ============================================================================

# Welcome message for interactive shells
if ($?prompt) then
    echo "Welcome back, $USER!"
    echo "Today is `date '+%A, %B %d, %Y at %I:%M %p'`"
    
    # Show system info if commands are available
    if (-X neofetch) then
        neofetch
    else if (-X screenfetch) then
        screenfetch
    else
        echo "System: `uname -sr`"
        if (-X uptime) then
            echo "Uptime: `uptime`"
        endif
    endif
endif

# ============================================================================
# END OF TCSHRC
# ============================================================================
