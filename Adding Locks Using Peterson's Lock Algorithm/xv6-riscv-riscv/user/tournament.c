#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if (argc != 2) {
    printf("Usage: tournament <number_of_processes>\n");
    exit(1);
  }

  int n = atoi(argv[1]);
  if (n <= 0 || (n & (n - 1)) != 0 || n > 16) {
    printf("Number of processes must be a power of 2 and <= 16\n");
    exit(1);
  }

  int tid = tournament_create(n);
  if (tid < 0) {
    printf("Failed to create tournament\n");
    exit(1);
  }


  for (int i = 0; i < 5; i++) {
    if (tournament_acquire() < 0) {
      printf("Failed to acquire tournament lock\n");
      exit(1);
    }

      printf("[PID %d | TID %d] In critical section, iteration %d\n", getpid(), tid, i);

    if (tournament_release() < 0) {
      printf("Failed to release tournament lock\n");
      exit(1);
    }
  }

  // Parent waits for all child processes to exit
  if (tid == 0) {
    for (int i = 1; i < n; i++) {
      wait(0);
    }
  }

  exit(0);
}