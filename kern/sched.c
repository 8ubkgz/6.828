#include <inc/assert.h>
#include <inc/x86.h>
#include <kern/spinlock.h>
#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/monitor.h>

void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
	struct Env *idle = NULL;

	// Implement simple round-robin scheduling.
	//
	// Search through 'envs' for an ENV_RUNNABLE environment in
	// circular fashion starting just after the env this CPU was
	// last running.  Switch to the first such environment found.
	//
	// If no envs are runnable, but the environment previously
	// running on this CPU is still ENV_RUNNING, it's okay to
	// choose that environment.
	//
	// Never choose an environment that's currently running on
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	
	// first acquisition of boot cpu
	if (curenv == NULL && cpunum() == bootcpu->cpu_id) {
			cprintf("run initial env\n");
			env_run(envs);
	}
	
	if (curenv == NULL) {
		cprintf("CPU %u curenv is NULL\n", cpunum());
		curenv = envs;
	}
	idle = curenv+1;
	
	size_t guard_counter =0;

_Continue_loop:
	while(idle != curenv) {

			if (NENV < (guard_counter++)) {
					panic("guard_counter > NENV");
			}

		if (idle->env_link == NULL) {
			idle = envs;
			continue;
		}
		switch (idle->env_status) {
			case ENV_RUNNABLE:
					goto _Exit_loop;
			case ENV_RUNNING:
			case ENV_FREE:
			case ENV_DYING:
			case ENV_NOT_RUNNABLE:
					idle = idle+1;
					goto _Continue_loop;
		}
	}

_Exit_loop:
	if (idle != curenv)
		env_run(idle);
	else if (idle == curenv && idle->env_status == ENV_RUNNING)
			if ((idle == envs && cpunum() == bootcpu->cpu_id) || (idle != envs))
				env_run(idle);
	
	sched_halt();
}

// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
	int i;
	cprintf("CPU %u halted\n", cpunum());
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
		while (1)
			monitor(NULL);
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
	lcr3(PADDR(kern_pgdir));

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
		"movl $0, %%ebp\n"
		"movl %0, %%esp\n"
		"pushl $0\n"
		"pushl $0\n"
//		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}

