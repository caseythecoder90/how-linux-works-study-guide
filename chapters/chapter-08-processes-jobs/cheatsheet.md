# Chapter 8: Process Monitoring and Resource Utilization - Quick Reference

## Essential Process Monitoring Commands

### Basic Process Tracking
```bash
# Real-time process monitor
top

# Enhanced process monitors
htop                    # More user-friendly interface
atop                    # Additional features and views

# Monitor specific processes
top -p 1234 -p 5678     # Monitor specific PIDs
```

### Top Interactive Commands
```bash
# While in top, press these keys:
M          # Sort by memory usage
T          # Sort by total CPU time
P          # Sort by current CPU usage (default)
u          # Show only one user's processes
f          # Select different statistics to display
Space      # Update display immediately
?          # Help screen
```

## File and Resource Access Monitoring

### lsof - List Open Files
```bash
# Basic usage
lsof                    # List all open files (massive output)
lsof | less            # Pipe to less for browsing

# Filter by directory
lsof +D /usr           # Files in /usr and subdirectories
lsof /var/log/syslog   # Specific file

# Filter by process
lsof -p 1234           # Files for specific PID
lsof -u username       # Files for specific user

# Network connections
lsof -i                # All network connections
lsof -i :80            # Connections on port 80
lsof -i TCP:443        # TCP connections on port 443

# Performance options
lsof -n                # No hostname resolution (faster)
lsof -P                # No port name resolution
```

### lsof Output Fields
```
COMMAND  PID  USER  FD   TYPE  DEVICE  SIZE/OFF  NODE  NAME
systemd   1   root  cwd  DIR   8,1     4096      2     /
```
- **FD**: File descriptor or purpose (cwd, rtd, txt, number)
- **TYPE**: REG (file), DIR (directory), CHR (character device), etc.

## System Call and Library Tracing

### strace - System Call Tracing
```bash
# Basic tracing
strace command                    # Trace a command
strace -p 1234                   # Attach to running process

# Output control
strace -o trace.log command      # Save to file
strace -f command                # Follow forked processes
strace -ff -o trace command      # Separate files for each process

# Daemon tracing
strace -o daemon_trace -ff mydaemon
```

### ltrace - Library Call Tracing
```bash
# Basic library tracing
ltrace command                   # Trace library calls
ltrace -p 1234                  # Attach to process
```

## Thread Monitoring

### Viewing Threads
```bash
# Show threads with ps
ps m                            # Show processes and threads
ps m -o pid,tid,command         # Custom format with TIDs

# Show threads in top
# Press 'H' while in top to toggle thread view
```

## CPU and Performance Monitoring

### Time Measurement
```bash
# Built-in time (basic)
time command

# System time (detailed)
/usr/bin/time -v command        # Verbose output with memory stats
```

### Load Averages
```bash
uptime                          # Show load averages
w                              # Load averages + logged in users
```

### Process Priority Management
```bash
# View priorities
ps -l                          # Long format with priorities
top                           # PR and NI columns

# Change priority
renice 10 1234                # Set nice value to 10 for PID 1234
renice -5 1234                # Higher priority (root only)

# Start with different priority
nice -n 10 command            # Start with nice value 10
```

## Memory Monitoring

### Page Fault Analysis
```bash
# View page faults for process
ps -o pid,min_flt,maj_flt 1234

# In top, press 'f' and select:
# nMaj - major page faults
# vMj  - major page faults since last update
```

## System-Wide Resource Monitoring

### vmstat - Virtual Memory Statistics
```bash
# One-time snapshot
vmstat

# Continuous monitoring
vmstat 2                       # Update every 2 seconds
vmstat 2 10                    # 10 updates, 2 seconds apart
```

### vmstat Output Guide
```
procs ----memory---- ---swap-- -----io---- -system-- ----cpu----
 r  b  swpd  free   buff cache  si so  bi bo  in   cs us sy id wa
```
- **r**: Ready to run processes
- **b**: Blocked processes
- **si/so**: Swap in/out (KB/s)
- **bi/bo**: Block in/out (blocks/s)
- **us/sy/id/wa**: User/System/Idle/Wait time (%)

## I/O Monitoring

### iostat - I/O Statistics
```bash
# Basic I/O stats
iostat

# Continuous monitoring
iostat 2                       # Every 2 seconds
iostat -d 2                    # Device report only
iostat -p ALL                  # Include all partitions
```

### iotop - Per-Process I/O
```bash
# Interactive I/O monitor
sudo iotop

# Options
iotop -o                       # Only show processes with I/O
iotop -a                       # Accumulated I/O instead of bandwidth
```

### I/O Priority Management
```bash
# Check I/O priority
ionice -p 1234

# Set I/O priority
ionice -c 3 command            # Idle class
ionice -c 2 -n 4 command       # Best effort, priority 4
ionice -c 1 -n 2 command       # Real-time, priority 2 (root only)
```

## Per-Process Resource Monitoring

### pidstat - Process Statistics Over Time
```bash
# CPU monitoring
pidstat -p 1234 2              # Monitor PID 1234 every 2 seconds

# Memory monitoring
pidstat -r -p 1234 2           # Memory stats

# I/O monitoring
pidstat -d -p 1234 2           # Disk I/O stats

# Context switching
pidstat -w -p 1234 2           # Context switch stats

# All processes
pidstat 2                      # All processes every 2 seconds
```

## Control Groups (cgroups)

### Viewing cgroups
```bash
# View process cgroups
cat /proc/self/cgroup           # Current shell
cat /proc/1234/cgroup          # Specific process

# Navigate cgroup filesystem
cd /sys/fs/cgroup/user.slice/user-1000.slice/session-2.scope/
ls                             # List cgroup files

# View cgroup contents
cat cgroup.procs               # Processes in cgroup
cat cgroup.threads            # Threads in cgroup
cat cgroup.controllers        # Available controllers
```

### cgroup Resource Monitoring
```bash
# CPU usage
cat cpu.stat

# Memory usage  
cat memory.current             # Current memory usage
cat memory.max                # Memory limit
cat memory.stat               # Detailed memory stats

# Process/thread counts
cat pids.current              # Current PID count
cat pids.max                  # PID limit
```

### cgroup Management (Root Required)
```bash
# Add process to cgroup
echo 1234 > cgroup.procs

# Set limits
echo 100M > memory.max         # 100MB memory limit
echo 1000 > pids.max          # Limit to 1000 processes

# Create new cgroup
mkdir /sys/fs/cgroup/my-cgroup

# Enable controllers for child cgroups
echo "+cpu +memory" > cgroup.subtree_control
```

## systemd Integration

### systemd cgroup Commands
```bash
# View systemd cgroup tree
systemd-cgls

# View service status with cgroup info
systemctl status servicename

# View service logs
journalctl -u servicename
```

## Quick Diagnostic Workflows

### System Performance Check
```bash
# 1. Overall system status
uptime                         # Load averages
free -h                       # Memory usage
df -h                         # Disk space

# 2. Process analysis
top                           # Current resource usage
ps aux --sort=-%cpu | head    # Top CPU users
ps aux --sort=-%mem | head    # Top memory users

# 3. I/O analysis
iostat 2 5                   # I/O patterns
iotop                        # Per-process I/O
```

### Process Debugging Workflow
```bash
# 1. Find the problematic process
ps aux | grep process_name
top                          # Real-time view

# 2. Analyze file/network access
lsof -p PID                  # What files is it accessing?
lsof -i -p PID              # Network connections

# 3. Trace system calls (if needed)
strace -p PID                # What is it trying to do?
strace -o trace.log command  # Trace from start
```

### Memory Issue Investigation
```bash
# 1. System memory overview
free -h
cat /proc/meminfo

# 2. Process memory usage
ps aux --sort=-%mem | head
top                          # Press 'M' to sort by memory

# 3. Memory activity
vmstat 2                     # Watch for swapping (si/so columns)
pidstat -r 2                 # Per-process memory over time
```

## Common Output Interpretations

### High Load Average
- **Load = CPU count**: Fully utilized but not overloaded
- **Load > CPU count**: More demand than capacity
- **High load + responsive system**: Likely CPU-bound but healthy
- **High load + slow system**: Possible memory thrashing

### Memory Pressure Signs
- **vmstat**: High 'si'/'so' values (swapping)
- **free**: Low available memory
- **iotop**: High I/O from kernel threads like kswapd

### I/O Bottlenecks
- **vmstat**: High 'wa' (wait) percentage
- **iostat**: High utilization percentages
- **iotop**: Processes with high I/O rates

## Emergency Commands

### Kill Runaway Processes
```bash
# Find and kill by name
pkill process_name
killall process_name

# Kill by PID
kill 1234
kill -9 1234                 # Force kill

# Kill all user processes
pkill -u username
```

### Resource Limits (Temporary)
```bash
# Limit memory for command
ulimit -v 100000             # Virtual memory limit (KB)
command

# Run with low priority
nice -n 19 cpu_intensive_command
```

This quick reference provides the essential commands and workflows for process monitoring and resource utilization analysis in Linux systems.