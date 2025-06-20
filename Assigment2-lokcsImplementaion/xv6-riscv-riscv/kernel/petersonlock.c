#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "petersonlock.h"

#define MAX_PETERSON_LOCKS 15

struct petersonlock petersonlocks[MAX_PETERSON_LOCKS];

// Initialize all locks as inactive at boot
void init_petersonlocks(void) {
    for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
        petersonlocks[i].flag[0] = 0;
        petersonlocks[i].flag[1] = 0;
        petersonlocks[i].turn = 0;
        petersonlocks[i].active = 0;
    }
}

// Create a new Peterson lock
int sys_peterson_create(void) {
    for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
        if (__sync_lock_test_and_set(&petersonlocks[i].active, 1) == 0) {
            petersonlocks[i].flag[0] = 0;
            petersonlocks[i].flag[1] = 0;
            petersonlocks[i].turn = 0;
            __sync_synchronize(); // Ensure initialization is visible
            return i;
        }
    }
    return -1; // No available locks
}

// Acquire the lock
int sys_peterson_acquire(void) {
    int lock_id, role;
    argint(0, &lock_id);
    argint(1, &role);

    if (lock_id < 0 || lock_id >= MAX_PETERSON_LOCKS || role < 0 || role > 1)
        return -1;
    if (petersonlocks[lock_id].active == 0)
        return -1;

    struct petersonlock *lock = &petersonlocks[lock_id];

    lock->flag[role] = 1;
    __sync_synchronize(); // Ensure flag is visible before turn
    lock->turn = 1 - role;
    __sync_synchronize(); // Ensure turn is visible

    while (lock->flag[1 - role] && lock->turn == (1 - role)) {
        yield();
        __sync_synchronize(); // Re-check conditions after yield
    }

    return 0;
}

// Release the lock
int sys_peterson_release(void) {
    int lock_id, role;
    argint(0, &lock_id);
    argint(1, &role);

    if (lock_id < 0 || lock_id >= MAX_PETERSON_LOCKS || role < 0 || role > 1)
        return -1;
    if (petersonlocks[lock_id].active == 0)
        return -1;

    __sync_lock_release(&petersonlocks[lock_id].flag[role]);
    __sync_synchronize(); // Ensure release is visible
    return 0;
}

// Destroy the lock
int sys_peterson_destroy(void) {
    int lock_id;
    argint(0, &lock_id);

    if (lock_id < 0 || lock_id >= MAX_PETERSON_LOCKS || petersonlocks[lock_id].active == 0)
        return -1;

    petersonlocks[lock_id].flag[0] = 0;
    petersonlocks[lock_id].flag[1] = 0;
    petersonlocks[lock_id].turn = 0;
    __sync_lock_release(&petersonlocks[lock_id].active);
    __sync_synchronize(); // Ensure deactivation is visible
    return 0;
}