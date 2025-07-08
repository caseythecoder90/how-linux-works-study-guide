# Chapter 11: Shell Scripting - Flashcards

## Basic Concepts

### Card 1
**Q:** What is the shebang line and what does it do?
**A:** `#!/bin/bash` or `#!/bin/sh` - tells the system which interpreter to use when executing the script.

### Card 2
**Q:** What's the difference between single quotes and double quotes in shell scripts?
**A:** Single quotes preserve everything literally, double quotes allow variable substitution and command substitution.

### Card 3
**Q:** How do you make a shell script executable?
**A:** `chmod +x script.sh`

### Card 4
**Q:** What are the three ways to execute a shell script?
**A:** `./script.sh` (if executable), `bash script.sh`, or `sh script.sh`

### Card 5
**Q:** What exit code indicates success in a shell script?
**A:** 0 (zero)

## Special Variables

### Card 6
**Q:** What does the `$1` variable contain?
**A:** The first command-line argument passed to the script.

### Card 7
**Q:** What does `$#` represent?
**A:** The number of command-line arguments passed to the script.

### Card 8
**Q:** What does `$@` contain?
**A:** All command-line arguments passed to the script.

### Card 9
**Q:** What does `$0` represent?
**A:** The name of the script itself.

### Card 10
**Q:** What does `$$` contain?
**A:** The process ID (PID) of the current shell script.

### Card 11
**Q:** What does `$?` represent?
**A:** The exit code of the last command that was executed.

### Card 12
**Q:** What does the `shift` command do?
**A:** Removes the first argument ($1) and shifts all remaining arguments down by one position.

## Quoting and Literals

### Card 13
**Q:** How would you print the literal string `$100` using echo?
**A:** `echo '$100'` (single quotes prevent variable expansion)

### Card 14
**Q:** What's the problem with this command: `grep r.*t /etc/passwd`?
**A:** If files like `r.input` and `r.output` exist in the current directory, the shell will expand `r.*t` to those filenames instead of treating it as a regex.

### Card 15
**Q:** How do you include a literal single quote inside a single-quoted string?
**A:** End the single-quoted string, add an escaped single quote, then start a new single-quoted string: `'don'\''t'`

### Card 16
**Q:** What's the difference between `echo $name` and `echo "$name"`?
**A:** Both expand the variable, but the quoted version preserves any whitespace in the variable value and prevents word splitting.

## Conditionals and Tests

### Card 17
**Q:** What's the syntax for a basic if statement in bash?
**A:** `if [ condition ]; then commands; fi`

### Card 18
**Q:** How do you test if a file exists?
**A:** `[ -f "filename" ]`

### Card 19
**Q:** How do you test if a directory exists?
**A:** `[ -d "dirname" ]`

### Card 20
**Q:** What's the operator to test if two numbers are equal?
**A:** `-eq` (example: `[ $a -eq $b ]`)

### Card 21
**Q:** How do you test if a string is empty?
**A:** `[ -z "$string" ]`

### Card 22
**Q:** How do you test if a string is NOT empty?
**A:** `[ -n "$string" ]`

### Card 23
**Q:** What's the difference between `=` and `==` in bash conditionals?
**A:** `=` is POSIX standard for string equality, `==` is bash-specific but works the same way.

## Loops

### Card 24
**Q:** What's the syntax for a for loop that iterates over a list?
**A:** `for item in list; do commands; done`

### Card 25
**Q:** How do you write a for loop that processes all script arguments?
**A:** `for arg in "$@"; do commands; done`

### Card 26
**Q:** What's the syntax for a basic while loop?
**A:** `while [ condition ]; do commands; done`

### Card 27
**Q:** How do you create an infinite loop in bash?
**A:** `while true; do commands; done`

### Card 28
**Q:** How do you break out of a loop?
**A:** Use the `break` command

## Functions

### Card 29
**Q:** What's the basic syntax for defining a function in bash?
**A:** `function_name() { commands; }` or `function function_name() { commands; }`

### Card 30
**Q:** How do you access the first parameter passed to a function?
**A:** `$1` (same as script arguments, but local to the function)

### Card 31
**Q:** How do you declare a local variable in a function?
**A:** `local variable_name=value`

### Card 32
**Q:** How do you return a value from a function?
**A:** Use `echo` to output the value, then capture it with command substitution: `result=$(function_name)`

### Card 33
**Q:** What does `return 0` do in a function?
**A:** Sets the function's exit status to 0 (success) - used for true/false functions.

## Input/Output

### Card 34
**Q:** How do you read user input into a variable?
**A:** `read variable_name`

### Card 35
**Q:** How do you prompt the user and read input in one line?
**A:** `read -p "Enter value: " variable_name`

### Card 36
**Q:** How do you read a password without showing it on screen?
**A:** `read -s password`

### Card 37
**Q:** How do you redirect error messages to stderr?
**A:** `echo "error message" >&2`

## File Operations

### Card 38
**Q:** How do you check if a file is readable?
**A:** `[ -r "filename" ]`

### Card 39
**Q:** How do you check if a file is writable?
**A:** `[ -w "filename" ]`

### Card 40
**Q:** How do you check if a file is executable?
**A:** `[ -x "filename" ]`

### Card 41
**Q:** How do you check if a file exists and is not empty?
**A:** `[ -s "filename" ]`

## Advanced Concepts

### Card 42
**Q:** How do you include another script file in your current script?
**A:** `. filename.sh` or `source filename.sh`

### Card 43
**Q:** What's command substitution and how do you use it?
**A:** Capturing command output in a variable: `variable=$(command)` or `variable=`command``

### Card 44
**Q:** How do you enable strict error handling in a bash script?
**A:** `set -e` (exit on error), `set -u` (exit on undefined variable), or `set -euo pipefail`

### Card 45
**Q:** What's the syntax for a case statement?
**A:** `case $variable in pattern1) commands;; pattern2) commands;; *) default;; esac`

## Best Practices

### Card 46
**Q:** When should you NOT use shell scripts?
**A:** For complex string manipulation, arithmetic operations, database work, or large applications - use Python/Perl instead.

### Card 47
**Q:** How should you handle command-line arguments validation?
**A:** Check `$#` for argument count and test each required argument: `[ $# -eq 0 ] && { echo "Usage: $0 <arg>"; exit 1; }`

### Card 48
**Q:** What's a good practice for error messages in scripts?
**A:** Include the script name using `$0` and redirect to stderr: `echo "$0: error message" >&2`

### Card 49
**Q:** How do you make your script more robust against errors?
**A:** Use `set -e` to exit on errors, quote all variables, check command success, and validate inputs.

### Card 50
**Q:** What tool can help you find common errors in shell scripts?
**A:** `shellcheck` - a static analysis tool for shell scripts.