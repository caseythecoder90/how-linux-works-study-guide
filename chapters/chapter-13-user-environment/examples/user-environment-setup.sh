#!/bin/bash
# User environment setup script
# This script helps set up a proper user environment with best practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Backup existing files
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# Create directories
create_directories() {
    log_info "Creating user directories..."
    
    local dirs=(
        "$HOME/bin"
        "$HOME/.local/bin"
        "$HOME/.config"
        "$HOME/scripts"
        "$HOME/projects"
        "$HOME/tmp"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
}

# Setup bashrc
setup_bashrc() {
    log_info "Setting up .bashrc..."
    
    backup_file "$HOME/.bashrc"
    
    cat > "$HOME/.bashrc" << 'EOF'
#!/bin/bash
# User-specific .bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Shell options
shopt -s checkwinsize
shopt -s globstar 2>/dev/null

# Environment variables
export EDITOR=vim
export PAGER=less
export LESS="-R -M -i -j5"

# PATH management
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Load aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# umask
umask 022
EOF

    log_success "Created .bashrc"
}

# Setup bash_profile
setup_bash_profile() {
    log_info "Setting up .bash_profile..."
    
    backup_file "$HOME/.bash_profile"
    
    cat > "$HOME/.bash_profile" << 'EOF'
#!/bin/bash
# User-specific .bash_profile

# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF

    log_success "Created .bash_profile"
}

# Setup aliases
setup_aliases() {
    log_info "Setting up aliases..."
    
    backup_file "$HOME/.bash_aliases"
    
    cat > "$HOME/.bash_aliases" << 'EOF'
#!/bin/bash
# User-specific aliases

# Color support
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
alias lt='ls -altr'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# System info
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'

# Network
alias ping='ping -c 5'
alias ports='netstat -tulanp'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Utility functions
mkcd() { mkdir -p "$1" && cd "$1"; }
backup() { cp "$1" "$1.$(date +%Y%m%d_%H%M%S).bak"; }
EOF

    log_success "Created .bash_aliases"
}

# Setup gitconfig
setup_gitconfig() {
    log_info "Setting up git configuration..."
    
    if ! git config --global user.name >/dev/null 2>&1; then
        read -p "Enter your full name for git: " git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        read -p "Enter your email for git: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Set up useful git defaults
    git config --global init.defaultBranch main
    git config --global core.editor vim
    git config --global color.ui auto
    git config --global push.default simple
    git config --global pull.rebase false
    
    log_success "Git configuration complete"
}

# Setup vim configuration
setup_vim() {
    log_info "Setting up basic vim configuration..."
    
    backup_file "$HOME/.vimrc"
    
    cat > "$HOME/.vimrc" << 'EOF'
" Basic vim configuration
set number
set relativenumber
set showcmd
set cursorline
set wildmenu
set showmatch
set incsearch
set hlsearch

" Indentation
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" Colors and appearance
syntax enable
set background=dark

" Useful mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>h :nohlsearch<CR>
EOF

    log_success "Created .vimrc"
}

# Setup ssh directory
setup_ssh() {
    log_info "Setting up SSH directory..."
    
    if [ ! -d "$HOME/.ssh" ]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        log_success "Created .ssh directory"
    else
        log_info "SSH directory already exists"
    fi
    
    # Create config file if it doesn't exist
    if [ ! -f "$HOME/.ssh/config" ]; then
        touch "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        log_success "Created SSH config file"
    fi
}

# Set file permissions
set_permissions() {
    log_info "Setting proper file permissions..."
    
    chmod 644 "$HOME/.bashrc" 2>/dev/null || true
    chmod 644 "$HOME/.bash_profile" 2>/dev/null || true
    chmod 644 "$HOME/.bash_aliases" 2>/dev/null || true
    chmod 644 "$HOME/.vimrc" 2>/dev/null || true
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
    
    log_success "File permissions set"
}

# Create useful scripts
create_scripts() {
    log_info "Creating utility scripts..."
    
    # System info script
    cat > "$HOME/bin/sysinfo" << 'EOF'
#!/bin/bash
# System information script

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(uname -sr)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo
echo "=== CPU Info ==="
lscpu | grep -E "Model name|CPU\(s\):|Core\(s\) per socket" 2>/dev/null || echo "CPU info not available"
echo
echo "=== Memory Info ==="
free -h
echo
echo "=== Disk Usage ==="
df -h | grep -E '^/dev/'
echo
echo "=== Network Interfaces ==="
ip addr show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//' 2>/dev/null || echo "Network info not available"
EOF

    chmod +x "$HOME/bin/sysinfo"
    log_success "Created sysinfo script"
    
    # Backup script
    cat > "$HOME/bin/quickbackup" << 'EOF'
#!/bin/bash
# Quick backup script for important files

BACKUP_DIR="$HOME/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup important dotfiles
cp ~/.bashrc "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.bash_profile "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.bash_aliases "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.vimrc "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.gitconfig "$BACKUP_DIR/" 2>/dev/null || true

# Backup SSH config (not keys!)
if [ -f ~/.ssh/config ]; then
    cp ~/.ssh/config "$BACKUP_DIR/ssh_config" 2>/dev/null || true
fi

echo "Backup complete: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
EOF

    chmod +x "$HOME/bin/quickbackup"
    log_success "Created quickbackup script"
    
    # Environment check script
    cat > "$HOME/bin/envcheck" << 'EOF'
#!/bin/bash
# Environment validation script

echo "=== Environment Check ==="
echo

# Check shell
echo "Current shell: $SHELL"
echo "Bash version: $BASH_VERSION"
echo

# Check PATH
echo "PATH components:"
echo "$PATH" | tr ':' '\n' | nl
echo

# Check important environment variables
echo "Important environment variables:"
echo "HOME: $HOME"
echo "USER: $USER"
echo "EDITOR: ${EDITOR:-not set}"
echo "PAGER: ${PAGER:-not set}"
echo "TERM: ${TERM:-not set}"
echo

# Check umask
echo "Current umask: $(umask)"
echo

# Check aliases
echo "Custom aliases count: $(alias | wc -l)"
echo

# Check functions
echo "Custom functions count: $(declare -f | grep -c '^[a-zA-Z]')"
echo

# Check startup files
echo "Startup files:"
for file in ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/.profile; do
    if [ -f "$file" ]; then
        echo "  ✓ $file ($(wc -l < "$file") lines)"
    else
        echo "  ✗ $file (missing)"
    fi
done
EOF

    chmod +x "$HOME/bin/envcheck"
    log_success "Created envcheck script"
}

# Test environment
test_environment() {
    log_info "Testing environment setup..."
    
    # Test if PATH includes user directories
    if [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
        log_success "$HOME/bin is in PATH"
    else
        log_warning "$HOME/bin is not in PATH - you may need to restart your shell"
    fi
    
    # Test if aliases are working
    if alias ll >/dev/null 2>&1; then
        log_success "Aliases are loaded"
    else
        log_warning "Aliases not loaded - restart shell or source .bashrc"
    fi
    
    # Test essential commands
    local commands=("git" "vim" "curl" "wget")
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "$cmd is available"
        else
            log_warning "$cmd is not installed"
        fi
    done
}

# Generate summary report
generate_report() {
    log_info "Generating setup summary..."
    
    cat > "$HOME/environment_setup_report.txt" << EOF
User Environment Setup Report
$(date)
========================================

Files created/modified:
- ~/.bashrc
- ~/.bash_profile
- ~/.bash_aliases
- ~/.vimrc
- ~/.ssh/config (if needed)

Directories created:
- ~/bin
- ~/.local/bin
- ~/.config
- ~/scripts
- ~/projects
- ~/tmp

Scripts installed:
- ~/bin/sysinfo
- ~/bin/quickbackup
- ~/bin/envcheck

Next steps:
1. Restart your shell or run: source ~/.bashrc
2. Test the setup with: envcheck
3. Customize further as needed
4. Consider installing additional tools:
   - htop (better process viewer)
   - tree (directory tree display)
   - neofetch (system info display)
   - tmux (terminal multiplexer)

To verify your setup:
- Run 'll' to test aliases
- Run 'sysinfo' to test custom scripts
- Check that tab completion works
- Verify your prompt shows colors

Backup files are saved with .backup.YYYYMMDD_HHMMSS extension
EOF

    log_success "Report saved to ~/environment_setup_report.txt"
}

# Main execution
main() {
    echo "=== User Environment Setup Script ==="
    echo "This script will set up a proper user environment with best practices."
    echo
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    create_directories
    setup_bashrc
    setup_bash_profile
    setup_aliases
    setup_gitconfig
    setup_vim
    setup_ssh
    set_permissions
    create_scripts
    test_environment
    generate_report
    
    echo
    log_success "Environment setup complete!"
    log_info "Please restart your shell or run: source ~/.bashrc"
    log_info "Check the report at: ~/environment_setup_report.txt"
    echo
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
