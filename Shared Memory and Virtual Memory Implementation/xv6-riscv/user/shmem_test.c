#include "user.h"
#include "./kernel/riscv.h"


int main(int argc, char *argv[])
{ 
    printf("Parent before malloc: %d\n", memory_size());
    char* memory = malloc(500); 
    int parent_id = getpid();
    
    printf("Parent after malloc: %d\n", memory_size());
    if(fork() == 0) {

        printf("Child memory before: %d\n", memory_size());
        char* ptr;

        if((ptr = (char*) map_shared_pages(parent_id,getpid(), (uint64)memory, 10   )) < 0){
            printf("Error in map\n");
            exit(0);
        }
        printf("Child after map %d\n", memory_size());
        //send the string 
        strcpy(ptr, "Hello daddy");
        int child_id=getpid();
        //unmapping
        unmap_shared_pages(child_id, (uint64)ptr,10);
        printf("Child after unmap %d\n", memory_size());

        malloc(40*PGSIZE);

        printf("Child after allocating memmory: %d\n", memory_size()); 

    }
    else {
        
        wait(0);
        printf("Parent: %s\n", memory);
        
    }

    return 0;
}