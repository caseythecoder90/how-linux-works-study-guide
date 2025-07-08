# Chapter 11: Shell Scripting

## Overview
This chapter introduces shell scripting with the Bourne shell (bash), covering everything from basic script creation to advanced topics like functions, loops, and user input. Shell scripting is essential for automating system administration tasks, batch file processing, and creating custom tools.

## Learning Objectives
By the end of this chapter, you should be able to:
- [ ] Write and execute basic shell scripts
- [ ] Understand quoting rules and literal handling
- [ ] Use special variables ($1, $#, $@, $0, $$, $?)
- [ ] Implement exit codes and error handling
- [ ] Create conditional statements (if/then/else)
- [ ] Write loops (for, while) for iteration
- [ ] Define and use functions
- [ ] Handle user input with the read command
- [ ] Include other files in scripts
- [ ] Know when NOT to use shell scripts

## Prerequisites
- Understanding of basic shell commands (Chapter 2)
- Knowledge of file permissions and execution
- Familiarity with variables and environment concepts
- Text editor skills for script creation

## Key Concepts
- **Shebang (#!)**: Script interpreter declaration
- **Quoting**: Literal handling with single/double quotes
- **Special Variables**: $1-$9, $#, $@, $0, $$, $?
- **Exit Codes**: Success (0) and error status codes
- **Conditionals**: if/then/else logic structures
- **Loops**: for and while iteration constructs
- **Functions**: Code reusability and organization
- **Input/Output**: Reading user input and managing streams

## Chapter Structure
- **notes.md**: Comprehensive notes covering all topics
- **flashcards.md**: Key terms and concepts for review
- **examples/**: Practical code examples and script templates
- **exercises/**: Practice problems and lab exercises
- **cheatsheet.md**: Quick reference for commands and syntax

## Estimated Study Time
- **Reading**: 3 hours
- **Examples**: 2 hours
- **Exercises**: 4 hours
- **Review**: 1 hour
- **Total**: 10 hours

## Files and Directories Covered
Key system files and directories discussed in this chapter:
- `/bin/sh` - Bourne shell interpreter
- `/bin/bash` - Bash shell interpreter
- `/usr/bin/env` - Environment-based interpreter selection
- `~/.bashrc` - User shell configuration
- `/etc/bash.bashrc` - System-wide bash configuration

## Important Commands
Essential commands introduced in this chapter:
- `#!/bin/sh` - Shebang for Bourne shell scripts
- `#!/bin/bash` - Shebang for Bash scripts
- `chmod +x script.sh` - Make script executable
- `./script.sh` - Execute script from current directory
- `bash script.sh` - Execute script with bash
- `sh script.sh` - Execute script with sh
- `echo` - Output text and variables
- `read` - Read user input
- `test` / `[ ]` - Conditional testing
- `shift` - Shift positional parameters

## Related Chapters
- **Previous**: Chapter 10 - Network Configuration
- **Next**: Chapter 12 - Moving Files
- **Related**: Chapter 2 (Basic Commands), Chapter 15 (Development Tools)

## Review Checklist
- [ ] Read chapter notes thoroughly
- [ ] Complete all script examples
- [ ] Practice with flashcards
- [ ] Complete exercises
- [ ] Review cheatsheet
- [ ] Write your own practice scripts
- [ ] Test knowledge with real automation tasks

## Notes
- Always test scripts in a safe environment before production use
- Remember that shell scripts are best for simple automation tasks
- For complex tasks, consider Python, Perl, or other scripting languages
- Pay special attention to quoting rules - they're a common source of errors