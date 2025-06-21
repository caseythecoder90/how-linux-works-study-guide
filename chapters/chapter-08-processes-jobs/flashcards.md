# Chapter 8: Process Monitoring and Resource Utilization - Flashcards

## Basic Concepts and Philosophy

**Q1:** What are the three basic hardware resources that processes compete for in Linux?
**A1:** CPU (processing power), Memory (RAM), and I/O (input/output operations like disk and network access). The kernel's job is to allocate these resources fairly among processes.

**Q2:** What is the recommended philosophy when using performance monitoring tools?
**A2:** Focus on understanding how the kernel works and how it interacts with processes, rather than chasing performance optimizations. Default settings are usually well-chosen, so only change them for very unusual needs.

**Q3:** What's the key limitation of the `ps` command that `top` addresses?
**A3:** `ps` shows only a static snapshot at one point in time and doesn't help identify which process is consuming too much CPU or memory over time. `top` provides real-time, continuously updating information.

---

## The `top` Command

**Q4:** What are the key interactive commands in `top` for sorting processes?
**A4:**
- **M** - Sort by current resident memory usage
- **T** - Sort by total (cumulative) CPU usage
- **P** - Sort by current CPU usage (default)
- **u** - Display only one user's processes
- **f** - Select different statistics to display
- **Spacebar** - Update display immediately

**Q5:** Are `top` commands case-sensitive?
**A5:** Yes, all `top` keystroke commands are case-sensitive.

---

## lsof - List Open Files

**Q6:** Why is `lsof` considered one of the most useful troubleshooting tools?
**A6:** Because Unix places heavy emphasis on files, and `lsof` can list not just regular files, but also network resources, dynamic libraries, pipes, and more. It shows what resources processes are actually using.

**Q7:** What do these `lsof` FD field values mean: `cwd`, `rtd`, `txt`?
**A7:**
- **cwd** - Current working directory
- **rtd** - Root directory
- **txt** - Executable text (the program file)

**Q8:** What's the difference between running `lsof` as root vs. a regular user?
**A8:** Running as root provides complete information about all processes and files. As a regular user, you only see information about your own processes.

**Q9:** What `lsof` command shows files open in a specific directory and all subdirectories?
**A9:** `lsof +D /path/to/directory`

**Q10:** How do you see open files for a specific process ID with `lsof`?
**A10:** `lsof -p pid`

---

## System Call Tracing

**Q11:** What is a system call and what does `strace` show?
**A11:** A system call is a privileged operation that a user-space process asks the kernel to perform (like opening files, reading data). `strace` shows all system calls that a process makes.

**Q12:** Where does `strace` send its output by default, and how can you redirect it?
**A12:** `strace` sends output to standard error by default. Use `-o filename` to save to a file, or redirect with `2> filename`.

**Q13:** What does this `strace` output indicate: `openat(AT_FDCWD, "not_a_file", O_RDONLY) = -1 ENOENT`?
**A13:** The process tried to open a file called "not_a_file" but failed. The return value -1 indicates error, and ENOENT means "No such file or directory" - a missing file.

**Q14:** How do you trace a daemon and all its child processes with `strace`?
**A14:** `strace -o daemon_trace -ff mydaemon` - The `-ff` option traces child processes into separate files named daemon_trace.pid.

**Q15:** What's the difference between `strace` and `ltrace`?
**A15:** `strace` tracks system calls (kernel-level operations), while `ltrace` tracks shared library calls (user-space library functions). `ltrace` generates even more output and doesn't work with statically linked binaries.

---

## Threads

**Q16:** What's the key difference between threads and processes in terms of resource sharing?
**A16:** Threads within a single process share system resources and memory, while separate processes usually don't share resources with other processes.

**Q17:** What is TID and how does it relate to PID for single-threaded processes?
**A17:** TID is Thread ID. For single-threaded processes, the TID equals the PID because there's only one thread (the main thread).

**Q18:** What command shows both processes and their threads?
**A18:** `ps m` - Shows processes with thread information, where lines with numbers in PID column are processes and lines with dashes are threads.

**Q19:** What are the main advantages of multithreading over multiple processes?
**A19:** Threads start faster than processes, can run simultaneously on multiple processors for parallel computation, and can communicate more easily through shared memory rather than inter-process channels.

---

## CPU Time and Priorities

**Q20:** What do the three time values from the `time` command represent?
**A20:**
- **real** - Total elapsed time (wall clock time)
- **user** - CPU time spent running the program's own code
- **sys** - CPU time the kernel spent doing work for the process

**Q21:** What is the range of Linux process scheduling priorities and which direction is higher priority?
**A21:** Range is -20 to +20, where -20 is the highest priority (most important) and +20 is the lowest priority.

**Q22:** What's the difference between the PR (priority) and NI (nice) columns in `top`?
**A22:** PR shows the kernel's current scheduling priority for the process. NI shows the nice value, which is a hint to the kernel's scheduler that you can control to influence priority.

**Q23:** How do you make a running process less aggressive (lower priority)?
**A23:** `renice 20 pid` - Sets the nice value to 20 (lowest priority, most "nice" to other processes).

**Q24:** Can regular users set negative nice values?
**A24:** No, only root can set negative nice values. Regular users can only set nice values from 0 to 20.

---

## Load Averages

**Q25:** What does load average measure?
**A25:** Load average is the average number of processes currently ready to run - including processes that are running and those waiting for CPU time. It does NOT include processes waiting for input.

**Q26:** What do the three load average numbers from `uptime` represent?
**A26:** The three numbers are load averages for the past 1 minute, 5 minutes, and 15 minutes respectively.

**Q27:** On a system with 2 CPU cores, what does a load average of 1.0 indicate?
**A27:** Only one of the two cores is likely active at any given time. A load of 2.0 would mean both cores are fully utilized.

**Q28:** When might a high load average NOT indicate a problem?
**A28:** When the system has enough memory and I/O resources and still responds well. Also on web/compute servers where processes start and terminate so quickly that load measurement can't function effectively.

---

## Memory Monitoring

**Q29:** What's the difference between major and minor page faults?
**A29:** Major page faults require disk access to load memory pages, while minor page faults are memory management operations that don't require disk I/O.

**Q30:** How do you view page faults for a specific process using `ps`?
**A30:** `ps -o pid,min_flt,maj_flt pid` - Shows minor and major page faults in MINFL and MAJFL columns.

---

## vmstat

**Q31:** What does the first line of `vmstat` output represent?
**A31:** The first line shows averages since the system booted up and is usually ignored. Subsequent lines show current activity.

**Q32:** In `vmstat` output, what do high values in the 'so' column indicate?
**A32:** High 'so' (swap out) values indicate memory pressure - the kernel is moving memory pages to disk because it's running low on available RAM.

**Q33:** What do the vmstat CPU columns 'us', 'sy', 'id', and 'wa' represent?
**A33:**
- **us** - User space time (% of CPU)
- **sy** - System/kernel time (% of CPU)
- **id** - Idle time (% of CPU)
- **wa** - Time waiting for I/O (% of CPU)

**Q34:** In vmstat, what do the 'r' and 'b' columns under 'procs' show?
**A34:**
- **r** - Processes ready to run
- **b** - Processes blocked waiting for I/O

---

## I/O Monitoring

**Q35:** What do the iostat columns 'tps', 'kB_read/s', and 'kB_wrtn/s' mean?
**A35:**
- **tps** - Transfers (I/O operations) per second
- **kB_read/s** - Kilobytes read per second
- **kB_wrtn/s** - Kilobytes written per second

**Q36:** How do you show all partition information with `iostat`?
**A36:** `iostat -p ALL` - Shows detailed I/O statistics for all partitions, not just whole disks.

**Q37:** What does `iotop` show that's different from other process monitors?
**A37:** `iotop` shows per-process I/O usage in real-time and displays TIDs (Thread IDs) instead of PIDs, making it thread-focused.

**Q38:** What do the I/O scheduling classes 'be', 'rt', and 'idle' mean in `iotop`?
**A38:**
- **be** - Best effort (default, kernel schedules I/O fairly)
- **rt** - Real time (scheduled before all other I/O)
- **idle** - Only when no other I/O is pending

**Q39:** How do you change the I/O priority of a process?
**A39:** `ionice -c class -n priority pid` - For example, `ionice -c 1 -n 4 command` sets real-time class with priority 4.

---

## pidstat

**Q40:** What advantage does `pidstat` have over `top` for monitoring?
**A40:** `pidstat` provides persistent output that doesn't refresh and erase like `top`, allowing you to see resource consumption over time in a log-like format.

**Q41:** What `pidstat` options monitor memory and disk I/O respectively?
**A41:** `-r` for memory monitoring and `-d` for disk I/O monitoring.

**Q42:** How do you monitor a specific process every 2 seconds with `pidstat`?
**A42:** `pidstat -p pid 2` - Monitors process 'pid' with updates every 2 seconds.

---

## Control Groups (cgroups)

**Q43:** What is the basic purpose of cgroups?
**A43:** To group processes together and manage the resources they consume on a group-wide basis, such as limiting total memory usage of a set of processes.

**Q44:** What's the key structural difference between cgroups v1 and v2?
**A44:**
- **v1:** Each controller type has its own cgroup hierarchy; a process can belong to multiple cgroups (one per controller)
- **v2:** A process belongs to only one cgroup, but multiple controllers can be applied to that single cgroup

**Q45:** How do you view what cgroups a process belongs to?
**A45:** `cat /proc/pid/cgroup` or `cat /proc/self/cgroup` for your current shell.

**Q46:** Where is the cgroups v2 filesystem typically mounted?
**A46:** `/sys/fs/cgroup` (or `/sys/fs/cgroup/unified` if v1 is also running).

**Q47:** What files in a cgroup directory show the processes and available controllers?
**A47:**
- `cgroup.procs` - Lists processes in the cgroup
- `cgroup.controllers` - Shows available controllers for the cgroup

**Q48:** How do you add a process to a cgroup?
**A48:** `echo pid > cgroup.procs` (must be run as root).

**Q49:** How do you set a memory limit of 100MB for a cgroup?
**A49:** `echo 100M > memory.max`

**Q50:** What does `cat cpu.stat` in a cgroup directory show?
**A50:** Accumulated CPU usage statistics for all processes in the cgroup over its entire lifespan, including user time, system time, and total usage in microseconds.

---

## Integration and Advanced Topics

**Q51:** How does systemd use cgroups?
**A51:** systemd automatically creates cgroups for services, providing service isolation and automatic cleanup. Most cgroups on modern systems are managed by systemd.

**Q52:** What systemd command shows the cgroup tree structure?
**A52:** `systemd-cgls` - Shows systemd-related cgroups in a tree format.

**Q53:** What are the main cgroup naming patterns for user sessions vs system services?
**A53:** User sessions are under `user.slice` (like `user.slice/user-1000.slice/session-2.scope`) while system services are under `system.slice`.

**Q54:** When should you avoid performance tuning?
**A54:** When the system is already working correctly. Trying to optimize a well-functioning system is usually a waste of time since default settings are typically well-chosen.

**Q55:** What's the relationship between cgroups and containers?
**A55:** Cgroups are a fundamental technology used by container systems for resource isolation and limitation. Understanding cgroups helps explain how containerized environments work.

---

## Troubleshooting and Best Practices

**Q56:** What's the most common problem that `strace` helps identify?
**A56:** Missing files. When programs fail mysteriously, `strace` often reveals failed `open()` system calls showing exactly which files the program can't find.

**Q57:** Why might you use `lsof -n` instead of just `lsof`?
**A57:** The `-n` option disables hostname resolution, which significantly speeds up the output when you don't need hostnames resolved.

**Q58:** When is memory thrashing occurring based on `vmstat` output?
**A58:** When you see high values in the 'so' (swap out) column, along with decreased buffer and cache sizes, and more processes blocked ('b' column increases).

**Q59:** What indicates an I/O bottleneck in system monitoring?
**A59:** High 'wa' (wait) values in `vmstat` CPU columns, indicating the CPU is spending significant time waiting for I/O operations to complete.

**Q60:** What's a key rule about creating cgroups?
**A60:** You can only put processes in "leaf" cgroups (outer-level cgroups). If you have `/my-cgroup` and `/my-cgroup/my-subgroup`, you can't put processes in `/my-cgroup`, only in `/my-cgroup/my-subgroup`.

These flashcards cover the essential concepts, commands, and troubleshooting knowledge needed to master process monitoring and resource utilization in Linux systems.