#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// Simple busy-wait sleep (xv6 sleep needs a channel)
void simple_delay(int loops) {
  volatile int i;
  for (i = 0; i < loops * 10000; i++) {
    // just waste some cycles
  }
}

int
main(int argc, char *argv[])
{
  int lock_id = peterson_create();
  if (lock_id < 0) {
    printf("Failed to create lock\n");
    exit(1);
  }

  int fork_ret = fork();
  int role = (fork_ret > 0) ? 0 : 1;

  for (int i = 0; i < 100; i++) {
    if (peterson_acquire(lock_id, role) < 0) {
      printf("Failed to acquire lock\n");
      exit(1);
    }

    // Critical section
    printf(">>> [Role %d] start iteration %d\n", role, i);
    simple_delay(1); // waste a little time
    printf("<<< [Role %d] end iteration %d\n", role, i);

    if (peterson_release(lock_id, role) < 0) {
      printf("Failed to release lock\n");
      exit(1);
    }

    // Random small delay outside critical section
    if (i % 5 == 0) {
      simple_delay(2); // sometimes delay more
    }
  }

  if (fork_ret > 0) {
    wait(0);
    printf("Parent process destroying lock\n");
    if (peterson_destroy(lock_id) < 0) {
      printf("Failed to destroy lock\n");
      exit(1);
    }
  }

  exit(0);
}
