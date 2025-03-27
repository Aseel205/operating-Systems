#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define MAX_CHILDREN 16

void test_forkn(int n) {
    int pids[MAX_CHILDREN];  // Array to store PIDs
    int ret = forkn(n, pids);

    if (ret == -1) {
        printf("forkn(%d) failed as expected (if n is invalid)\n", n);
        return;
    }

    if (ret == 0) {
        printf("Parent: forkn(%d) succeeded!\n", n);
        printf("Parent: Child PIDs = ");
        for (int i = 0; i < n; i++) {
            printf("%d ", pids[i]);
        }
        printf("\n");

        // Wait for all children to exit
        for (int i = 0; i < n; i++) {
            wait(0 , " ");
        }
    } else {
        printf("@");
        exit(0 , " ");
    }
}

int main() {
    printf("===== Testing forkn =====\n");

    printf("\nTest 1: Creating 4 child processes\n");
    test_forkn(4);

    printf("\nTest 2: Creating 16 child processes (max limit)\n");
    test_forkn(16);

    printf("\nTest 3: Invalid n (-1)\n");
    test_forkn(-1);

    printf("\nTest 4: Invalid n (0)\n");
    test_forkn(0);

    printf("\nTest 5: Invalid n (17, beyond max limit)\n");
    test_forkn(17);
    

    printf("\n===== All tests finished! =====\n");
    exit(0 , " ");
}
