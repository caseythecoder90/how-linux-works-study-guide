# Chapter 13: User Environments - Lab Exercises

## Exercise 1: Basic Startup File Configuration

### Objective
Set up a basic bash environment with proper startup files.

### Tasks
1. Create a `.bashrc` file with the following features:
   - Interactive shell check
   - Basic history settings (HISTSIZE=500, no duplicates)
   - Simple colored prompt showing user@hostname:directory
   - PATH that includes `~/bin`
   - umask of 022

2. Create a `.bash_profile` that sources `.bashrc`

3. Create at least 5 useful aliases

4. Test your configuration by opening a new terminal

### Solution Template
```bash
# ~/.bashrc
case $- in
    *i*) ;;
      *) return;;
esac

# Your code here
```

---

## Exercise 2: Advanced Environment Configuration

### Objective
Create a more sophisticated user environment with functions and conditional loading.

### Tasks
1. Modify your `.bashrc` to include:
   - Conditional PATH additions (only if directories exist)
   - Function to create and enter directory (`mkcd`)
   - Function to backup files with timestamp
   - Conditional loading of bash completion

2. Create separate `.bash_aliases` file and source it from `.bashrc`

3. Set up environment variables for:
   - EDITOR (vim or nano)
   - PAGER (less with color support)
   - Custom LESS options

4. Add safety aliases for destructive commands

### Verification
- Test that `mkcd test_dir` creates and enters the directory
- Verify that PATH includes your custom directories
- Check that aliases work as expected

---

## Exercise 3: Shell Function Development

### Objective
Create useful shell functions that demonstrate best practices.

### Tasks
Create the following functions in your `.bashrc`:

1. **extract()** - Extract various archive formats
   ```bash
   # Should handle: .tar.gz, .zip, .tar.bz2, .rar, .7z
   extract archive.tar.gz
   ```

2. **findtext()** - Search for text in files
   ```bash
   # Usage: findtext "search term" [directory]
   findtext "TODO" ~/projects
   ```

3. **backup_config()** - Backup important configuration files
   ```bash
   # Should backup .bashrc, .vimrc, .gitconfig to ~/backups/
   backup_config
   ```

4. **weather()** - Get weather information (using curl)
   ```bash
   # Usage: weather [city]
   weather "New York"
   ```

### Requirements
- All functions should include error checking
- Functions should provide usage information if called incorrectly
- Use local variables where appropriate

---

## Exercise 4: Environment Security and Best Practices

### Objective
Implement security best practices in your startup files.

### Tasks
1. **Security Audit**:
   - Check permissions on all startup files (should be 644 or 600)
   - Ensure no sensitive information in startup files
   - Verify umask is appropriate for your environment

2. **PATH Security**:
   - Remove any current directory (.) from PATH
   - Ensure PATH directories are owned by root or user
   - Check that PATH directories are not world-writable

3. **Environment Cleanup**:
   - Remove any unnecessary environment variables
   - Clean up old aliases and functions
   - Ensure startup files don't produce output in non-interactive mode

4. **Documentation**:
   - Add comments explaining each major section
   - Document any non-obvious aliases or functions
   - Create a README file explaining your setup

### Verification Script
```bash
#!/bin/bash
# Environment security check
echo "=== Security Check ==="

# Check file permissions
for file in ~/.bashrc ~/.bash_profile ~/.bash_aliases; do
    if [ -f "$file" ]; then
        perms=$(stat -c %a "$file" 2>/dev/null || stat -f %Lp "$file")
        echo "$file: $perms"
    fi
done

# Check PATH security
echo "$PATH" | tr ':' '\n' | while read dir; do
    if [ -d "$dir" ]; then
        ls -ld "$dir"
    fi
done

# Check for current directory in PATH
if [[ ":$PATH:" == *":."* ]]; then
    echo "WARNING: Current directory (.) found in PATH"
fi
```

---

## Study Questions for Review

1. What's the difference between login and non-login shells, and how does this affect startup file execution?

2. Why should you avoid setting LD_LIBRARY_PATH in startup files?

3. How would you troubleshoot a situation where your aliases aren't loading?

4. What security considerations should you keep in mind when creating startup files?

5. How can you optimize startup time for a slow-loading environment?

6. What's the proper way to add directories to PATH in a startup file?

7. How do you handle differences between operating systems in portable startup files?

8. What's the difference between aliases and functions, and when should you use each?

9. How do you test startup files without breaking your current environment?

10. What information should and shouldn't be included in a shell prompt?

---

## Submission Guidelines

For each exercise, submit:
1. Your configuration files (`.bashrc`, `.bash_profile`, etc.)
2. Any custom scripts or functions created
3. Documentation explaining your choices
4. Test results showing everything works correctly
5. Reflection on what you learned

Remember to:
- Test all configurations thoroughly
- Include error handling in scripts
- Document any assumptions or requirements
- Follow security best practices
- Make your code readable and maintainable
