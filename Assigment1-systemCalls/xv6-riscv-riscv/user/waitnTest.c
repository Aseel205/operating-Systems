#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define MAX_CHILDREN 16

void harshWaitallTest() {    
    int numChildren = MAX_CHILDREN;
    int pids[MAX_CHILDREN];

    printf("Starting harshWaitallTest with %d children...\n", numChildren);

    for (int i = 0; i < numChildren; i++) {
        pids[i] = fork();
        if (pids[i] < 0) {
            printf("Fork failed for child %d\n", i);
            exit(1, "Fork failure");
        }
        if (pids[i] == 0) { 
            sleep((i % 4) + 1);  // Randomized sleep to simulate varying workloads
            int exitStatus = (i % 2 == 0) ? (i + 10) : -(i + 5); // Mix of positive and negative exits
            printf("Child %d (PID: %d) exiting with status %d\n", i, getpid(), exitStatus);
            exit(exitStatus, "Child Exit");
        }
    }

    sleep(5); // Ensure some processes enter a zombie state

    int number = 0;
    int status[MAX_CHILDREN] = {0};  // Store exit statuses

    if (waitall(&number, status) < 0) {
        printf("waitall failed!\n");
        exit(1, " ");
    }

    printf("\nNumber of children exited: %d (Expected: %d)\n", number, numChildren);

    for (int i = 0; i < number; i++) {
        printf("Child exited with status: %d\n", status[i]);
    }

    printf("\nAll children have exited successfully under stress.\n");
    exit(0, " ");
}

int main() {
    harshWaitallTest();
    return 0;
}
