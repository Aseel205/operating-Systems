# Operating Systems Homework Repository

This repository contains my solutions for Operating Systems assignments completed as part of my course at Ben-Gurion University. The projects focus on understanding and extending xv6, a simple Unix-like teaching operating system.

---

## About xv6

xv6 is a minimalist Unix operating system developed at MIT for teaching purposes. It is a re-implementation of Unix Version 6 (v6) using modern tools and conventions. xv6 is designed to be simple and understandable, making it ideal for learning core OS concepts such as processes, system calls, synchronization, and memory management.

---

## Homework Tasks Overview

### Task 1: Implementing New System Calls  
The first assignment involved extending xv6 by adding new system calls. This required modifying the kernel code to define the system calls, update the syscall table, and handle user-kernel communication properly.

### Task 2: Adding Locks Using Peterson's Lock Algorithm  
The second task focused on synchronization and concurrency control. I implemented locking mechanisms using the classical Peterson’s lock algorithm to ensure safe access to shared resources among multiple threads/processes.

### Task 3: Shared Memory and Virtual Memory Implementation  
The third assignment involved implementing shared memory between processes and enhancing memory management by adding support for virtual memory. This included designing data structures for shared pages, modifying page tables, and handling access synchronization.

---

## Technologies and Tools

- **Programming Language:** C  
- **Operating System:** xv6 (Unix v6 teaching OS)  
- **Build Tools:** GNU Make, GCC  
- **Emulation:** QEMU or similar emulator for running xv6  

---

## Building and Running xv6 with My Changes

1. Clone this repository  
2. Navigate to the xv6 directory  
3. Run `make` to compile the kernel  
4. Run `make qemu` (or your preferred emulator command) to launch xv6 with your modifications  

---

## Notes

- All implementations follow xv6 coding style and conventions.  
- Testing was done through xv6 user programs and system behavior validation.  
- This repository aims to demonstrate practical understanding of OS fundamentals through hands-on kernel programming.

---

If you want to explore or contribute, feel free to open issues or pull requests!

---

**Author:** [Your Name]  
**Course:** Operating Systems - Ben-Gurion University  
**Contact:** [Your Email or GitHub link]
