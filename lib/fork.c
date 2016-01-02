// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if (!(err & FEC_WR))
			panic("pgfault hasn't been caused by write");
	// TODO COW check

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	if ( 0 > ( r = sys_page_alloc(0, PFTEMP, PTE_P|PTE_U|PTE_W)))
			panic("PFTEMP page allocatation failedi %e", r);

	memmove(PFTEMP, ROUNDDOWN(addr, PGSIZE), PGSIZE);

	if ( 0 > ( r = sys_page_map(0, PFTEMP, 0, ROUNDDOWN(addr, PGSIZE), PTE_P|PTE_U|PTE_W)) ||
		 0 > ( r = sys_page_unmap(0, PFTEMP)))
			panic("pgfault handling failed %e", r);
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uint32_t new_perm = uvpt[pn] & PTE_SYSCALL;
	void * va = (void*)(pn << 12);

	if (new_perm & PTE_W) {
		new_perm ^= PTE_W|PTE_COW;
		if ( 0 > (r = sys_page_map(0, va, envid, va, new_perm)) || //< map child
			 0 > (r = sys_page_map(0, va, 0, va, new_perm)))	   //< remap parent with new perm
			 panic("child mapping failed : %e", r);
	}
	else
		if ( 0 > ( r = sys_page_map(0, va, envid, va, new_perm))) //< if perm are not changed just map child
			panic("child mapping failed : %e", r);

	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
// refer to UVPT clever mapping
// pdeno - traverse over pgdir entries
// pteno - traverse over pt entries
// ptecnt - restrict to number of pte in pt
// uvpt - va pointer to pt's
// uvpd - va pointer to pgdir

envid_t
fork(void)
{
	envid_t envid;
	int err;
	uint32_t pdeno, ptecnt, pteno;

	set_pgfault_handler(pgfault);

	envid = sys_exofork();
	if (envid < 0)
		return envid;
	if (envid == 0) {
		// Child
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// Parent
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
		if (uvpd[pdeno] == 0) {
			// skip empty PDEs
			continue;
		}

		for (ptecnt = 0, pteno = pdeno << 10; ptecnt < NPTENTRIES; ptecnt++,pteno++) {
			if (uvpt[pteno] == 0) {
				// skipt empty PTEs
				continue;
			}

			// Do not duplicate the exception stack
			if ((pteno << 12) == (UXSTACKTOP - PGSIZE))
				continue;

			if ( 0 > (err = duppage(envid, pteno)))
				panic("duppage: %e", err);
		}
	}

	// Child's mapping done, allocate a page for its exception
	// stack, set its page fault handler and mark it runnable

	if ( 0 > (err = sys_page_alloc(envid, (void *) (UXSTACKTOP - PGSIZE), PTE_P|PTE_U|PTE_W)) ||
	   ( 0 > (err = sys_env_set_pgfault_upcall(envid, thisenv->env_pgfault_upcall))) ||
	   ( 0 > (err = sys_env_set_status(envid, ENV_RUNNABLE))))
			panic("child kick-off failed: e%", err);
	return envid;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
