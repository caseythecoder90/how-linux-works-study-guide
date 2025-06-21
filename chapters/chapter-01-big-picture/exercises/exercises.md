# Chapter 1: The Big Picture - Practice Exercises and Labs

## Lab Exercise 1: System Architecture Exploration

### Objective
Explore the three levels of Linux system architecture using command-line tools.

### Part A: Hardware Level Investigation

**Step 1: CPU Information**
```bash
# View CPU details
lscpu
cat /proc/cpuinfo

# Questions to answer:
# - How many CPU cores do you have?
# - What is the CPU architecture?
# - What is the CPU frequency?
```

**Step 2: Memory Investigation**
```bash
# View memory information
free -h
cat /proc/meminfo | head -20

# Questions to answer:
# - How much total RAM is available?
# - How much memory is currently in use?
# - What is the difference between 'available' and 'free' memory?
```

**Step 3: Device Discovery**
```bash
# List block devices
lsblk

# List all devices
ls -l /dev/ | head -20

# Look at specific device types
ls -l /dev/sd*    # SCSI/SATA devices
ls -l /dev/tty*   # Terminal devices

# Questions to answer:
# - What storage devices are attached to your system?
# - Can you identify any pseudodevices in /dev/?
```

### Part B: Kernel Level Exploration

**Step 4: Kernel Information**
```bash
# Kernel version and details
uname -a
cat /proc/version

# Kernel modules (drivers)
lsmod | head -10

# System call information
man syscalls

# Questions to answer:
# - What kernel version are you running?
# - What are some loaded kernel modules and their purposes?
```

**Step 5: Process Management Observation**
```bash
# View all processes
ps aux

# Dynamic process view
top
# (Press 'q' to quit top)

# Process tree
pstree

# Questions to answer:
# - What is the PID of the init process?
# - How many processes are currently running?
# - Can you identify kernel threads (usually in square brackets)?
```

### Part C: User Space Investigation

**Step 6: User Process Analysis**
```bash
# Current user information
whoami
id

# User processes only
ps -u $(whoami)

# Process hierarchy
ps -ef --forest

# Questions to answer:
# - What is your user ID?
# - What processes are you running?
# - Can you trace the parent