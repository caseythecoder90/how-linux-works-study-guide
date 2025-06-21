# Bash Scripting: Control Structures and Functions

## Table of Contents
1. [Variables and Basic Syntax](#variables-and-basic-syntax)
2. [Conditional Statements (if/then/else)](#conditional-statements)
3. [Loops](#loops)
4. [Functions](#functions)
5. [Advanced Topics](#advanced-topics)
6. [Practical Examples](#practical-examples)

---

## Variables and Basic Syntax

### Variable Assignment
```bash
# Basic assignment (NO SPACES around =)
name="Casey"
age=25
file_path="/home/user/file.txt"

# Using variables
echo $name           # Output: Casey
echo ${name}         # Same as above, but safer
echo "Hello $name"   # Output: Hello Casey
echo 'Hello $name'   # Output: Hello $name (literal)
```

### Command Substitution
```bash
# Store command output in variable
current_date=$(date)
user_count=$(who | wc -l)
hostname=$(hostname)

echo "Today is: $current_date"
echo "Users logged in: $user_count"
```

### Special Variables
```bash
$0    # Script name
$1    # First argument
$2    # Second argument
$#    # Number of arguments
$@    # All arguments
$$    # Process ID
$?    # Exit status of last command
```

---

## Conditional Statements

### Basic if Statement
```bash
#!/bin/bash

age=25

if [ $age -gt 18 ]; then
    echo "You are an adult"
fi
```

### if/else Statement
```bash
#!/bin/bash

time_hour=$(date +%H)

if [ $time_hour -lt 12 ]; then
    echo "Good morning!"
else
    echo "Good afternoon/evening!"
fi
```

### if/elif/else Statement
```bash
#!/bin/bash

score=85

if [ $score -ge 90 ]; then
    echo "Grade: A"
elif [ $score -ge 80 ]; then
    echo "Grade: B"
elif [ $score -ge 70 ]; then
    echo "Grade: C"
else
    echo "Grade: F"
fi
```

### Test Conditions

#### Numeric Comparisons
```bash
[ $a -eq $b ]    # Equal
[ $a -ne $b ]    # Not equal
[ $a -gt $b ]    # Greater than
[ $a -ge $b ]    # Greater than or equal
[ $a -lt $b ]    # Less than
[ $a -le $b ]    # Less than or equal
```

#### String Comparisons
```bash
[ "$str1" = "$str2" ]     # Equal
[ "$str1" != "$str2" ]    # Not equal
[ -z "$str" ]             # String is empty
[ -n "$str" ]             # String is not empty
```

#### File Tests
```bash
[ -f "file.txt" ]         # File exists and is regular file
[ -d "directory" ]        # Directory exists
[ -r "file.txt" ]         # File is readable
[ -w "file.txt" ]         # File is writable
[ -x "script.sh" ]        # File is executable
```

### Modern Bash Test Syntax
```bash
# [[ ]] is more powerful than [ ]
if [[ $name == "Casey" ]]; then
    echo "Hello Casey!"
fi

# Pattern matching
if [[ $file == *.txt ]]; then
    echo "This is a text file"
fi

# Multiple conditions
if [[ $age -gt 18 && $name == "Casey" ]]; then
    echo "Adult Casey"
fi
```

---

## Loops

### for Loop - List Items
```bash
#!/bin/bash

# Loop through a list
for fruit in apple banana orange; do
    echo "I like $fruit"
done

# Loop through files
for file in *.txt; do
    echo "Processing: $file"
done

# Loop through command output
for user in $(cat /etc/passwd | cut -d: -f1); do
    echo "User: $user"
done
```

### for Loop - Numeric Range
```bash
#!/bin/bash

# C-style for loop
for ((i=1; i<=5; i++)); do
    echo "Count: $i"
done

# Using seq command
for i in $(seq 1 10); do
    echo "Number: $i"
done

# Brace expansion
for i in {1..10}; do
    echo "Value: $i"
done
```

### while Loop
```bash
#!/bin/bash

counter=1
while [ $counter -le 5 ]; do
    echo "Counter: $counter"
    ((counter++))  # Increment counter
done

# Reading file line by line
while read line; do
    echo "Line: $line"
done < /etc/passwd
```

### until Loop
```bash
#!/bin/bash

counter=1
until [ $counter -gt 5 ]; do
    echo "Counter: $counter"
    ((counter++))
done
```

### Loop Control
```bash
#!/bin/bash

for i in {1..10}; do
    if [ $i -eq 3 ]; then
        continue  # Skip this iteration
    fi
    
    if [ $i -eq 8 ]; then
        break     # Exit the loop
    fi
    
    echo "Number: $i"
done
```

---

## Functions

### Basic Function Syntax
```bash
#!/bin/bash

# Method 1: function keyword
function say_hello() {
    echo "Hello, World!"
}

# Method 2: without function keyword (preferred)
say_goodbye() {
    echo "Goodbye!"
}

# Call the functions
say_hello
say_goodbye
```

### Functions with Arguments
```bash
#!/bin/bash

greet_user() {
    local name=$1    # First argument
    local age=$2     # Second argument
    
    echo "Hello $name, you are $age years old"
}

# Call with arguments
greet_user "Casey" 25
greet_user "Alice" 30
```

### Functions with Return Values
```bash
#!/bin/bash

# Method 1: Using echo (most common)
get_current_time() {
    echo $(date +%H:%M:%S)
}

# Method 2: Using return for exit status
is_even() {
    local number=$1
    if [ $((number % 2)) -eq 0 ]; then
        return 0  # Success (true)
    else
        return 1  # Failure (false)
    fi
}

# Using the functions
current_time=$(get_current_time)
echo "Current time: $current_time"

if is_even 4; then
    echo "4 is even"
fi
```

### Local Variables in Functions
```bash
#!/bin/bash

global_var="I'm global"

my_function() {
    local local_var="I'm local"
    global_var="Modified global"
    
    echo "Inside function:"
    echo "  Local: $local_var"
    echo "  Global: $global_var"
}

echo "Before function: $global_var"
my_function
echo "After function: $global_var"
# echo "Local var: $local_var"  # This would be empty
```

### Functions with Multiple Return Values
```bash
#!/bin/bash

get_system_info() {
    local hostname=$(hostname)
    local uptime=$(uptime | awk '{print $3,$4}')
    local users=$(who | wc -l)
    
    # Return multiple values separated by |
    echo "$hostname|$uptime|$users"
}

# Parse multiple return values
system_info=$(get_system_info)
IFS='|' read -r host_name system_uptime user_count <<< "$system_info"

echo "Hostname: $host_name"
echo "Uptime: $system_uptime"
echo "Users: $user_count"
```

---

## Advanced Topics

### Case Statements
```bash
#!/bin/bash

day=$(date +%A)

case $day in
    "Monday")
        echo "Start of work week"
        ;;
    "Friday")
        echo "TGIF!"
        ;;
    "Saturday"|"Sunday")
        echo "Weekend!"
        ;;
    *)
        echo "Midweek day"
        ;;
esac
```

### Arrays
```bash
#!/bin/bash

# Declare array
fruits=("apple" "banana" "orange")

# Add elements
fruits[3]="grape"
fruits+=("mango")

# Access elements
echo "First fruit: ${fruits[0]}"
echo "All fruits: ${fruits[@]}"
echo "Number of fruits: ${#fruits[@]}"

# Loop through array
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done
```

### Error Handling
```bash
#!/bin/bash

# Exit on any error
set -e

# Function with error handling
safe_copy() {
    local source=$1
    local dest=$2
    
    if [ ! -f "$source" ]; then
        echo "Error: Source file $source does not exist"
        return 1
    fi
    
    if cp "$source" "$dest"; then
        echo "Successfully copied $source to $dest"
        return 0
    else
        echo "Error: Failed to copy $source to $dest"
        return 1
    fi
}

# Use the function
if safe_copy "file1.txt" "file2.txt"; then
    echo "Copy operation succeeded"
else
    echo "Copy operation failed"
fi
```

---

## Practical Examples

### Example 1: System Monitor Script
```bash
#!/bin/bash

log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message"
}

check_disk_space() {
    local threshold=80
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ $usage -gt $threshold ]; then
        log_message "WARNING: Disk usage is ${usage}%"
        return 1
    else
        log_message "INFO: Disk usage is ${usage}% (OK)"
        return 0
    fi
}

check_memory() {
    local mem_info=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    log_message "INFO: Memory usage is ${mem_info}%"
}

main() {
    log_message "Starting system check"
    
    check_disk_space
    check_memory
    
    log_message "System check completed"
}

# Run the script
main
```

### Example 2: File Backup Script
```bash
#!/bin/bash

backup_file() {
    local source_file=$1
    local backup_dir="/backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Check if source file exists
    if [ ! -f "$source_file" ]; then
        echo "Error: File $source_file not found"
        return 1
    fi
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
    fi
    
    # Create backup filename
    local filename=$(basename "$source_file")
    local backup_file="${backup_dir}/${filename}.${timestamp}.bak"
    
    # Perform backup
    if cp "$source_file" "$backup_file"; then
        echo "Successfully backed up $source_file to $backup_file"
        return 0
    else
        echo "Failed to backup $source_file"
        return 1
    fi
}

# Backup multiple files
for file in "$@"; do
    backup_file "$file"
done
```

### Example 3: User Input and Validation
```bash
#!/bin/bash

get_user_input() {
    local prompt=$1
    local var_name=$2
    local validation_func=$3
    
    while true; do
        read -p "$prompt: " input
        
        if [ -n "$validation_func" ] && ! $validation_func "$input"; then
            echo "Invalid input. Please try again."
            continue
        fi
        
        # Return the input
        echo "$input"
        return 0
    done
}

validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_age() {
    local age=$1
    if [[ $age =~ ^[0-9]+$ ]] && [ $age -ge 1 ] && [ $age -le 120 ]; then
        return 0
    else
        return 1
    fi
}

# Get user information
name=$(get_user_input "Enter your name" "name")
email=$(get_user_input "Enter your email" "email" "validate_email")
age=$(get_user_input "Enter your age" "age" "validate_age")

echo "Name: $name"
echo "Email: $email"
echo "Age: $age"
```

## Key Takeaways

1. **Variables**: No spaces around `=`, use `${}` for safety
2. **Conditions**: Use `[[ ]]` for modern bash, `[ ]` for POSIX
3. **Loops**: `for` for known iterations, `while` for conditions
4. **Functions**: Use `local` for variables, return values with `echo`
5. **Error Handling**: Check return codes, use `set -e` for strict mode
6. **Best Practices**: Quote variables, use meaningful names, comment your code

This covers the essential building blocks for bash scripting! Practice with small scripts and gradually build more complex ones.