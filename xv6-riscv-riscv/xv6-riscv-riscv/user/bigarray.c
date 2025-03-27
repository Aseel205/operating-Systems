#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int waitnTest () {    
    int numChildren = 5;  // Increase number of child processes
    int pids[numChildren];

    for (int i = 0; i < numChildren; i++) {
        pids[i] = fork();
        if (pids[i] == 0) { 
            sleep(i + 1); // Different sleep times
            exit(i + 10, "Child Exit");
        }
    }

    // Introduce extra delay to allow some processes to turn into zombies
    sleep(2);

    int number = 0;
    int status[64] = {0};  // Initialize status array

    if (waitall((int *)&number, (int *)status) < 0) {
        printf("waitall failed!\n");
        exit(1, " ");
    }

    printf("\nNumber of children exited: %d\n", number);

    for (int i = 0; i < number; i++) {
        printf("Child exited with status: %d\n", status[i]);
    }

    printf("\nAll children have exited.\n");
    exit(0, " ");
}

int main () {
    return  0 ; 
}
 