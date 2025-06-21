# Chapter 8: A Closer Look at Processes and Resource Utilization - Comprehensive Notes

## Overview and Philosophy

### Three Basic Hardware Resources
Linux systems have three fundamental hardware resources that processes compete for:
1. **CPU** - Processing power for computation
2. **Memory** - RAM for data storage and program execution
3. **I/O** - Input/output operations (disk, network, etc.)

The kernel's primary job is to allocate these resources fairly among processes. The kernel itself is also a resource - a software resource that processes use for system calls and process management.

### Performance Monitoring Philosophy
- **Focus on understanding, not optimization** - Learn how tools work and what they measure
- **Don't prematurely optimize** - Default settings are usually well-chosen
- **Use tools to understand kernel behavior** rather than just chasing performance metrics
- **Change settings only for very unusual needs**

---

## 8.1 Tracking Processes

### Beyond Static Process Listings
The `ps` command shows a snapshot at a specific moment, but doesn't help with:
- Understanding how processes change over time
- Identifying which process is consuming too much CPU or memory
- Seeing real-time resource utilization

### The `top` Command - Interactive Process Monitor
**Basic Usage:**
```bash
top
```

**Key Interactive Commands:**
- **Spacebar** - Update display immediately
- **M** - Sort by current resident memory usage
- **T** - Sort by total (cumulative) CPU usage
- **P** - Sort by current CPU usage (default)
- **u** - Display only one user's processes
- **f** - Select different statistics to display
- **?** - Display usage summary

**Important Note:** All top commands are case-sensitive.

### Enhanced Alternatives
- **`atop`** - Enhanced features and additional views
- **`htop`** - More user-friendly interface with better visualization
- Both offer functionality similar to other tools (like `lsof` capabilities)

---

## 8.2 Finding Open Files with lsof

### Why lsof is Crucial
Unix philosophy emphasizes files, making `lsof` one of the most useful troubleshooting tools. It can list:
- Regular files
- Network resources
- Dynamic libraries
- Pipes
- Device files

### Understanding lsof Output
**Sample Output:**
```
COMMAND    PID  USER   FD      TYPE     DEVICE  SIZE/OFF  NODE NAME
systemd      1  root  cwd       DIR        8,1      4096     2 /
systemd      1  root  rtd       DIR        8,1      4096     2 /
systemd      1  root  txt       REG        8,1   1595792  9961784 /lib/systemd/systemd
vi        1994 juser    3u       REG        8,1     12288   786440 /tmp/.ff.swp
```

**Field Explanations:**
- **COMMAND** - Process name holding the file descriptor
- **PID** - Process ID
- **USER** - User running the process
- **FD** - File descriptor number OR purpose (cwd=current working directory, rtd=root directory, txt=executable text)
- **TYPE** - File type (REG=regular file, DIR=directory, CHR=character device, etc.)
- **DEVICE** - Major and minor device numbers
- **SIZE/OFF** - File size or offset
- **NODE** - Inode number
- **NAME** - Filename or resource name

### Using lsof Effectively
**Two Main Approaches:**
1. **List everything and filter:**
   ```bash
   lsof | less
   # Then search within the output
   ```

2. **Use command-line options to narrow results:**
   ```bash
   # Files in specific directory
   lsof +D /usr
   
   # Files for specific process
   lsof -p 1234
   
   # Brief help summary
   lsof -h
   ```

**Performance Tips:**
- Run as root for complete information
- Use `-n` to disable hostname resolution (speeds up output)
- Use `-P` to disable port name lookups

---

## 8.3 Tracing Program Execution and System Calls

### When Static Tools Aren't Enough
For programs that:
- Die immediately after starting
- Have mysterious failures
- Need deep debugging

Use tracing tools to see exactly what the program attempts to do.

### 8.3.1 strace - System Call Tracing

**Basic Concept:**
System calls are privileged operations that user processes ask the kernel to perform (opening files, reading data, etc.). `strace` shows all system calls a process makes.

**Basic Usage:**
```bash
strace cat /dev/null
```

**Key Features:**
- Output goes to stderr by default
- Use `-o filename` to save output to file
- Traces the new process after `fork()` system call

**Example Trace Analysis:**
```bash
# Successful file open
openat(AT_FDCWD, "/dev/null", O_RDONLY) = 3

# Failed file open  
openat(AT_FDCWD, "not_a_file", O_RDONLY) = -1 ENOENT (No such file or directory)
```

**Advanced Usage:**
```bash
# Trace daemon and all child processes
strace -o daemon_trace -ff mydaemon

# Follow forked processes
strace -f command
```

**What to Look For:**
- `execve()` calls showing program startup
- `openat()` or `open()` calls for file access
- Error returns (-1) with descriptive error messages
- Missing files (most common Unix program problem)

### 8.3.2 ltrace - Library Call Tracing

**Purpose:** Tracks shared library calls rather than kernel system calls.

**Characteristics:**
- Similar output format to `strace`
- Shows user-space library interactions
- Generates even more output than `strace`
- Built-in filtering options
- Doesn't work with statically linked binaries

**Usage:**
```bash
ltrace command
```

---

## 8.4 Threads

### Understanding Threads vs Processes

**Thread Characteristics:**
- Similar to processes - have Thread ID (TID) and are scheduled by kernel
- **Key Difference:** Threads within a process share system resources and memory
- All processes start single-threaded with a "main thread"
- Main thread can create additional threads (like `fork()` creates processes)

### Single-Threaded vs Multithreaded Processes
**Single-threaded:** Only one thread (the main thread)
**Multithreaded:** Multiple threads within one process

**Advantages of Multithreading:**
- **Parallel computation** on multiple processors
- **Faster thread startup** compared to new processes
- **Shared memory communication** easier than inter-process communication
- **Better I/O management** without subprocess overhead

### 8.4.2 Viewing Threads

**Using ps with threads:**
```bash
# Show threads
ps m

# Custom format showing PIDs and TIDs
ps m -o pid,tid,command
```

**Sample Output:**
```
  PID   TID COMMAND
 3587     - bash
    -  3587 -
12534     - /usr/lib/xorg/Xorg
    - 12534 -
    - 13227 -
    - 14443 -
```

**Understanding the Output:**
- Lines with PID numbers = processes
- Lines with dashes in PID = threads
- When TID = PID, that's the main thread
- Single-threaded processes show TID = PID

**Note:** Don't usually interact with individual threads directly unless you understand the multithreaded program's architecture.

---

## 8.5 Introduction to Resource Monitoring

### Core Philosophy
Use resource monitoring tools to:
- **Understand kernel behavior** and process interaction
- **Identify bottlenecks** when systems slow down
- **Learn how resource allocation works**
- **Not for premature optimization** of well-working systems

### 8.5.1 Measuring CPU Time

**Monitoring Specific Processes Over Time:**
```bash
# Monitor specific processes
top -p 1234 -p 5678
```

**The `time` Command:**
```bash
# Built-in shell version (basic)
time ls

# System version (more detailed)
/usr/bin/time ls
```

**Understanding Time Output:**
```
real    0m0.442s    # Total elapsed time (wall clock)
user    0m0.052s    # CPU time running program code
sys     0m0.091s    # CPU time kernel spent on process work
```

**Analysis:**
- **User time** = CPU executing program instructions
- **System time** = Kernel doing work for the process (file I/O, system calls)
- **Real time** = Total elapsed time including waiting
- **Real - (User + System)** = Time spent waiting for resources

### 8.5.2 Adjusting Process Priorities

**Understanding Priority System:**
- **Scheduling Priority:** Range -20 to +20 (-20 = highest priority)
- **Nice Value:** Hint to kernel scheduler (higher = nicer to other processes)
- **Default nice value:** 0

**Viewing Priorities:**
```bash
# See priorities with ps
ps -l

# Better view with top
top
```

**Top Priority Columns:**
- **PR (Priority)** - Current kernel scheduling priority
- **NI (Nice)** - Nice value affecting priority

**Changing Priorities:**
```bash
# Make process less aggressive (nice value 20)
renice 20 1234

# Start process with lower priority
nice -n 10 command

# Root can set negative nice values (higher priority)
sudo renice -5 1234
```

**Best Practices:**
- **Avoid negative nice values** unless absolutely necessary
- **Use positive nice values** for background computations
- **Modern single-user systems** rarely need nice adjustments

### 8.5.3 Measuring CPU Performance with Load Averages

**Load Average Definition:**
Average number of processes currently ready to run - includes:
- Processes actually running
- Processes waiting for CPU time
- Does NOT include processes waiting for input (keyboard, network, etc.)

**Viewing Load Averages:**
```bash
uptime
# Output: up 91 days, load average: 0.08, 0.03, 0.01
```

**Understanding the Numbers:**
- **Three values:** 1 minute, 5 minute, 15 minute averages
- **0.01 load average** = 1% CPU utilization (on single CPU)
- **Load = 1.0** = CPU fully utilized
- **Load > CPU count** = More demand than capacity

**Multi-CPU Considerations:**
- **2 CPUs, load 1.0** = Only one CPU active
- **2 CPUs, load 2.0** = Both CPUs fully utilized
- **Load can exceed CPU count** during high demand

**Managing High Loads:**
- **High load ≠ always problematic** if system responds well
- **Memory thrashing** can cause artificially high load averages
- **Web/compute servers** may have rapidly changing loads that don't reflect accurately

### 8.5.4 Monitoring Memory Status

**Understanding Memory Usage:**
Linux kernel manages memory through pages and virtual memory. Monitor:
- **Page faults** - When process accesses memory not currently in RAM
- **Major page faults** - Require disk access
- **Minor page faults** - Memory management without disk I/O

**Using time for Memory Analysis:**
```bash
/usr/bin/time -v command
```

**Key Memory Metrics:**
- **Page reclaims** (minor page faults)
- **Page faults** (major page faults requiring disk access)
- **Voluntary context switches**
- **Involuntary context switches**

**Viewing Page Faults with ps:**
```bash
# Show page faults for specific process
ps -o pid,min_flt,maj_flt 1234
```

**Column Meanings:**
- **MINFL** - Minor page faults
- **MAJFL** - Major page faults

### 8.5.5 Monitoring CPU and Memory Performance with vmstat

**vmstat Overview:**
One of the oldest, most efficient monitoring tools with minimal overhead. Provides high-level system view.

**Basic Usage:**
```bash
# One-time snapshot
vmstat

# Continuous monitoring (every 2 seconds)
vmstat 2
```

**Understanding vmstat Output:**
```
procs -----------memory---------- ---swap-- -----io---- -system-- ----cpu----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa
 2  0 320416 3027696 198636 1072568  0    0     1     1    2    0 15  2 83  0
```

**Column Categories and Meanings:**

**Procs:**
- **r** - Processes ready to run
- **b** - Processes blocked waiting for I/O

**Memory (KB):**
- **swpd** - Virtual memory used
- **free** - Free memory
- **buff** - Memory used as buffers
- **cache** - Memory used as cache

**Swap (KB/s):**
- **si** - Memory swapped in from disk
- **so** - Memory swapped out to disk

**I/O (blocks/s):**
- **bi** - Blocks received from block device
- **bo** - Blocks sent to block device

**System:**
- **in** - Interrupts per second
- **cs** - Context switches per second

**CPU (% of total CPU time):**
- **us** - User space time
- **sy** - System (kernel) time
- **id** - Idle time
- **wa** - Time waiting for I/O

**Analysis Tips:**
- **First line** = Average since boot (usually ignore)
- **Subsequent lines** = Current activity
- **High 'so' values** = Memory pressure, swapping occurring
- **High 'wa' values** = I/O bottleneck

### 8.5.6 I/O Monitoring

**Using iostat:**
```bash
# One-time I/O statistics
iostat

# Continuous monitoring
iostat 2

# Device-only report
iostat -d 2

# Include all partitions
iostat -p ALL
```

**Understanding iostat Output:**
```
Device:            tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
sda               4.67         7.28        49.86    9493727   65011716
```

**Field Meanings:**
- **tps** - Transfers (I/O operations) per second
- **kB_read/s** - Kilobytes read per second
- **kB_wrtn/s** - Kilobytes written per second
- **kB_read** - Total kilobytes read
- **kB_wrtn** - Total kilobytes written

**Advanced I/O Monitoring with iotop:**
```bash
# Interactive I/O process monitor
sudo iotop
```

**iotop Features:**
- **Real-time per-process I/O usage**
- **Thread-based display** (shows TIDs instead of PIDs)
- **I/O priority information**

**I/O Priority System:**
- **Format:** `be/4` (scheduling class/priority level)
- **Scheduling Classes:**
    - **be** - Best effort (default for most processes)
    - **rt** - Real time (scheduled before all other I/O)
    - **idle** - Only when no other I/O pending
- **Priority Levels:** Lower numbers = higher priority

**Managing I/O Priority:**
```bash
# Check I/O priority
ionice -p 1234

# Set I/O priority
ionice -c 1 -n 4 command  # Real-time class, priority 4
```

### 8.5.7 Per-Process Monitoring with pidstat

**pidstat Advantages:**
- **Persistent output** (doesn't refresh and erase like top)
- **Historical tracking** of process resource usage
- **Multiple monitoring types** (CPU, memory, I/O)

**Basic Usage:**
```bash
# Monitor specific process every second
pidstat -p 1329 1
```

**Sample Output:**
```
09:26:55 PM   UID   PID  %usr %system  %guest   %CPU  CPU  Command
09:27:03 PM  1000  1329  8.00    0.00    0.00   8.00    1  myprocess
```

**Advanced Options:**
```bash
# Memory monitoring
pidstat -r -p 1329 1

# Disk I/O monitoring  
pidstat -d -p 1329 1

# Context switching
pidstat -w -p 1329 1

# Threads
pidstat -t -p 1329 1
```

---

## 8.6 Control Groups (cgroups)

### Purpose and Concept
Control groups allow you to:
- **Group processes together** for resource management
- **Set resource limits** on groups of processes
- **Monitor resource usage** across process groups
- **Provide more flexibility** than traditional tools like `nice`

**Basic Workflow:**
1. Create a cgroup
2. Add processes to the cgroup
3. Use controllers to manage/limit resources
4. Monitor group resource usage

### 8.6.1 Differentiating Between cgroup Versions

**cgroups v1 vs v2 - Key Differences:**

**cgroups v1:**
- Each controller type (cpu, memory, etc.) has its own cgroup hierarchy
- Process can belong to multiple cgroups (one per controller)
- More complex configuration

**cgroups v2:**
- Process belongs to only one cgroup
- Multiple controllers can be applied to single cgroup
- Simpler, unified hierarchy

**Version Coexistence:**
- Both versions can run simultaneously (confusing!)
- If controller used in v1, cannot be used in v2 simultaneously
- v1 being phased out in favor of v2

**Visual Comparison:**
- **v1:** Need 6 separate cgroups for 3 process groups × 2 controllers
- **v2:** Need only 3 cgroups with multiple controllers each

### 8.6.2 Viewing cgroups

**Finding Process cgroups:**
```bash
# View current shell's cgroups
cat /proc/self/cgroup

# View specific process cgroups
cat /proc/1234/cgroup
```

**Sample Output:**
```
12:rdma:/
11:net_cls,net_prio:/
10:perf_event:/
8:cpu,cpuacct:/user.slice
5:pids:/user.slice/user-1000.slice/session-2.scope
1:name=systemd:/user.slice/user-1000.slice/session-2.scope
0::/user.slice/user-1000.slice/session-2.scope
```

**Reading the Output:**
- **Numbers 2-12:** cgroups v1 (with controllers listed)
- **Number 1:** v1 management cgroup (no controller)
- **Number 0:** cgroups v2
- **Hierarchical naming:** Like file paths
- **user.slice:** User sessions (systemd managed)
- **system.slice:** System services (systemd managed)

**Exploring cgroup Filesystem:**
```bash
# Navigate to cgroup directory
cd /sys/fs/cgroup/user.slice/user-1000.slice/session-2.scope/

# List files
ls

# View processes in cgroup
cat cgroup.procs

# View threads in cgroup  
cat cgroup.threads

# View available controllers
cat cgroup.controllers
```

### 8.6.3 Manipulating and Creating cgroups

**Adding Process to cgroup:**
```bash
# Add process PID to cgroup
echo 1234 > cgroup.procs
```

**Setting Resource Limits:**
```bash
# Limit maximum PIDs in cgroup
echo 3000 > pids.max

# Set memory limit (in bytes)
echo 100M > memory.max
```

**Creating New cgroups:**
```bash
# Create new cgroup (creates subdirectory)
mkdir /sys/fs/cgroup/my-cgroup
```

**cgroup Rules and Constraints:**
- **Leaf-only processes:** Can only put processes in outer-level cgroups
- **Controller inheritance:** Child cgroup can't have controller parent doesn't have
- **Explicit controller specification:** Must specify controllers for child cgroups via `cgroup.subtree_control`

**Example Controller Management:**
```bash
# Enable cpu and pids controllers for child cgroups
echo "+cpu +pids" > cgroup.subtree_control
```

### 8.6.4 Viewing Resource Utilization

**CPU Usage Monitoring:**
```bash
# View CPU statistics for cgroup
cat cpu.stat
```

**Sample Output:**
```
usage_usec 4617481
user_usec 2170266  
system_usec 2447215
```

**Memory Usage Monitoring:**
```bash
# Current memory usage
cat memory.current

# Detailed memory statistics
cat memory.stat

# Memory limit
cat memory.max
```

**Benefits of cgroup Monitoring:**
- **Aggregate statistics** across all processes in group
- **Historical data** persists even after processes terminate
- **Hierarchical monitoring** for complex service architectures

---

## 8.7 Further Topics and Advanced Tools

### Additional Monitoring Tools
**sar (System Activity Reporter):**
- **Historical monitoring** capability
- **Records resource utilization over time**
- **Analyze past system events**
- Part of sysstat package

**acct (Process Accounting):**
- **Records process execution** and resource usage
- **Historical process tracking**
- **Audit trail** of system activity

**Quota Systems:**
- **Disk space limits** per user or group
- **Filesystem-level enforcement**
- **Integration with user management**

### Advanced Performance Analysis
**Tools for Deep Analysis:**
- **perf** - Linux profiling tool
- **systemtap** - Dynamic tracing
- **ftrace** - Function tracing
- **BPF/eBPF** - Programmable kernel monitoring

**Network Resource Monitoring:**
- **iftop** - Network interface monitoring
- **nethogs** - Per-process network usage
- **ss** - Socket statistics
- **iptraf** - IP traffic monitoring

### Integration with systemd
**systemd and cgroups:**
- systemd **automatically creates cgroups** for services
- **Service isolation** through cgroup boundaries
- **Resource limits** in unit files
- **Automatic cleanup** when services stop

**Viewing systemd cgroups:**
```bash
# View systemd cgroup tree
systemd-cgls

# View specific unit's cgroup
systemctl status unit-name
```

### Performance Tuning Guidelines
**When to Tune:**
- **Measure first** - Understand current behavior
- **Identify bottlenecks** through monitoring
- **Change one thing at a time**
- **Validate improvements** with metrics

**What NOT to Do:**
- **Tune without measuring**
- **Change multiple settings simultaneously**
- **Optimize systems that work fine**
- **Chase benchmarks** instead of real-world performance

## Key Takeaways

### Essential Concepts
1. **Three basic resources:** CPU, memory, I/O
2. **Tools for different purposes:** Static snapshots vs continuous monitoring vs deep tracing
3. **Process vs thread** distinction and when it matters
4. **Resource monitoring philosophy:** Understand first, optimize only when needed

### Critical Tools to Master
- **`top`** - Real-time process monitoring
- **`lsof`** - File and network resource tracking
- **`strace`** - System call debugging
- **`vmstat`** - System-wide resource overview
- **`iostat`** - I/O performance monitoring

### Modern Linux Features
- **cgroups v2** for resource management
- **systemd integration** with process monitoring
- **Thread-aware tools** for modern applications
- **Container-ready** monitoring concepts

This comprehensive understanding provides the foundation for system administration, performance tuning, and application debugging in modern Linux environments.