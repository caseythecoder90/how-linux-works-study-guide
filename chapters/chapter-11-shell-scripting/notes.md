# Chapter 11: Shell Scripting - Notes

## Chapter Overview
Shell scripting allows you to automate repetitive tasks, create custom tools, and build complex workflows using simple text files that contain shell commands. This chapter focuses on Bourne shell scripting, which is portable across Unix-like systems and forms the foundation for system automation.

## Key Concepts

### What Shell Scripts Do Best
**Definition**: Shell scripts excel at manipulating files, running commands, and automating system administration tasks.

**Best use cases**:
- Batch file processing
- System administration automation
- Simple data manipulation
- Command pipeline creation
- Environment setup

**When NOT to use shell scripts**:
- Complex string manipulation
- Arithmetic computations
- Database operations
- Large applications
- GUI applications

**Examples**:
```bash
# Good for shell scripts
#!/bin/bash
for file in *.log; do
    gzip "$file"
    mv "$file.gz" /archive/
done

# Better suited for Python/Perl
# Complex regex processing, data parsing, etc.
```

---

### Quoting and Literals

**Definition**: Quoting controls how the shell interprets special characters and prevents unwanted expansions.

**Why it matters**: Without proper quoting, variables and special characters may be interpreted incorrectly.

**Three types of quoting**:
1. **Single quotes (')'**: Preserve everything literally
2. **Double quotes (")"**: Allow variable substitution
3. **Backslash (\)**: Escape individual characters

**Examples**:
```bash
# Variable expansion examples
name="John"
echo $name        # Output: John
echo '$name'      # Output: $name (literal)
echo "$name"      # Output: John
echo \$name       # Output: $name (escaped)

# Special character handling
echo '$100'       # Output: $100 (literal)
echo "$100"       # Output: 00 (expands $1 which is empty)
echo "\$100"      # Output: $100 (escaped)

# Glob pattern protection
echo '*.txt'      # Output: *.txt (literal)
echo "*.txt"      # Output: *.txt (literal in quotes)
echo *.txt        # Output: file1.txt file2.txt (expanded)
```

**Complex quoting example**:
```bash
# Original problematic string: this isn't a forward slash: \
# Solution: 'this isn'\''t a forward slash: \'
# Breakdown: 'this isn' + \' + 't a forward slash: \'
```

---

### Special Variables

**Definition**: Pre-defined variables that provide access to script arguments, metadata, and execution status.

**Core special variables**:

#### Positional Parameters ($1, $2, etc.)
```bash
#!/bin/bash
# Script: show_args.sh
echo "Script name: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "Third arg: $3"

# Usage: ./show_args.sh hello world test
# Output:
# Script name: ./show_args.sh
# First arg: hello
# Second arg: world
# Third arg: test
```

#### Argument Count ($#)
```bash
#!/bin/bash
echo "Number of arguments: $#"

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi
```

#### All Arguments ($@)
```bash
#!/bin/bash
# Pass all arguments to another command
echo "Running: grep $@ /var/log/syslog"
grep "$@" /var/log/syslog
```

#### Process ID ($$)
```bash
#!/bin/bash
echo "This script's PID: $$"
# Useful for creating unique temporary files
temp_file="/tmp/script_$$_temp"
```

#### Exit Code ($?)
```bash
#!/bin/bash
ls /nonexistent 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Command failed"
fi

# Better approach - test directly
if ! ls /nonexistent 2>/dev/null; then
    echo "Command failed"
fi
```

#### The shift Command
```bash
#!/bin/bash
# Process all arguments one by one
while [ $# -gt 0 ]; do
    echo "Processing: $1"
    shift
done
```

---

### Exit Codes

**Definition**: Numeric values that indicate whether a command or script succeeded or failed.

**Why it matters**: Exit codes enable error handling and conditional execution in scripts and command chains.

**Standard convention**:
- **0**: Success
- **1-255**: Various error conditions
- **Common codes**: 1 (general error), 2 (misuse), 126 (not executable), 127 (command not found)

**Examples**:
```bash
#!/bin/bash

# Set exit code explicitly
if [ ! -f "$1" ]; then
    echo "Error: File $1 not found" >&2
    exit 1
fi

# Check exit codes
cp file1 file2
if [ $? -eq 0 ]; then
    echo "Copy successful"
else
    echo "Copy failed"
fi

# Using exit codes in conditions
if command_that_might_fail; then
    echo "Success"
else
    echo "Failed with exit code: $?"
fi
```

---

### Conditional Statements

**Definition**: Control structures that execute different code paths based on conditions.

**Basic if statement**:
```bash
#!/bin/bash
if [ condition ]; then
    # commands
fi
```

**if/else statement**:
```bash
#!/bin/bash
if [ condition ]; then
    # commands if true
else
    # commands if false
fi
```

**if/elif/else statement**:
```bash
#!/bin/bash
if [ condition1 ]; then
    # commands if condition1 true
elif [ condition2 ]; then
    # commands if condition2 true
else
    # commands if all conditions false
fi
```

**Test operators**:
```bash
# Numeric comparisons
[ $a -eq $b ]    # equal
[ $a -ne $b ]    # not equal
[ $a -gt $b ]    # greater than
[ $a -ge $b ]    # greater than or equal
[ $a -lt $b ]    # less than
[ $a -le $b ]    # less than or equal

# String comparisons
[ "$str1" = "$str2" ]     # equal
[ "$str1" != "$str2" ]    # not equal
[ -z "$str" ]             # string is empty
[ -n "$str" ]             # string is not empty

# File tests
[ -f "file" ]      # file exists and is regular file
[ -d "dir" ]       # directory exists
[ -r "file" ]      # file is readable
[ -w "file" ]      # file is writable
[ -x "file" ]      # file is executable
[ -s "file" ]      # file exists and is not empty
```

**Practical example**:
```bash
#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found"
    exit 1
fi

if [ -r "$1" ]; then
    echo "File '$1' is readable"
else
    echo "Error: Cannot read file '$1'"
    exit 1
fi
```

---

### Loops

**Definition**: Control structures that repeat commands multiple times.

#### for Loops
```bash
# Loop over list of items
for item in item1 item2 item3; do
    echo "Processing: $item"
done

# Loop over files
for file in *.txt; do
    echo "Found text file: $file"
done

# Loop over arguments
for arg in "$@"; do
    echo "Argument: $arg"
done

# C-style for loop (bash only)
for ((i=1; i<=10; i++)); do
    echo "Number: $i"
done
```

#### while Loops
```bash
# Basic while loop
counter=1
while [ $counter -le 5 ]; do
    echo "Count: $counter"
    counter=$((counter + 1))
done

# Reading lines from file
while read line; do
    echo "Line: $line"
done < input.txt

# Reading user input
while true; do
    echo -n "Enter command (quit to exit): "
    read cmd
    if [ "$cmd" = "quit" ]; then
        break
    fi
    echo "You entered: $cmd"
done
```

**Practical loop examples**:
```bash
#!/bin/bash
# Backup all .conf files
for config in /etc/*.conf; do
    if [ -f "$config" ]; then
        cp "$config" "/backup/$(basename "$config").bak"
        echo "Backed up: $config"
    fi
done

# Monitor disk usage
while true; do
    usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $usage -gt 90 ]; then
        echo "WARNING: Disk usage at ${usage}%"
    fi
    sleep 60
done
```

---

### Functions

**Definition**: Reusable blocks of code that can accept parameters and return values.

**Basic function syntax**:
```bash
# Method 1: function keyword
function function_name() {
    # commands
}

# Method 2: without function keyword (preferred)
function_name() {
    # commands
}
```

**Functions with parameters**:
```bash
#!/bin/bash
greet() {
    local name=$1
    local time=$2
    echo "Good $time, $name!"
}

# Call the function
greet "Alice" "morning"
greet "Bob" "evening"
```

**Functions with return values**:
```bash
#!/bin/bash
# Return via echo (capture with command substitution)
get_file_count() {
    local dir=$1
    echo $(ls -1 "$dir" | wc -l)
}

# Return via exit status
file_exists() {
    local file=$1
    [ -f "$file" ]
    return $?  # 0 if true, 1 if false
}

# Usage
count=$(get_file_count "/tmp")
echo "Files in /tmp: $count"

if file_exists "/etc/passwd"; then
    echo "Password file exists"
fi
```

**Local variables**:
```bash
#!/bin/bash
global_var="I'm global"

my_function() {
    local local_var="I'm local to this function"
    global_var="Modified by function"
    echo "Inside function: $local_var"
}

echo "Before: $global_var"
my_function
echo "After: $global_var"
# local_var is not accessible here
```

---

### Reading User Input

**Definition**: Interactive scripts that prompt users for input during execution.

**Basic read usage**:
```bash
#!/bin/bash
echo -n "Enter your name: "
read name
echo "Hello, $name!"
```

**Reading with prompts**:
```bash
#!/bin/bash
# Read with built-in prompt
read -p "Enter filename: " filename
read -p "Enter your age: " age

echo "File: $filename, Age: $age"
```

**Reading passwords (hidden input)**:
```bash
#!/bin/bash
read -s -p "Enter password: " password
echo  # New line after hidden input
echo "Password length: ${#password}"
```

**Input validation example**:
```bash
#!/bin/bash
while true; do
    read -p "Enter a number (1-10): " num
    if [[ "$num" =~ ^[1-9]|10$ ]]; then
        echo "Valid number: $num"
        break
    else
        echo "Invalid input. Please enter a number between 1 and 10."
    fi
done
```

---

### Including Other Files

**Definition**: Sourcing external files to include their variables and functions in the current script.

**Syntax**:
```bash
# Include another file
. config.sh
# or
source config.sh
```

**Example structure**:
```bash
# config.sh
#!/bin/bash
DATABASE_HOST="localhost"
DATABASE_PORT="5432"
LOG_LEVEL="INFO"

log_message() {
    echo "[$(date)] $1"
}

# main.sh
#!/bin/bash
. ./config.sh

log_message "Connecting to $DATABASE_HOST:$DATABASE_PORT"
log_message "Log level set to $LOG_LEVEL"
```

---

## Advanced Topics

### Case Statements
```bash
#!/bin/bash
read -p "Enter a choice (a/b/c): " choice

case $choice in
    a|A)
        echo "You chose A"
        ;;
    b|B)
        echo "You chose B"
        ;;
    c|C)
        echo "You chose C"
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
```

### Arrays (Bash)
```bash
#!/bin/bash
# Declare array
fruits=("apple" "banana" "orange")

# Access elements
echo "First: ${fruits[0]}"
echo "All: ${fruits[@]}"
echo "Count: ${#fruits[@]}"

# Loop through array
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done
```

### Command Substitution
```bash
#!/bin/bash
# Old style (backticks)
current_date=`date`

# New style (preferred)
current_date=$(date)
file_count=$(ls | wc -l)
hostname=$(hostname)

echo "Today is $current_date"
echo "Files in current directory: $file_count"
```

---

## Best Practices

### Script Structure
```bash
#!/bin/bash
# Script: backup_files.sh
# Purpose: Backup important configuration files
# Author: Your Name
# Date: 2024-01-01

# Exit on any error
set -e

# Configuration
BACKUP_DIR="/backup"
SOURCE_DIRS="/etc /home"

# Functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

create_backup() {
    local source=$1
    local backup_name="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log_message "Creating backup of $source"
    tar -czf "$BACKUP_DIR/$backup_name" "$source"
    log_message "Backup completed: $backup_name"
}

# Main script
log_message "Starting backup process"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    log_message "Created backup directory: $BACKUP_DIR"
fi

# Perform backups
for dir in $SOURCE_DIRS; do
    if [ -d "$dir" ]; then
        create_backup "$dir"
    else
        log_message "Warning: Directory $dir not found"
    fi
done

log_message "Backup process completed"
```

### Error Handling
```bash
#!/bin/bash
# Enable strict error handling
set -euo pipefail

# Function for error messages
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check prerequisites
command -v rsync >/dev/null 2>&1 || error_exit "rsync not installed"
[ -d "$SOURCE_DIR" ] || error_exit "Source directory not found: $SOURCE_DIR"
```

---

## Summary

### Key Takeaways
1. **Shell scripts excel at automation**: File manipulation, command execution, and system administration
2. **Quoting is critical**: Use single quotes for literals, double quotes for variable expansion
3. **Special variables provide context**: $1-$9 for arguments, $# for count, $@ for all args, $? for exit codes
4. **Exit codes enable error handling**: 0 for success, non-zero for errors
5. **Functions improve organization**: Use local variables and proper parameter handling
6. **Input validation is essential**: Always validate user input and command success

### Essential Patterns to Remember
```bash
# Shebang and error handling
#!/bin/bash
set -euo pipefail

# Argument checking
[ $# -eq 0 ] && { echo "Usage: $0 <arg>"; exit 1; }

# File existence check
[ -f "$file" ] || { echo "File not found: $file"; exit 1; }

# Function with local variables
function_name() {
    local param=$1
    # function body
}

# Loop with error checking
for file in "$@"; do
    if [ -f "$file" ]; then
        process_file "$file"
    else
        echo "Skipping non-existent file: $file" >&2
    fi
done
```

---

## Personal Notes
- Always test scripts in a safe environment before production use
- Remember the difference between `[ ]` and `[[ ]]` (latter is bash-specific but more powerful)
- Use `shellcheck` tool to validate scripts for common errors
- Keep scripts simple - complex logic belongs in Python/Perl
- Document your scripts with comments explaining the purpose and usage