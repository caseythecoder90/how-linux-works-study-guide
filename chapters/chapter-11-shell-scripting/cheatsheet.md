# Chapter 11: Shell Scripting - Quick Reference

## Script Basics

### Shebang Lines
```bash
#!/bin/sh          # POSIX shell (most portable)
#!/bin/bash        # Bash shell (more features)
#!/usr/bin/env bash # Find bash in PATH
```

### Making Scripts Executable
```bash
chmod +x script.sh      # Make executable
./script.sh            # Run from current directory
bash script.sh         # Run with bash
sh script.sh           # Run with sh
```

## Special Variables

### Positional Parameters
```bash
$0                     # Script name
$1, $2, $3...          # Command-line arguments
$#                     # Number of arguments
$@                     # All arguments as separate words
$*                     # All arguments as single word
$                     # Process ID of script
$?                     # Exit status of last command
```

### Examples
```bash
# Script: example.sh arg1 arg2 arg3
echo "Script: $0"      # Output: ./example.sh
echo "First: $1"       # Output: arg1
echo "Count: $#"       # Output: 3
echo "All: $@"         # Output: arg1 arg2 arg3
```

## Quoting Rules

### Quote Types
```bash
'literal string'       # No expansion at all
"variable expansion"   # Variables and commands expand
\special              # Escape single character
```

### Common Examples
```bash
echo '$HOME'          # Output: $HOME (literal)
echo "$HOME"          # Output: /home/user (expanded)
echo \$HOME           # Output: $HOME (escaped)
echo "I don't"        # Works fine
echo 'I don'\''t'     # Literal single quote: I don't
```

## Exit Codes

### Setting Exit Codes
```bash
exit 0                # Success
exit 1                # General error
exit 2                # Misuse of command
exit 126              # Command not executable
exit 127              # Command not found
```

### Checking Exit Codes
```bash
command
if [ $? -eq 0 ]; then
    echo "Success"
fi

# Better approach
if command; then
    echo "Success"
fi
```

## Conditionals

### if Statements
```bash
# Basic if
if [ condition ]; then
    commands
fi

# if/else
if [ condition ]; then
    commands
else
    commands
fi

# if/elif/else
if [ condition1 ]; then
    commands
elif [ condition2 ]; then
    commands
else
    commands
fi
```

### Test Operators

#### Numeric Comparisons
```bash
[ $a -eq $b ]         # Equal
[ $a -ne $b ]         # Not equal
[ $a -gt $b ]         # Greater than
[ $a -ge $b ]         # Greater than or equal
[ $a -lt $b ]         # Less than
[ $a -le $b ]         # Less than or equal
```

#### String Comparisons
```bash
[ "$a" = "$b" ]       # Equal
[ "$a" != "$b" ]      # Not equal
[ -z "$a" ]           # Empty string
[ -n "$a" ]           # Non-empty string
```

#### File Tests
```bash
[ -f file ]           # Regular file exists
[ -d dir ]            # Directory exists
[ -e path ]           # Path exists (file or dir)
[ -r file ]           # Readable
[ -w file ]           # Writable
[ -x file ]           # Executable
[ -s file ]           # Not empty
[ file1 -nt file2 ]   # file1 newer than file2
[ file1 -ot file2 ]   # file1 older than file2
```

## Loops

### for Loops
```bash
# Iterate over list
for item in list; do
    commands
done

# Iterate over files
for file in *.txt; do
    echo "Processing $file"
done

# Iterate over arguments
for arg in "$@"; do
    echo "Argument: $arg"
done

# C-style loop (bash only)
for ((i=1; i<=10; i++)); do
    echo $i
done
```

### while Loops
```bash
# Basic while
while [ condition ]; do
    commands
done

# Infinite loop
while true; do
    commands
done

# Read file line by line
while read line; do
    echo "Line: $line"
done < file.txt
```

### Loop Control
```bash
break                 # Exit loop
continue              # Skip to next iteration
```

## Functions

### Function Definition
```bash
# Method 1 (preferred)
function_name() {
    commands
}

# Method 2
function function_name() {
    commands
}
```

### Function Parameters
```bash
my_function() {
    local param1=$1
    local param2=$2
    echo "Param1: $param1, Param2: $param2"
}

my_function "hello" "world"
```

### Return Values
```bash
# Return via echo
get_date() {
    echo $(date +%Y-%m-%d)
}
today=$(get_date)

# Return via exit status
is_root() {
    [ $(id -u) -eq 0 ]
}
if is_root; then
    echo "Running as root"
fi
```

## Input/Output

### Reading Input
```bash
read var              # Read into variable
read -p "Prompt: " var # Read with prompt
read -s password      # Silent read (for passwords)
read -n 1 char        # Read single character
read -t 10 var        # Timeout after 10 seconds
```

### Output Redirection
```bash
echo "message" >&2    # Send to stderr
command > file        # Redirect stdout to file
command 2> file       # Redirect stderr to file
command &> file       # Redirect both stdout and stderr
command | tee file    # Display and save to file
```

## Arrays (Bash Only)

### Array Operations
```bash
# Declaration
arr=("item1" "item2" "item3")
arr[0]="new_item1"

# Access
echo ${arr[0]}        # First element
echo ${arr[@]}        # All elements
echo ${#arr[@]}       # Number of elements

# Loop through array
for item in "${arr[@]}"; do
    echo "$item"
done
```

## Case Statements

### Basic Syntax
```bash
case $variable in
    pattern1)
        commands
        ;;
    pattern2|pattern3)
        commands
        ;;
    *)
        default commands
        ;;
esac
```

### Example
```bash
case $1 in
    start)
        echo "Starting service"
        ;;
    stop)
        echo "Stopping service"
        ;;
    restart)
        echo "Restarting service"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```

## String Operations

### String Manipulation
```bash
${#string}            # String length
${string:pos}         # Substring from position
${string:pos:len}     # Substring with length
${string#pattern}     # Remove shortest match from beginning
${string##pattern}    # Remove longest match from beginning
${string%pattern}     # Remove shortest match from end
${string%%pattern}    # Remove longest match from end
${string/old/new}     # Replace first occurrence
${string//old/new}    # Replace all occurrences
```

## Command Substitution

### Syntax
```bash
# Modern syntax (preferred)
result=$(command)
count=$(wc -l < file)

# Old syntax (backticks)
result=`command`
```

## File Inclusion

### Source Files
```bash
. config.sh           # Include file (POSIX)
source config.sh      # Include file (bash)
```

## Error Handling

### Strict Mode
```bash
set -e                # Exit on any error
set -u                # Exit on undefined variable
set -o pipefail       # Fail on pipe errors
set -euo pipefail     # All of the above
```

### Error Functions
```bash
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

[ -f "$file" ] || error_exit "File not found: $file"
```

## Debugging

### Debug Options
```bash
bash -x script.sh     # Show commands as executed
set -x                # Enable debug mode in script
set +x                # Disable debug mode
```

### Common Patterns

### Argument Validation
```bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <argument>"
    exit 1
fi
```

### File Processing
```bash
for file in "$@"; do
    if [ -f "$file" ]; then
        echo "Processing $file"
        # process file
    else
        echo "Warning: $file not found" >&2
    fi
done
```

### Safe Temporary Files
```bash
tmpfile="/tmp/script_$_$(date +%s)"
trap "rm -f $tmpfile" EXIT
```

## Best Practices

### Script Header Template
```bash
#!/bin/bash
# Script: script_name.sh
# Purpose: Brief description
# Author: Your name
# Date: YYYY-MM-DD

set -euo pipefail
```

### Function Template
```bash
function_name() {
    local param1=$1
    local param2=${2:-"default_value"}
    
    # Validate parameters
    [ -z "$param1" ] && { echo "Error: param1 required" >&2; return 1; }
    
    # Function logic here
    echo "Result"
}
```

### Error Handling Pattern
```bash
command || {
    echo "Error: command failed" >&2
    exit 1
}
```

## Quick Tips

- Always quote variables: `"$var"` not `$var`
- Use `[[ ]]` for bash, `[ ]` for POSIX
- Check script with `shellcheck`
- Use `local` for function variables
- Always validate inputs
- Include usage information
- Use meaningful variable names
- Comment complex logic