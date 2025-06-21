#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

// here we added yhe message to the process
uint64 sys_exit(void) {
  int n;
  char exit_msg[32]; // Local buffer for the exit message

  argint(0, &n);
  argstr(1, exit_msg, sizeof(exit_msg)); // Copy from userspace to kernelspace

  // Copy the message safely to the process struct
  strncpy(myproc()->exit_msg, exit_msg, 32);
  myproc()->exit_msg[32] = '\0'; // Ensure null termination


  exit(n);
  return 0; // Not reached
}
uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}


uint64 sys_forkn(void)
{
    int n;
    uint64 pids ;  
    argint(0, &n);
    argaddr(1,  &pids);  // Get the user-space address for pids
    
    if(n < 1 || n > 16) {
        return -1;  // Invalid number of children
    }

    // Check if the pids pointer is valid and accessible in user space
    if (pids == 0) {
        return -1;  // Invalid address
    }

    return forkn(n, (int*) pids);  // Call the forkn function with the arguments
}


uint64 sys_wait(void) {
    uint64 p;
    uint64 messagePointerAddress;  // Pointer to user-space buffer

    argaddr(0, &p);
    argaddr(1, &messagePointerAddress);

    return  wait(p , messagePointerAddress );  // Wait for child process

   }


uint64 sys_waitall(void) {
    uint64 n;          
    uint64 statuses;  // Pointer to the statuses array 

    argaddr(0, &n);
    argaddr(1, &statuses);
    return  waitall(n , statuses );  // Wait for child process

   }


uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64 sys_memsize(void)
{
  struct proc *p = myproc();    
  return p->sz; // Process size in bytes
}


