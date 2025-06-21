# Chapter 1: The Big Picture - Flashcards

## Basic Concepts

**Q: What is abstraction in the context of operating systems?**
A: A method of understanding complex systems by ignoring implementation details and focusing on basic purpose and operation. It allows you to split computing systems into components and concentrate on what components do rather than how they work internally.

---

**Q: What are the three main levels of a Linux system?**
A: 1. Hardware (bottom) - CPU, memory, devices
2. Linux Kernel (middle) - core OS managing hardware
3. User Space (top) - running user processes

---

**Q: What is the difference between kernel mode and user mode?**
A: Kernel mode has unrestricted access to processor and main memory, while user mode restricts access to a small subset of memory and safe CPU operations. Kernel mode is powerful but dangerous; user mode is safer but limited.

---

**Q: What is kernel space vs user space?**
A: Kernel space is the memory area that only the kernel can access. User space refers to the parts of main memory that user processes can access.

---

## Hardware Fundamentals

**Q: What is a bit in computer memory?**
A: Each slot for storing a 0 or 1 in main memory. All programs, data, and the kernel itself are collections of bits.

---

**Q: What is the difference between "state" and "image" in memory terms?**
A: State is a particular arrangement of bits (often described abstractly like "process is waiting for input"). Image refers to the particular physical arrangement of bits in memory.

---

**Q: What role does the CPU play in relation to memory?**
A: The CPU is an operator on memory - it reads instructions and data from memory and writes data back out to memory.

---

**Q: What hardware components make up the hardware level?**
A: Memory (RAM), one or more CPUs, and devices such as disks and network interfaces.

---

## Kernel Functions

**Q: What are the four general system areas managed by the kernel?**
A: 1. Process Management
2. Memory Management
3. Device Drivers and Management
4. System Calls and Support

---

**Q: What is process management in the kernel?**
A: The starting, pausing, resuming, scheduling, and terminating of processes. The kernel determines which processes are allowed to use the CPU.

---

**Q: How does multitasking work on a single-core CPU?**
A: Through time slicing and context switching. Each process uses the CPU for a small fraction of a second, then another process takes a turn. The slices are so small that humans perceive simultaneous execution.

---

**Q: What is a context switch?**
A: The act of one process giving up control of the CPU to another process. The kernel is responsible for context switching.

---

**Q: What is virtual memory and why is it important?**
A: A memory access scheme where processes don't directly access physical memory locations. Instead, each process acts as if it has an entire machine to itself. The MMU translates virtual addresses to physical addresses, allowing the system to use more memory than physically present.

---

**Q: What is the MMU?**
A: Memory Management Unit - hardware that enables virtual memory by intercepting memory accesses and translating virtual memory locations to actual physical memory locations.

---

**Q: What is a page table?**
A: The implementation of a memory address map used by the MMU for virtual memory translation.

---

**Q: Why are device drivers typically part of the kernel?**
A: Because devices are typically accessible only in kernel mode for security (improper access could crash the machine), and different devices rarely have the same programming interface. Kernel drivers provide a uniform interface to user processes.

---

## System Calls

**Q: What are system calls (syscalls)?**
A: Functions that perform specific tasks that a user process cannot do well or at all, such as opening files, reading files, or creating processes.

---

**Q: What does the fork() system call do?**
A: When a process calls fork(), the kernel creates a nearly identical copy of the process.

---

**Q: What does the exec() system call do?**
A: When a process calls exec(program), the kernel loads and starts the specified program, replacing the current process.

---

**Q: Describe the process flow when you run the 'ls' command in a shell.**
A: 1. Shell calls fork() to create a copy of itself
2. The new copy of the shell calls exec(ls) to run the ls program
3. The ls program executes and then terminates

---

**Q: What are pseudodevices?**
A: Devices that look like hardware devices to user processes but are implemented purely in software. Example: /dev/random (kernel random number generator).

---

## User Space

**Q: What is user space?**
A: The main memory that the kernel allocates for user processes, also referring to the memory for the entire collection of running processes.

---

**Q: What are the three service levels in user space?**
A: 1. Bottom level - Basic services (small components doing simple tasks)
2. Middle level - Utility services (larger components like mail, print services)
3. Top level - Applications (complicated tasks users directly control)

---

**Q: What is the general rule for component interaction in user space?**
A: Generally, if one component wants to use another, the second component is either at the same service level or below. However, there are no strict rules in user space.

---

**Q: Give examples of bottom-level user space components.**
A: Network configuration, communication bus, diagnostic logging - small components that perform single, uncomplicated tasks.

---

**Q: Give examples of top-level user space components.**
A: User interface, web browser - applications that perform complicated tasks that users often control directly.

---

## Users and Security

**Q: How does the Linux kernel identify users?**
A: The kernel identifies users by simple numeric identifiers called user IDs, not by usernames. Usernames are managed by user-space processes.

---

**Q: What is a user in Linux terms?**
A: An entity that can run processes and own files, most often associated with a username.

---

**Q: Can a user process cause serious damage to the system?**
A: In theory, no - consequences are limited and can be cleaned up by the kernel. In reality, it depends on the process privileges. With correct permissions, a process could damage disk data.

---

## Advanced Concepts

**Q: What are kernel threads?**
A: Processes that look like regular processes but have access to kernel space. Examples include kthreadd and kblockd.

---

**Q: Why might CD/DVD writing be moved to user space instead of kernel space?**
A: Writing optical discs is significantly more complicated than reading and no critical system services depend on it. It's safer and easier to maintain in user space, even if slightly less efficient.

---

**Q: What is the difference between a process and a thread?**
A: This is mentioned as a variant concept to be covered in Chapter 8, but processes are the main focus in Chapter 1 as running programs managed by the kernel.

---

## Troubleshooting Concepts

**Q: How does abstraction help with problem-solving?**
A: You can quickly assess different abstraction levels to determine the source of problems. Example: rough car ride → eliminate car and driving style → narrow down to road conditions.

---

**Q: Why is understanding system layers important for troubleshooting?**
A: It allows you to systematically eliminate potential problem sources by working through the abstraction layers, from hardware through kernel to user space applications.

---

## Memory Management Details

**Q: What are the key requirements for memory management in a multi-process system?**
A: 1. Each user process needs its own memory section
2. One process may not access another's private memory
3. User processes can share memory
4. Some memory can be read-only
5. System can use more memory than physically present

---

**Q: How does the kernel handle memory during context switches?**
A: The kernel must change the memory address map from the outgoing process to the incoming process, updating the page table used by the MMU.

---

## Process Creation Deep Dive

**Q: Except for which process do all new user processes start with fork()?**
A: All new user processes except init start as a result of fork(). Init is covered in Chapter 6.

---

**Q: What happens after most fork() calls?**
A: Most of the time, exec() is called to start a new program instead of running a copy of the existing process.

---

**Q: How is system call notation represented in technical documentation?**
A: System calls are denoted with parentheses, like fork() and exec(), derived from C programming language syntax.

---

This flashcard set covers all major concepts from Chapter 1. Use these for spaced repetition study, and consider creating additional cards for any concepts you find challenging!