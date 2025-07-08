# Chapter 11: Shell Scripting Lab Exercises

## Prerequisites
- Linux system with bash shell
- Text editor (nano, vim, VS Code, etc.)
- Basic command line knowledge
- Understanding of file permissions

## Lab Objectives
By the end of this lab, you will:
1. Create and execute basic shell scripts
2. Master quoting and special variables
3. Implement conditional logic and loops
4. Write functions and handle user input
5. Apply best practices for script development

---

## Part 1: Basic Script Creation (20 minutes)

### Exercise 1.1: Your First Script
1. Create a simple "Hello World" script:
   ```bash
   nano hello.sh
   ```

2. Add the following content:
   ```bash
   #!/bin/bash
   echo "Hello, World!"
   echo "Today is $(date)"
   echo "You are logged in as $(whoami)"
   ```

3. Make it executable and run it:
   ```bash
   chmod +x hello.sh
   ./hello.sh
   ```

### Exercise 1.2: Script Arguments
1. Create a script that uses command-line arguments:
   ```bash
   nano greet.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   echo "Script name: $0"
   echo "First argument: $1"
   echo "Second argument: $2"
   echo "Number of arguments: $#"
   echo "All arguments: $@"
   echo "Process ID: $$"
   ```

3. Test with different arguments:
   ```bash
   chmod +x greet.sh
   ./greet.sh Alice Bob Charlie
   ./greet.sh "John Doe"
   ./greet.sh
   ```

### Exercise 1.3: Exit Codes
1. Create a script that demonstrates exit codes:
   ```bash
   nano exit_demo.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   echo "Testing ls command..."
   ls /nonexistent 2>/dev/null
   echo "Exit code of ls: $?"
   
   echo "Testing date command..."
   date
   echo "Exit code of date: $?"
   
   # Set custom exit code
   if [ $# -eq 0 ]; then
       echo "No arguments provided"
       exit 1
   else
       echo "Arguments provided: $@"
       exit 0
   fi
   ```

3. Test and check exit codes:
   ```bash
   chmod +x exit_demo.sh
   ./exit_demo.sh
   echo "Script exit code: $?"
   ./exit_demo.sh arg1
   echo "Script exit code: $?"
   ```

**Questions:**
- What happens when you don't provide arguments to greet.sh?
- Why might exit codes be important in automation scripts?

---

## Part 2: Quoting and Variables (25 minutes)

### Exercise 2.1: Quoting Challenges
1. Create a script to explore quoting:
   ```bash
   nano quote_test.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   amount=100
   
   echo "Testing quoting with \$amount = $amount"
   echo
   
   echo "Single quotes:"
   echo 'The amount is $amount'
   
   echo "Double quotes:"
   echo "The amount is $amount"
   
   echo "No quotes:"
   echo The amount is $amount
   
   echo "Escaped:"
   echo "The amount is \$amount"
   
   # Test with special characters
   echo
   echo "Special characters:"
   echo 'Files: *.txt'
   echo "Files: *.txt"
   echo Files: *.txt
   ```

3. Run and observe the differences:
   ```bash
   chmod +x quote_test.sh
   ./quote_test.sh
   ```

### Exercise 2.2: Variable Assignment and Expansion
1. Create a script with variable operations:
   ```bash
   nano variables.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Variable assignment (no spaces around =)
   name="Alice"
   age=25
   city="New York"
   
   # Command substitution
   current_date=$(date +%Y-%m-%d)
   file_count=$(ls -1 | wc -l)
   
   # Display variables
   echo "Name: $name"
   echo "Age: $age"
   echo "City: $city"
   echo "Date: $current_date"
   echo "Files in current directory: $file_count"
   
   # String concatenation
   full_info="$name is $age years old and lives in $city"
   echo "Full info: $full_info"
   
   # Using variables in commands
   echo "Creating backup file for $name..."
   touch "backup_${name}_${current_date}.txt"
   ls -l backup_*.txt
   ```

3. Test the script:
   ```bash
   chmod +x variables.sh
   ./variables.sh
   ```

**Questions:**
- What happens if you put spaces around the = in variable assignment?
- How do single quotes affect variable expansion?

---

## Part 3: Conditionals and Testing (30 minutes)

### Exercise 3.1: File Testing Script
1. Create a comprehensive file testing script:
   ```bash
   nano file_test.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   if [ $# -eq 0 ]; then
       echo "Usage: $0 <filename>"
       exit 1
   fi
   
   file="$1"
   
   echo "Testing file: $file"
   echo "========================"
   
   if [ -e "$file" ]; then
       echo "✓ File exists"
       
       if [ -f "$file" ]; then
           echo "✓ It's a regular file"
       elif [ -d "$file" ]; then
           echo "✓ It's a directory"
       elif [ -L "$file" ]; then
           echo "✓ It's a symbolic link"
       fi
       
       # Permission tests
       [ -r "$file" ] && echo "✓ Readable" || echo "✗ Not readable"
       [ -w "$file" ] && echo "✓ Writable" || echo "✗ Not writable"
       [ -x "$file" ] && echo "✓ Executable" || echo "✗ Not executable"
       
       # Size test
       if [ -s "$file" ]; then
           echo "✓ File is not empty"
           echo "  Size: $(ls -lh "$file" | awk '{print $5}')"
       else
           echo "✗ File is empty"
       fi
       
   else
       echo "✗ File does not exist"
   fi
   ```

3. Test with various files:
   ```bash
   chmod +x file_test.sh
   ./file_test.sh /etc/passwd
   ./file_test.sh /tmp
   ./file_test.sh ./file_test.sh
   ./file_test.sh /nonexistent
   ```

### Exercise 3.2: Number Comparison Script
1. Create a number comparison script:
   ```bash
   nano compare.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   if [ $# -ne 2 ]; then
       echo "Usage: $0 <number1> <number2>"
       exit 1
   fi
   
   num1=$1
   num2=$2
   
   # Validate that inputs are numbers
   if ! [[ "$num1" =~ ^-?[0-9]+$ ]]; then
       echo "Error: '$num1' is not a valid number"
       exit 1
   fi
   
   if ! [[ "$num2" =~ ^-?[0-9]+$ ]]; then
       echo "Error: '$num2' is not a valid number"
       exit 1
   fi
   
   echo "Comparing $num1 and $num2:"
   
   if [ $num1 -eq $num2 ]; then
       echo "$num1 equals $num2"
   elif [ $num1 -gt $num2 ]; then
       echo "$num1 is greater than $num2"
   else
       echo "$num1 is less than $num2"
   fi
   
   # Additional comparisons
   [ $num1 -ge $num2 ] && echo "$num1 >= $num2" || echo "$num1 < $num2"
   [ $num1 -le $num2 ] && echo "$num1 <= $num2" || echo "$num1 > $num2"
   [ $num1 -ne $num2 ] && echo "$num1 != $num2" || echo "$num1 == $num2"
   ```

3. Test with different numbers:
   ```bash
   chmod +x compare.sh
   ./compare.sh 10 20
   ./compare.sh 5 5
   ./compare.sh -3 7
   ./compare.sh abc 123
   ```

**Questions:**
- What's the difference between `-eq` and `=` for comparisons?
- How does the script validate that inputs are actually numbers?

---

## Part 4: Loops and Iteration (35 minutes)

### Exercise 4.1: For Loop Practice
1. Create a file processing script:
   ```bash
   nano process_files.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   echo "Creating test files..."
   for i in {1..5}; do
       echo "This is test file $i" > "test$i.txt"
   done
   
   echo "Processing .txt files in current directory:"
   count=0
   
   for file in *.txt; do
       if [ -f "$file" ]; then
           echo "Processing: $file"
           echo "  Lines: $(wc -l < "$file")"
           echo "  Words: $(wc -w < "$file")"
           echo "  Size: $(ls -lh "$file" | awk '{print $5}')"
           count=$((count + 1))
       fi
   done
   
   echo "Processed $count files"
   
   # Process command line arguments
   if [ $# -gt 0 ]; then
       echo
       echo "Processing command line arguments:"
       for arg in "$@"; do
           echo "Argument: $arg"
       done
   fi
   ```

3. Test the script:
   ```bash
   chmod +x process_files.sh
   ./process_files.sh
   ./process_files.sh arg1 arg2 "argument with spaces"
   ```

### Exercise 4.2: While Loop and User Input
1. Create an interactive menu script:
   ```bash
   nano menu.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   display_menu() {
       echo
       echo "=== System Information Menu ==="
       echo "1) Show current date and time"
       echo "2) Show disk usage"
       echo "3) Show memory usage"
       echo "4) Show logged in users"
       echo "5) Show system uptime"
       echo "q) Quit"
       echo "=========================="
   }
   
   while true; do
       display_menu
       read -p "Enter your choice: " choice
       
       case $choice in
           1)
               echo "Current date and time: $(date)"
               ;;
           2)
               echo "Disk usage:"
               df -h | head -5
               ;;
           3)
               echo "Memory usage:"
               free -h
               ;;
           4)
               echo "Logged in users:"
               who
               ;;
           5)
               echo "System uptime:"
               uptime
               ;;
           q|Q)
               echo "Goodbye!"
               break
               ;;
           *)
               echo "Invalid choice. Please try again."
               ;;
       esac
       
       read -p "Press Enter to continue..."
   done
   ```

3. Test the interactive script:
   ```bash
   chmod +x menu.sh
   ./menu.sh
   ```

### Exercise 4.3: Nested Loops and File Organization
1. Create a directory organization script:
   ```bash
   nano organize.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Create test directory structure
   echo "Creating test files..."
   mkdir -p test_organize
   cd test_organize
   
   # Create various file types
   for ext in txt pdf jpg doc; do
       for i in {1..3}; do
           touch "file$i.$ext"
       done
   done
   
   # Create some additional files
   touch "README.md" "script.sh" "data.csv"
   
   echo "Files created:"
   ls -la
   
   echo
   echo "Organizing files by extension..."
   
   # Get all file extensions
   extensions=$(ls -1 | grep '\.' | sed 's/.*\.//' | sort -u)
   
   for ext in $extensions; do
       echo "Processing .$ext files..."
       
       # Create directory for this extension
       mkdir -p "$ext"
       
       # Move files with this extension
       for file in *.$ext; do
           if [ -f "$file" ]; then
               echo "  Moving $file to $ext/"
               mv "$file" "$ext/"
           fi
       done
   done
   
   echo
   echo "Organization complete:"
   for dir in */; do
       echo "Directory $dir:"
       ls "$dir"
   done
   
   cd ..
   ```

3. Run the organization script:
   ```bash
   chmod +x organize.sh
   ./organize.sh
   ```

**Questions:**
- How does the nested loop structure work in the organize script?
- What would happen if you ran the organization script twice?

---

## Part 5: Functions and Modular Programming (30 minutes)

### Exercise 5.1: Basic Functions
1. Create a script with utility functions:
   ```bash
   nano utils.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Function to display colored output
   print_colored() {
       local color=$1
       local message=$2
       
       case $color in
           red)    echo -e "\033[31m$message\033[0m" ;;
           green)  echo -e "\033[32m$message\033[0m" ;;
           yellow) echo -e "\033[33m$message\033[0m" ;;
           blue)   echo -e "\033[34m$message\033[0m" ;;
           *)      echo "$message" ;;
       esac
   }
   
   # Function to check if command exists
   command_exists() {
       command -v "$1" >/dev/null 2>&1
   }
   
   # Function to get file size in human readable format
   get_file_size() {
       local file=$1
       if [ -f "$file" ]; then
           ls -lh "$file" | awk '{print $5}'
       else
           echo "File not found"
       fi
   }
   
   # Function to backup a file
   backup_file() {
       local file=$1
       local backup_dir=${2:-"./backup"}
       
       if [ ! -f "$file" ]; then
           print_colored red "Error: File '$file' not found"
           return 1
       fi
       
       # Create backup directory if it doesn't exist
       mkdir -p "$backup_dir"
       
       # Create backup with timestamp
       local timestamp=$(date +%Y%m%d_%H%M%S)
       local backup_name="$(basename "$file").$timestamp.bak"
       
       cp "$file" "$backup_dir/$backup_name"
       print_colored green "Backup created: $backup_dir/$backup_name"
   }
   
   # Function to calculate directory size
   dir_size() {
       local dir=${1:-.}
       if [ -d "$dir" ]; then
           du -sh "$dir" | cut -f1
       else
           echo "Directory not found"
       fi
   }
   
   # Main script execution
   echo "=== Utility Functions Demo ==="
   
   print_colored blue "Testing colored output..."
   print_colored red "This is red"
   print_colored green "This is green"
   print_colored yellow "This is yellow"
   
   echo
   print_colored blue "Testing command existence..."
   for cmd in ls grep nonexistent_command; do
       if command_exists "$cmd"; then
           print_colored green "✓ $cmd exists"
       else
           print_colored red "✗ $cmd not found"
       fi
   done
   
   echo
   print_colored blue "Testing file operations..."
   echo "Sample content" > sample.txt
   echo "File size: $(get_file_size sample.txt)"
   backup_file sample.txt
   
   echo
   print_colored blue "Directory size:"
   echo "Current directory: $(dir_size .)"
   ```

3. Test the functions:
   ```bash
   chmod +x utils.sh
   ./utils.sh
   ```

### Exercise 5.2: Function Parameters and Return Values
1. Create a mathematical functions script:
   ```bash
   nano math_funcs.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Function that returns a value via echo
   add() {
       local a=$1
       local b=$2
       echo $((a + b))
   }
   
   # Function that returns success/failure
   is_even() {
       local number=$1
       [ $((number % 2)) -eq 0 ]
   }
   
   # Function with input validation
   divide() {
       local dividend=$1
       local divisor=$2
       
       # Validate inputs
       if [ -z "$dividend" ] || [ -z "$divisor" ]; then
           echo "Error: Two numbers required" >&2
           return 1
       fi
       
       if [ "$divisor" -eq 0 ]; then
           echo "Error: Division by zero" >&2
           return 1
       fi
       
       echo $((dividend / divisor))
   }
   
   # Function with multiple return values
   get_stats() {
       local file=$1
       
       if [ ! -f "$file" ]; then
           echo "0|0|0"  # lines|words|chars
           return 1
       fi
       
       local lines=$(wc -l < "$file")
       local words=$(wc -w < "$file")
       local chars=$(wc -c < "$file")
       
       echo "$lines|$words|$chars"
   }
   
   # Function with default parameters
   greet() {
       local name=${1:-"World"}
       local greeting=${2:-"Hello"}
       echo "$greeting, $name!"
   }
   
   # Main execution
   echo "=== Mathematical Functions Demo ==="
   
   # Test addition
   result=$(add 5 3)
   echo "5 + 3 = $result"
   
   # Test even/odd
   for num in 4 7 10 13; do
       if is_even $num; then
           echo "$num is even"
       else
           echo "$num is odd"
       fi
   done
   
   # Test division
   echo "Division tests:"
   echo "10 / 2 = $(divide 10 2)"
   echo "10 / 0 = $(divide 10 0)"
   echo "Empty params = $(divide)"
   
   # Test file statistics
   echo "Sample content for testing" > test_file.txt
   echo "More content here" >> test_file.txt
   
   stats=$(get_stats test_file.txt)
   IFS='|' read -r lines words chars <<< "$stats"
   echo "File stats - Lines: $lines, Words: $words, Characters: $chars"
   
   # Test greetings with defaults
   greet
   greet "Alice"
   greet "Bob" "Hi"
   
   # Cleanup
   rm -f test_file.txt
   ```

3. Test the mathematical functions:
   ```bash
   chmod +x math_funcs.sh
   ./math_funcs.sh
   ```

**Questions:**
- How do you return multiple values from a function?
- What's the difference between return codes and return values?

---

## Part 6: Advanced Scripting (40 minutes)

### Exercise 6.1: User Input and Validation
1. Create a user registration script:
   ```bash
   nano register.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Function to validate email
   validate_email() {
       local email=$1
       if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
           return 0
       else
           return 1
       fi
   }
   
   # Function to validate age
   validate_age() {
       local age=$1
       if [[ $age =~ ^[0-9]+$ ]] && [ $age -ge 1 ] && [ $age -le 120 ]; then
           return 0
       else
           return 1
       fi
   }
   
   # Function to get valid input
   get_input() {
       local prompt=$1
       local var_name=$2
       local validator=$3
       
       while true; do
           read -p "$prompt: " input
           
           if [ -z "$input" ]; then
               echo "Input cannot be empty. Please try again."
               continue
           fi
           
           if [ -n "$validator" ]; then
               if ! $validator "$input"; then
                   echo "Invalid input. Please try again."
                   continue
               fi
           fi
           
           echo "$input"
           return 0
       done
   }
   
   # Main registration process
   echo "=== User Registration ==="
   echo
   
   # Get user information
   name=$(get_input "Enter your full name" "name")
   email=$(get_input "Enter your email address" "email" "validate_email")
   age=$(get_input "Enter your age" "age" "validate_age")
   
   # Get password (hidden input)
   while true; do
       read -s -p "Enter password (min 6 characters): " password
       echo
       if [ ${#password} -lt 6 ]; then
           echo "Password must be at least 6 characters long."
           continue
       fi
       
       read -s -p "Confirm password: " confirm_password
       echo
       if [ "$password" != "$confirm_password" ]; then
           echo "Passwords do not match. Please try again."
           continue
       fi
       break
   done
   
   # Display summary
   echo
   echo "=== Registration Summary ==="
   echo "Name: $name"
   echo "Email: $email"
   echo "Age: $age"
   echo "Password: [hidden]"
   echo
   
   # Confirm registration
   read -p "Confirm registration? (y/n): " confirm
   case $confirm in
       y|Y|yes|YES)
           echo "Registration completed successfully!"
           # Here you would typically save to a file or database
           echo "$name|$email|$age|$(date)" >> users.txt
           echo "User data saved to users.txt"
           ;;
       *)
           echo "Registration cancelled."
           ;;
   esac
   ```

3. Test the registration script:
   ```bash
   chmod +x register.sh
   ./register.sh
   ```

### Exercise 6.2: File Processing with Error Handling
1. Create a log analyzer script:
   ```bash
   nano log_analyzer.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Enable strict error handling
   set -euo pipefail
   
   # Configuration
   SCRIPT_NAME=$(basename "$0")
   DEFAULT_LOG="/var/log/syslog"
   
   # Function for error messages
   error_exit() {
       echo "ERROR: $1" >&2
       exit 1
   }
   
   # Function for logging
   log_message() {
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
   }
   
   # Function to analyze log file
   analyze_log() {
       local logfile=$1
       local output_file=${2:-"analysis_report.txt"}
       
       log_message "Starting analysis of $logfile"
       
       # Check if log file exists and is readable
       [ -f "$logfile" ] || error_exit "Log file not found: $logfile"
       [ -r "$logfile" ] || error_exit "Cannot read log file: $logfile"
       
       # Create analysis report
       {
           echo "=== Log Analysis Report ==="
           echo "File: $logfile"
           echo "Generated: $(date)"
           echo "Analyzed by: $(whoami) on $(hostname)"
           echo
           
           echo "=== File Statistics ==="
           echo "Size: $(ls -lh "$logfile" | awk '{print $5}')"
           echo "Lines: $(wc -l < "$logfile")"
           echo "Last modified: $(ls -l "$logfile" | awk '{print $6, $7, $8}')"
           echo
           
           echo "=== Error Analysis ==="
           local error_count=$(grep -ci "error\|fail\|exception" "$logfile" || true)
           echo "Total errors/failures: $error_count"
           
           if [ $error_count -gt 0 ]; then
               echo
               echo "Recent errors (last 10):"
               grep -i "error\|fail\|exception" "$logfile" | tail -10
           fi
           
           echo
           echo "=== Warning Analysis ==="
           local warning_count=$(grep -ci "warn\|warning" "$logfile" || true)
           echo "Total warnings: $warning_count"
           
           if [ $warning_count -gt 0 ]; then
               echo
               echo "Recent warnings (last 5):"
               grep -i "warn\|warning" "$logfile" | tail -5
           fi
           
           echo
           echo "=== Top IP Addresses ==="
           # Extract IP addresses and count them
           grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$logfile" | \
           sort | uniq -c | sort -rn | head -10
           
           echo
           echo "=== Hourly Activity ==="
           # Extract hours and count activity
           grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}' "$logfile" | \
           cut -d: -f1 | sort | uniq -c | sort -rn
           
       } > "$output_file"
       
       log_message "Analysis complete. Report saved to $output_file"
   }
   
   # Function to monitor log in real-time
   monitor_log() {
       local logfile=$1
       local pattern=${2:-"error\|warning\|fail"}
       
       log_message "Starting real-time monitoring of $logfile"
       log_message "Watching for pattern: $pattern"
       log_message "Press Ctrl+C to stop"
       
       tail -f "$logfile" | while read line; do
           if echo "$line" | grep -qi "$pattern"; then
               echo "[ALERT] $(date '+%H:%M:%S') $line"
           fi
       done
   }
   
   # Function to create sample log for testing
   create_sample_log() {
       local sample_log="sample.log"
       log_message "Creating sample log file: $sample_log"
       
       {
           for i in {1..100}; do
               timestamp=$(date '+%Y-%m-%d %H:%M:%S')
               case $((RANDOM % 5)) in
                   0) echo "$timestamp INFO: User login successful from 192.168.1.$((RANDOM % 255))" ;;
                   1) echo "$timestamp WARNING: High memory usage detected" ;;
                   2) echo "$timestamp ERROR: Database connection failed" ;;
                   3) echo "$timestamp INFO: Backup completed successfully" ;;
                   4) echo "$timestamp ERROR: Authentication failed for user admin" ;;
               esac
               sleep 0.1
           done
       } > "$sample_log"
       
       log_message "Sample log created with 100 entries"
       echo "$sample_log"
   }
   
   # Function to display usage
   usage() {
       cat << EOF
   Usage: $SCRIPT_NAME [OPTIONS] [LOGFILE]
   
   OPTIONS:
       -a, --analyze [file]    Analyze log file (default: $DEFAULT_LOG)
       -m, --monitor [file]    Monitor log file in real-time
       -s, --sample           Create sample log for testing
       -h, --help            Show this help message
   
   EXAMPLES:
       $SCRIPT_NAME --analyze /var/log/apache2/access.log
       $SCRIPT_NAME --monitor /var/log/syslog
       $SCRIPT_NAME --sample
   EOF
   }
   
   # Main script logic
   case ${1:-""} in
       -a|--analyze)
           logfile=${2:-$DEFAULT_LOG}
           analyze_log "$logfile"
           ;;
       -m|--monitor)
           logfile=${2:-$DEFAULT_LOG}
           monitor_log "$logfile"
           ;;
       -s|--sample)
           sample_file=$(create_sample_log)
           echo "Sample log created: $sample_file"
           echo "You can now analyze it with: $SCRIPT_NAME --analyze $sample_file"
           ;;
       -h|--help)
           usage
           ;;
       "")
           usage
           ;;
       *)
           error_exit "Unknown option: $1. Use --help for usage information."
           ;;
   esac
   ```

3. Test the log analyzer:
   ```bash
   chmod +x log_analyzer.sh
   ./log_analyzer.sh --help
   ./log_analyzer.sh --sample
   ./log_analyzer.sh --analyze sample.log
   ```

### Exercise 6.3: Configuration Management Script
1. Create a system configuration backup script:
   ```bash
   nano config_backup.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Configuration
   BACKUP_DIR="$HOME/config_backups"
   CONFIG_DIRS="/etc /home/$USER/.config"
   EXCLUDE_PATTERNS="*.log *.tmp *.cache"
   DATE_FORMAT="%Y%m%d_%H%M%S"
   
   # Include shared functions if they exist
   if [ -f "./utils.sh" ]; then
       source ./utils.sh
   else
       # Define basic functions if utils.sh not available
       print_colored() {
           local color=$1
           local message=$2
           echo "$message"
       }
   fi
   
   # Function to create backup
   create_backup() {
       local description=${1:-"manual"}
       local timestamp=$(date +"$DATE_FORMAT")
       local backup_name="config_backup_${description}_${timestamp}"
       local backup_path="$BACKUP_DIR/$backup_name"
       
       print_colored blue "Creating backup: $backup_name"
       
       # Create backup directory
       mkdir -p "$backup_path"
       
       # Backup each configuration directory
       for config_dir in $CONFIG_DIRS; do
           if [ -d "$config_dir" ]; then
               local dir_name=$(basename "$config_dir")
               print_colored yellow "Backing up $config_dir..."
               
               # Use tar with exclusions
               tar -czf "$backup_path/${dir_name}.tar.gz" \
                   --exclude="*.log" \
                   --exclude="*.tmp" \
                   --exclude="*.cache" \
                   -C "$(dirname "$config_dir")" \
                   "$(basename "$config_dir")" 2>/dev/null || {
                   print_colored red "Warning: Failed to backup $config_dir"
                   continue
               }
               
               print_colored green "✓ $config_dir backed up"
           else
               print_colored yellow "Warning: $config_dir not found, skipping"
           fi
       done
       
       # Create manifest file
       {
           echo "Backup: $backup_name"
           echo "Created: $(date)"
           echo "User: $(whoami)"
           echo "Host: $(hostname)"
           echo "Directories:"
           for dir in $CONFIG_DIRS; do
               [ -d "$dir" ] && echo "  - $dir"
           done
       } > "$backup_path/manifest.txt"
       
       print_colored green "Backup completed: $backup_path"
       return 0
   }
   
   # Function to list backups
   list_backups() {
       print_colored blue "Available backups in $BACKUP_DIR:"
       
       if [ ! -d "$BACKUP_DIR" ]; then
           print_colored yellow "No backup directory found"
           return 1
       fi
       
       local count=0
       for backup in "$BACKUP_DIR"/config_backup_*; do
           if [ -d "$backup" ]; then
               count=$((count + 1))
               local backup_name=$(basename "$backup")
               local manifest="$backup/manifest.txt"
               
               echo "[$count] $backup_name"
               if [ -f "$manifest" ]; then
                   echo "    Created: $(grep "Created:" "$manifest" | cut -d: -f2-)"
                   echo "    Size: $(du -sh "$backup" | cut -f1)"
               fi
               echo
           fi
       done
       
       if [ $count -eq 0 ]; then
           print_colored yellow "No backups found"
       else
           print_colored green "Total backups: $count"
       fi
   }
   
   # Function to restore backup
   restore_backup() {
       local backup_name=$1
       
       if [ -z "$backup_name" ]; then
           print_colored red "Error: Backup name required for restore"
           return 1
       fi
       
       local backup_path="$BACKUP_DIR/$backup_name"
       
       if [ ! -d "$backup_path" ]; then
           print_colored red "Error: Backup not found: $backup_name"
           return 1
       fi
       
       print_colored yellow "WARNING: This will restore configuration files!"
       print_colored yellow "Current files may be overwritten."
       read -p "Continue? (y/N): " confirm
       
       case $confirm in
           y|Y|yes|YES)
               print_colored blue "Restoring from $backup_name..."
               
               for archive in "$backup_path"/*.tar.gz; do
                   if [ -f "$archive" ]; then
                       local dir_name=$(basename "$archive" .tar.gz)
                       print_colored yellow "Restoring $dir_name..."
                       
                       # Extract to appropriate location
                       case $dir_name in
                           etc)
                               sudo tar -xzf "$archive" -C / 2>/dev/null || {
                                   print_colored red "Failed to restore $dir_name (may need sudo)"
                               }
                               ;;
                           .config)
                               tar -xzf "$archive" -C "$HOME" 2>/dev/null || {
                                   print_colored red "Failed to restore $dir_name"
                               }
                               ;;
                           *)
                               print_colored yellow "Unknown directory type: $dir_name, skipping"
                               ;;
                       esac
                   fi
               done
               
               print_colored green "Restore completed"
               ;;
           *)
               print_colored yellow "Restore cancelled"
               ;;
       esac
   }
   
   # Function to cleanup old backups
   cleanup_backups() {
       local days=${1:-30}
       
       print_colored blue "Cleaning up backups older than $days days..."
       
       if [ ! -d "$BACKUP_DIR" ]; then
           print_colored yellow "No backup directory found"
           return 0
       fi
       
       local count=0
       find "$BACKUP_DIR" -name "config_backup_*" -type d -mtime +$days | while read backup; do
           print_colored yellow "Removing old backup: $(basename "$backup")"
           rm -rf "$backup"
           count=$((count + 1))
       done
       
       print_colored green "Cleanup completed"
   }
   
   # Function to show disk usage
   show_usage() {
       if [ -d "$BACKUP_DIR" ]; then
           print_colored blue "Backup directory usage:"
           du -sh "$BACKUP_DIR"
           echo
           print_colored blue "Individual backup sizes:"
           du -sh "$BACKUP_DIR"/config_backup_* 2>/dev/null | sort -hr
       else
           print_colored yellow "No backup directory found"
       fi
   }
   
   # Function to display usage
   usage() {
       cat << EOF
   Configuration Backup Script
   
   Usage: $0 [COMMAND] [OPTIONS]
   
   COMMANDS:
       backup [description]    Create new backup (optional description)
       list                   List all available backups
       restore <backup_name>  Restore from specific backup
       cleanup [days]         Remove backups older than N days (default: 30)
       usage                  Show disk usage of backups
       help                   Show this help message
   
   EXAMPLES:
       $0 backup "before_update"
       $0 list
       $0 restore config_backup_manual_20240101_120000
       $0 cleanup 7
   EOF
   }
   
   # Main script execution
   case ${1:-"help"} in
       backup)
           create_backup "${2:-manual}"
           ;;
       list)
           list_backups
           ;;
       restore)
           restore_backup "$2"
           ;;
       cleanup)
           cleanup_backups "${2:-30}"
           ;;
       usage)
           show_usage
           ;;
       help|--help|-h)
           usage
           ;;
       *)
           print_colored red "Unknown command: $1"
           usage
           exit 1
           ;;
   esac
   ```

3. Test the configuration backup script:
   ```bash
   chmod +x config_backup.sh
   ./config_backup.sh help
   ./config_backup.sh backup "test_backup"
   ./config_backup.sh list
   ./config_backup.sh usage
   ```

**Questions:**
- How does the script handle errors and provide user feedback?
- What security considerations are important when dealing with configuration files?

---

## Part 7: Integration and Real-World Application (25 minutes)

### Exercise 7.1: System Monitoring Dashboard
1. Create a comprehensive system monitoring script:
   ```bash
   nano monitor.sh
   ```

2. Add this content:
   ```bash
   #!/bin/bash
   
   # Include utility functions
   [ -f "./utils.sh" ] && source ./utils.sh
   
   # Configuration
   REFRESH_INTERVAL=5
   LOG_FILE="$HOME/system_monitor.log"
   
   # Function to get system information
   get_system_info() {
       cat << EOF
   ╔══════════════════════════════════════════════════════════════╗
   ║                    SYSTEM MONITORING DASHBOARD               ║
   ║                    Last Updated: $(date)         ║
   ╚══════════════════════════════════════════════════════════════╝
   
   SYSTEM INFORMATION:
   ├─ Hostname: $(hostname)
   ├─ Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
   ├─ Users: $(who | wc -l) logged in
   └─ Load Average: $(uptime | awk -F'load average:' '{print $2}')
   
   MEMORY USAGE:
   $(free -h | awk '
   NR==1 {printf "├─ %-12s %8s %8s %8s %8s\n", $1, $2, $3, $4, $7}
   NR==2 {printf "├─ %-12s %8s %8s %8s %8s\n", $1":", $2, $3, $4, $7}
   NR==3 {printf "└─ %-12s %8s %8s\n", $1":", $2, $3}')
   
   DISK USAGE (>80% highlighted):
   EOF
   
       df -h | awk 'NR>1 {
           usage = int($5)
           if (usage > 80)
               printf "├─ 🔴 %-20s %6s %6s %6s %4s %s\n", $6, $2, $3, $4, $5, $1
           else if (usage > 60)
               printf "├─ 🟡 %-20s %6s %6s %6s %4s %s\n", $6, $2, $3, $4, $5, $1
           else
               printf "├─ 🟢 %-20s %6s %6s %6s %4s %s\n", $6, $2, $3, $4, $5, $1
       }' | head -5
       
       echo
       echo "TOP PROCESSES (by CPU):"
       ps aux --sort=-%cpu | head -6 | awk '
       NR==1 {printf "├─ %-8s %4s %4s %6s %6s %-8s %s\n", $1, $2, $3, $4, $5, $8, $11}
       NR>1 {printf "├─ %-8s %4s %4s %6s %6s %-8s %s\n", $1, $2, $3, $4, $5, $8, $11}'
       
       echo
       echo "NETWORK CONNECTIONS:"
       echo "├─ Active connections: $(netstat -tun 2>/dev/null | grep ESTABLISHED | wc -l)"
       echo "├─ Listening ports: $(netstat -tln 2>/dev/null | grep LISTEN | wc -l)"
       
       if command -v ss >/dev/null; then
           echo "└─ Socket summary:"
           ss -s | grep -E "TCP|UDP" | sed 's/^/   /'
       fi
   }
   
   # Function to log system status
   log_status() {
       {
           echo "$(date): System check"
           echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
           echo "Memory: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
           echo "Disk: $(df / | awk 'NR==2{print $5}')"
           echo "---"
       } >> "$LOG_FILE"
   }
   
   # Function for interactive mode
   interactive_mode() {
       while true; do
           clear
           get_system_info
           
           echo
           echo "Options: [r]efresh [l]ogs [q]uit [s]ave report"
           read -t $REFRESH_INTERVAL -n 1 -s choice
           
           case $choice in
               r|R) continue ;;
               l|L) 
                   clear
                   echo "=== Recent Log Entries ==="
                   tail -20 "$LOG_FILE" 2>/dev/null || echo "No log file found"
                   read -p "Press Enter to continue..."
                   ;;
               s|S)
                   report_file="system_report_$(date +%Y%m%d_%H%M%S).txt"
                   get_system_info > "$report_file"
                   echo "Report saved to: $report_file"
                   read -p "Press Enter to continue..."
                   ;;
               q|Q) break ;;
           esac
           
           log_status
       done
   }
   
   # Function to check for alerts
   check_alerts() {
       local alerts=()
       
       # Check disk usage
       df -h | awk 'NR>1 && int($5) > 90 {print "CRITICAL: Disk " $6 " is " $5 " full"}' | while read alert; do
           echo "$alert"
           alerts+=("$alert")
       done
       
       # Check memory usage
       local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
       if [ $mem_usage -gt 90 ]; then
           echo "CRITICAL: Memory usage is ${mem_usage}%"
       fi
       
       # Check load average
       local load=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
       local cpu_count=$(nproc)
       if (( $(echo "$load > $cpu_count" | bc -l) )); then
           echo "WARNING: Load average ($load) exceeds CPU count ($cpu_count)"
       fi
   }
   
   # Function to display usage
   usage() {
       cat << EOF
   System Monitor Script
   
   Usage: $0 [OPTIONS]
   
   OPTIONS:
       -i, --interactive    Run in interactive mode (default)
       -o, --once          Show status once and exit
       -a, --alerts        Check for system alerts
       -l, --log           Show recent log entries
       -h, --help          Show this help
   
   Interactive Mode Commands:
       r - Refresh display
       l - View logs
       s - Save report
       q - Quit
   EOF
   }
   
   # Main execution
   case ${1:-"-i"} in
       -i|--interactive)
           interactive_mode
           ;;
       -o|--once)
           get_system_info
           log_status
           ;;
       -a|--alerts)
           echo "=== System Alerts ==="
           check_alerts
           ;;
       -l|--log)
           echo "=== Recent System Monitor Logs ==="
           tail -20 "$LOG_FILE" 2>/dev/null || echo "No log file found"
           ;;
       -h|--help)
           usage
           ;;
       *)
           echo "Unknown option: $1"
           usage
           exit 1
           ;;
   esac
   ```

3. Test the monitoring script:
   ```bash
   chmod +x monitor.sh
   ./monitor.sh --once
   ./monitor.sh --alerts
   # ./monitor.sh --interactive  # Try this for the full experience
   ```

**Final Questions:**
- How could you extend this monitoring script for production use?
- What additional system metrics would be valuable to monitor?
- How would you implement alerting (email, SMS, etc.) when thresholds are exceeded?

---

## Lab Summary

### Completed Exercises
- ✅ Basic script creation and execution
- ✅ Special variables and command-line arguments
- ✅ Quoting rules and literal handling
- ✅ Conditional statements and testing
- ✅ Loops and iteration patterns
- ✅ Function definition and usage
- ✅ User input and validation
- ✅ Error handling and logging
- ✅ Real-world script applications

### Key Skills Developed
1. **Script Structure**: Proper shebang, comments, and organization
2. **Variable Handling**: Assignment, expansion, and quoting
3. **Control Flow**: Conditionals, loops, and case statements
4. **Function Programming**: Parameter passing and return values
5. **Error Management**: Validation, logging, and graceful failures
6. **User Interaction**: Input prompting and menu systems
7. **File Operations**: Reading, writing, and processing files
8. **System Integration**: Monitoring, backup, and administration

### Next Steps
- Practice writing scripts for your daily tasks
- Study existing system scripts in `/etc/init.d/` and `/usr/local/bin/`
- Learn about advanced bash features (arrays, parameter expansion)
- Explore other scripting languages (Python, Perl) for complex tasks
- Implement error handling and logging in all your scripts

### Additional Resources
- Use `shellcheck` to validate your scripts
- Study the Bash manual: `man bash`
- Practice with online shell scripting challenges
- Build a personal library of useful functions
- Document your scripts with proper comments and usage information