#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

//#define BUF_SIZE PGSIZE
#define BUF_SIZE PGSIZE
#define child_count 4
#define HEADER_SIZE 4 // 2 bytes for index, 2 bytes for length


uint32 make_header(uint16 idx, uint16 len) {
  return ((uint32)idx << 16) | (uint32)len;
}

uint16 get_index(uint32 header) {
  return (header >> 16) & 0xFFFF;
}

uint16 get_length(uint32 header) {
  return header & 0xFFFF;
}

void child_proc(int parent_pid, void *buf, int idx) {
  char *ptr;

  if ((ptr = (char *)map_shared_pages(parent_pid, getpid(), (uint64)buf, BUF_SIZE)) == (char *)-1) {
    printf("[child %d] Failed to map shared memory\n", idx);
    exit(1);
  }

  char *msg = "Hello from child \n";
  int len = strlen(msg);

  //printf("[child %d] Starting and the msg len = %x \n", idx , len );
  char *end = ptr + BUF_SIZE;

  while ((ptr + HEADER_SIZE + len) <= end) {
    uint32 *header_ptr = (uint32 *)ptr;
    uint32 zero = 0;
    uint32 hdr = make_header((uint16)idx, (uint16)len);
      
    __sync_synchronize();
//printf("[child %d] head_ptr = %x \n", idx,*header_ptr);
    
   if (__sync_val_compare_and_swap(header_ptr, zero, hdr) == zero) {
  //  printf("[child %d] head_ptr = %x \n", idx,*header_ptr);  
    //printf("[child %d] Found place in memory \n", idx);
      char *msg_ptr = ptr + HEADER_SIZE;
      strcpy(msg_ptr, msg);
      __sync_synchronize();
    //    printf("[child %d] Wrote message: %s\n", idx, msg_ptr);
       unmap_shared_pages(getpid(), (uint64)end-BUF_SIZE, BUF_SIZE);
      exit(0);
    }

    ptr += HEADER_SIZE + get_length(*header_ptr);
    ptr = (char *)(((uint64)ptr + 3) & ~3);
  }

  //printf("[child %d] buffer is full \n", idx);
  exit(1);
}

void parent_proc(char *shmem) {
  char *ptr = shmem;
  //printf("[parent] Starting scan of shared buffer\n");
     //uint32 *header_ptr = (uint32 *)shmem;

//     printf("[parent] head_ptr-4 = %x \n",*(header_ptr-4));
//     printf("[parent] head_ptr-3 = %x \n",*(header_ptr-3));
//     printf("[parent] head_ptr-2 = %x \n",*(header_ptr-2));
//     printf("[parent] head_ptr-1 = %x \n",*(header_ptr-1));  
//     printf("[parent] head_ptr = %x \n",*(header_ptr));
//     printf("[parent] head_ptr+1 = %x \n",*(header_ptr+1));  
//     printf("[parent] head_ptr+2 = %x \n",*(header_ptr+2));
//     printf("[parent] head_ptr+3 = %x \n",*(header_ptr+3));
//     printf("[parent] head_ptr+4 = %x \n",*(header_ptr+4));
//     printf("[parent] head_ptr+5 = %x \n",*(header_ptr+5));
//     printf("[parent] head_ptr+6 = %x \n",*(header_ptr+6));
//     printf("[parent] head_ptr+7 = %x \n",*(header_ptr+7));
//   printf("[parent] head_ptr+8 = %x \n",*(header_ptr+8));
//   printf("[parent] head_ptr+9 = %x \n",*(header_ptr+9));
//   printf("[parent] head_ptr+10 = %x \n",*(header_ptr+10));
//   printf("[parent] head_ptr+11 = %x \n",*(header_ptr+11));
  
//     printf("[parent] head_ptr+19 = %x \n",*(header_ptr+19));
//     printf("[parent] head_ptr+20 = %x \n",*(header_ptr+20));
//     printf("[parent] head_ptr+21 = %x \n",*(header_ptr+21));
//     printf("[parent] head_ptr+22 = %x \n",*(header_ptr+22));
//     printf("[parent] head_ptr+23 = %x \n",*(header_ptr+23));
//     printf("[parent] head_ptr+24 = %x \n",*(header_ptr+24));
//     printf("[parent] head_ptr+25 = %x \n",*(header_ptr+25));
//     printf("[parent] head_ptr+26 = %x \n",*(header_ptr+26));
//     printf("[parent] head_ptr+27 = %x \n",*(header_ptr+27));
//     printf("[parent] head_ptr+28 = %x \n",*(header_ptr+28));
//     printf("[parent] head_ptr+29 = %x \n",*(header_ptr+29));
//     printf("[parent] head_ptr+30 = %x \n",*(header_ptr+30));
//     printf("[parent] head_ptr+12 = %x \n",*(header_ptr+31));
//     printf("[parent] head_ptr+13 = %x \n",*(header_ptr+32));
//     printf("[parent] head_ptr+14 = %x \n",*(header_ptr+33));
//     printf("[parent] head_ptr+15 = %x \n",*(header_ptr+34));
//     printf("[parent] head_ptr+16 = %x \n",*(header_ptr+35));
//     printf("[parent] head_ptr+17 = %x \n",*(header_ptr+36));
//     printf("[parent] head_ptr+18 = %x \n",*(header_ptr+37));
//     printf("[parent] head_ptr+19 = %x \n",*(header_ptr+38));
//     printf("[parent] head_ptr+20 = %x \n",*(header_ptr+39));
//     printf("[parent] head_ptr+21 = %x \n",*(header_ptr+40));
//     printf("[parent] head_ptr+22 = %x \n",*(header_ptr+41));
//     printf("[parent] head_ptr+23 = %x \n",*(header_ptr+42));
//     printf("[parent] head_ptr+24 = %x \n",*(header_ptr+43));
//     printf("[parent] head_ptr+25 = %x \n",*(header_ptr+44));
//     printf("[parent] head_ptr+26 = %x \n",*(header_ptr+45));
//     printf("[parent] head_ptr+27 = %x \n",*(header_ptr+46));
//     printf("[parent] head_ptr+28 = %x \n",*(header_ptr+47));
//     printf("[parent] head_ptr+29 = %x \n",*(header_ptr+48));
//     printf("[parent] head_ptr+30 = %x \n",*(header_ptr+49));
//     printf("[parent] head_ptr+31 = %d \n",*(header_ptr+50));
     while ((ptr + HEADER_SIZE) < (shmem + BUF_SIZE)) {
    

    uint32 header = *(uint32 *)ptr;
  if (header == 0) {
        
//  printf("[parent] get to the last header \n");

      return ; // No more headers, exit the loop
    //   ptr += HEADER_SIZE;
    //   ptr = (char *)(((uint64)ptr + 3) & ~3);
    //   continue;
     }
    
     uint16  idx = get_index(header);
    uint16 len = get_length(header);
     
   printf("[parent] len = %x\n" , len);
    printf("[parent] idx = %d\n" , idx);
    
    if ((ptr + HEADER_SIZE + len) > (shmem + BUF_SIZE)){
  //  printf("[parent] i am heerrrr \n");
        break;
    }
    char msg[len+1];
//printf("[parent] insad the buffer \n");
    for (int i = 0; i < len; i++) {
      msg[i] = ptr[HEADER_SIZE + i];
    }
    msg[len] = '\0';
    printf("[parent] Child %d: %s\n", idx, msg);

    ptr += HEADER_SIZE + len;
   ptr = (char *)(((uint64)ptr + 3) & ~3);
  }
  //printf("[parent] Finished scan of shared buffer\n");
}

int main(int argc, char *argv[]) {
  int parent_pid = getpid();
  void *buf = malloc(BUF_SIZE);
  if (buf == 0) {
    printf("Failed to allocate buffer\n");
    exit(1);
  }
    buf = memset(buf, 0, BUF_SIZE);  // Zero out the buffer
    //uint32 *header_ptr = (uint32 *)buf;
    //printf("[parent] head_ptr = %x \n",*header_ptr);  

 

// Create 4 child processes
for (int i = 0; i < child_count; i++) {
  int pid = fork();
  if (pid == 0) {
    // Child process
    child_proc(parent_pid, buf, i); // Pass the current iteration index if needed
    exit(0); // Ensure the child process exits after its work
}
}
// Wait for all child processes to complete
for (int i = 0; i < child_count; i++) {
  wait(0) ; // Wait for the specific child to terminate
}


  __sync_synchronize(); // Ensure visibility
  parent_proc(buf);
  exit(0);
}
