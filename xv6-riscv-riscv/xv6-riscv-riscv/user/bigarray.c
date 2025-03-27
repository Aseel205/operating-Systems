#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#define ARRAY_SIZE (1 << 16) // 2^16 = 65536

// Global array
int arr[ARRAY_SIZE];

void task4(int n) {
    if (n <= 0 || n >= 16) {
        printf("Invalid value of n. n must be between 1 and 16 (exclusive).\n");
        return;
    }

    int pids[n];  // Array to store PIDs

    // Parent process: initialize the array with consecutive numbers
    for (int i = 0; i < ARRAY_SIZE; i++) {
        arr[i] = i;
    }

    // Create n child processes
    int ret = forkn(n, pids);
  
    if (ret == -1) {
        printf("forkn(%d) failed\n", n);
        return;
    }

    // Child process: compute the sum of its assigned portion of the array
    if (ret >= 1) {
        int base_size = ARRAY_SIZE / n;  // Base size per child
        int remainder = ARRAY_SIZE % n;  // Remainder to distribute
        int start = (ret - 1) * base_size + (ret - 1 < remainder ? ret - 1 : remainder);  // Partition start index
        int end = start + base_size + (ret <= remainder ? 1 : 0);  // Partition end index
        int sum = 0;
        
        // Sum the array portion
        for (int i = start; i < end; i++) {
            sum += arr[i];
        }
        sleep(ret);
        printf("Child %d  sum: %d\n", ret, sum);
        exit(sum, " ");
    }

    // Parent process: wait for all children and compute the final sum
    int finished;
    int statuses[n];
    if (waitall(&finished, statuses) < 0) {
        printf("waitall failed\n");
        exit(1, " ");
    }

    // Compute the final sum
    int total_sum = 0;
    for (int i = 0; i < n; i++) {
        total_sum += statuses[i];
    }
    printf("Total sum: %d\n", total_sum);

    exit(0, " ");
}

int main() {
    int n = 5 ;
    task4(n); // Call task4 with the specified number of child processes

    printf("\n===== All tests finished! =====\n");
    exit(0, " ");
}
