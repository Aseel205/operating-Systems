#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "petersonlock.h"

#define MAX_PETERSON_LOCKS 15

struct petersonlock petersonlocks[MAX_PETERSON_LOCKS];

void init_petersonlocks(void)
{
    for (int i = 0; i < MAX_PETERSON_LOCKS; i++)
    {
        petersonlocks[i].active = 0;
    }
}

// Create a new Peterson lock and return its id
int sys_peterson_create(void)
{
    for (int i = 0; i < MAX_PETERSON_LOCKS; i++)
    {
        if (__sync_lock_test_and_set(&petersonlocks[i].active, 1) == 0)
        {
            // Initialize the lock
            petersonlocks[i].flag[0] = 0;
            petersonlocks[i].flag[1] = 0;
            petersonlocks[i].turn = 0;
            __sync_synchronize();
            return i;
        }
    }
    return -1; // No available lock
}

// Acquire the Peterson lock
int sys_peterson_acquire(void)
{
    int lock_id, role;
    argint(0, &lock_id);
    argint(1, &role);

    if (lock_id < 0 || lock_id >= MAX_PETERSON_LOCKS || role < 0 || role > 1)
        return -1;
    if (petersonlocks[lock_id].active == 0)
        return -1;

    struct petersonlock *lock = &petersonlocks[lock_id];

    __sync_lock_test_and_set(&lock->flag[role], 1);
    __sync_synchronize();
    lock->turn = 1 - role;
    __sync_synchronize();

    while (lock->flag[1 - role] && lock->turn == (1 - role))
    {
        yield();
        __sync_synchronize();
    }

    return 0;
}

// Release the Peterson lock
int sys_peterson_release(void)
{
    int lock_id, role;
    argint(0, &lock_id);
    argint(1, &role);

    if (lock_id < 0 || lock_id >= MAX_PETERSON_LOCKS || role < 0 || role > 1)
        return -1;
    if (petersonlocks[lock_id].active == 0)
        return -1;

    struct petersonlock *lock = &petersonlocks[lock_id];

    __sync_lock_release(&lock->flag[role]);
    __sync_synchronize();

    return 0;
}

// Destroy a Peterson lock
int sys_peterson_destroy(void)
{
    int lock_id;
    argint(0, &lock_id);
    if (lock_id < 0)
        return -1;

    if (lock_id < 0 || lock_id >= MAX_PETERSON_LOCKS)
        return -1;
    if (petersonlocks[lock_id].active == 0)
        return -1;

    __sync_lock_release(&petersonlocks[lock_id].active);
    __sync_synchronize();

    return 0;
}
