#include "kernel/types.h"
#include "user/user.h"
#include "kernel/param.h"

#define MAX_PROCESSES 16
#define MAX_LOCKS (MAX_PROCESSES - 1) // Binary tree: 2^n - 1 nodes

static int num_levels;
static int num_processes;
static int tournament_index; // index of current process (0..N-1)
static int locks[MAX_LOCKS]; // lock IDs from peterson_create()

// Helper to calculate log2(n)
static int log2(int n) {
  int l = 0;
  while (n > 1) {
    n /= 2;
    l++;
  }
  return l;
}

// Calculate lock array index based on level and process index
static int get_lock_index(int level, int process_index) {
  int offset = (1 << level) - 1;
  int lockl = process_index >> (num_levels - level);
  return offset + lockl;
}

int
tournament_create(int processes)
{
  if (processes <= 0 || processes > MAX_PROCESSES)
    return -1;

  // Must be a power of 2
  if ((processes & (processes - 1)) != 0)
    return -1;

  num_processes = processes;
  num_levels = log2(processes);

  // Create locks
  for (int i = 0; i < (processes - 1); i++) {
    locks[i] = peterson_create();
    if (locks[i] < 0)
      return -1;
  }

  // Fork processes
  tournament_index = 0;
  for (int i = 1; i < processes; i++) {
    int pid = fork();
    if (pid < 0)
      return -1;
    if (pid == 0) {
      tournament_index = i;
      break;
    }
  }

  return tournament_index;
}

int
tournament_acquire(void)
{
  int idx = tournament_index;
  for (int l = 0; l < num_levels; l++) {
    int role = (idx >> (num_levels - l - 1)) & 1;
    int lock_idx = get_lock_index(l, idx);
    if (peterson_acquire(locks[lock_idx], role) < 0)
      return -1;
  }
  return 0;
}

int
tournament_release(void)
{
  int idx = tournament_index;
  // Release in reverse order
  for (int l = num_levels - 1; l >= 0; l--) {
    int role = (idx >> (num_levels - l - 1)) & 1;
    int lock_idx = get_lock_index(l, idx);
    if (peterson_release(locks[lock_idx], role) < 0)
      return -1;
  }
  return 0;
}
