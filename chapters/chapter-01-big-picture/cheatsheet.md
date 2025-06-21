# Chapter 1: The Big Picture - Quick Reference Cheat Sheet

## Linux System Architecture Overview

```
┌─────────────────────────────────────────┐
│               USER SPACE                │
│  ┌─────────────┐  ┌─────────────────┐  │
│  │ User Interface│  │  Web Browser   │  │  ← Top Level (Applications)
│  └─────────────┘  └─────────────────┘  │
│  ┌─────────────────────────────────────┐ │
│  │     Name Caching Server           │ │  ← Middle Level (Utilities)
│  └─────────────────────────────────────┘ │
│  ┌──────┐ ┌──────────┐ ┌──────────────┐ │
│  │Net   │ │Comm Bus  │ │Diag Logging  │ │  ← Bottom Level (Basic Services)
│  │Config│ │          │ │              │ │
│  └──────┘ └──────────┘ └──────────────┘ │
├─────────────────────────────────────────┤
│              LINUX KERNEL               │
│  ┌─────────────────────────────────────┐ │
│  │         System Calls                │ │
│  ├─────────────────────────────────────┤ │
│  │Process Mgmt│Memory Mgmt│Device Drivers│ │
│  └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│               HARDWARE                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────────┐ │
│  │CPU      │ │RAM      │ │Devices      │ │
│  │         │ │         │ │(Disk, Net)  │ │
│  └─────────┘ └─────────┘ └─────────────┘ │
└─────────────────────────────────────────┘
```

## Core Concepts Quick Reference

| Concept | Definition | Example |
|---------|------------|---------|
| **Abstraction** | Ignore details, focus on purpose | Car: transport vs engine details |
| **Kernel Mode** | Unrestricted hardware access | Device drivers, memory management |
| **User Mode** | Limited, safe operations | Applications, user programs |
| **Context Switch** | CPU control transfer between processes | Process A → Process B |
| **Virtual Memory** | Process sees "private" memory space | MMU translates virtual→physical |

## Three Main System Levels

### 1. Hardware (Bottom Layer)
- **CPU(s)**: Execute instructions, operate on memory
- **RAM**: Store running programs and data
- **Devices**: Disks, network interfaces, peripherals

### 2. Kernel (Middle Layer)
Four main responsibilities:
- **Process Management**: Start, pause, resume, schedule, terminate
- **Memory Management**: Track allocation, sharing, virtual memory
- **Device Drivers**: Interface between hardware and processes
- **System Calls**: Services for user processes

### 3. User Space (Top Layer)
Three service levels:
- **Top**: Applications (GUI, browsers)
- **Middle**: Utilities (mail, print, database services)
- **Bottom**: Basic services (logging, network config)

## Memory Management Essentials

### Key Requirements
- Each process gets own memory section
- No cross-process private memory access
- Processes can share memory safely
- Read-only memory support
- Virtual memory (more than physical RAM)

### Virtual Memory System
```
Process View: [0x1000] → MMU → Physical RAM: [0x4F3A1000]
             [0x2000] → MMU → Physical RAM: [0x7B2C2000]
```

## Critical System Calls

| System Call | Purpose | Example Use |
|-------------|---------|-------------|
| `fork()` | Create process copy | Shell creating new process |
| `exec()` | Replace process with new program | Running commands like `ls` |

### Process Creation Flow
```
Shell → fork() → Shell Copy → exec(ls) → ls program
```

## Mode Comparison

| Aspect | Kernel Mode | User Mode |
|--------|-------------|-----------|
| **Memory Access** | Unrestricted (kernel space + user space) | Limited (user space only) |
| **CPU Operations** | All operations allowed | Safe operations only |
| **Crash Impact** | Can crash entire system | Limited to process |
| **Examples** | Device drivers, memory mgmt | Applications, utilities |

## Essential Commands for Chapter 1

```bash
# System Information
uname -a                    # System info
cat /proc/version          # Kernel version
lscpu                      # CPU info
free -h                    # Memory usage

# Process Exploration
ps aux                     # All processes
top                        # Live process view
echo $$                    # Current shell PID

# Memory Investigation
cat /proc/meminfo          # Memory details
cat /proc/self/maps        # Process memory map

# Device Information
lsblk                      # Block devices
ls /dev/                   # Device files
```

## Key Files and Directories

| Path | Content |
|------|---------|
| `/proc/meminfo` | System memory information |
| `/proc/cpuinfo` | CPU details |
| `/proc/version` | Kernel version |
| `/dev/` | Device files |
| `/dev/random` | Pseudodevice example |

## Troubleshooting with Abstraction

### Problem-Solving Steps
1. **Identify the abstraction levels** involved
2. **Systematically eliminate** each level
3. **Focus on remaining** suspect areas
4. **Drill down** into specific layer

### Example: System Performance Issue
1. **Application layer**: Check specific program
2. **User space**: Check other processes
3. **Kernel**: Check system calls, drivers
4. **Hardware**: Check CPU, memory, devices

## Memory Types and Usage

| Type | Description | Access |
|------|-------------|--------|
| **Physical RAM** | Actual hardware memory | Kernel manages |
| **Virtual Memory** | Process view of memory | Per-process |
| **Kernel Space** | Kernel-only memory | Kernel mode only |
| **User Space** | Process memory | User mode |

## Common Exam/Interview Questions

1. **What are the three levels of Linux architecture?**
   Hardware → Kernel → User Space

2. **Difference between fork() and exec()?**
   fork() copies process, exec() replaces process

3. **How does multitasking work on single CPU?**
   Time slicing with context switching

4. **Why kernel mode vs user mode?**
   Security and stability - limit damage from crashes

5. **What is virtual memory?**
   Each process thinks it has entire machine to itself

## Next Chapter Preview

Chapter 2 covers basic commands and directory hierarchy - the practical tools you'll use to interact with the system architecture described in Chapter 1.

---

**Study Tip**: Use this cheat sheet alongside the detailed notes and flashcards. Focus on understanding the relationships between concepts rather than just memorizing definitions.