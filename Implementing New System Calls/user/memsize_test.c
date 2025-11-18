#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main() {
    printf("Memory usage before malloc: %d bytes\n", memsize());

    int *ptr = (int *) malloc(20 * 1000);
    

    printf("Memory usage after malloc: %d bytes\n", memsize());

    free(ptr);
    printf("Memory usage after free: %d bytes\n", memsize());

 

    return 0 ; 
}
