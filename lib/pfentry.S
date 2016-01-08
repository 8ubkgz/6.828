#include <inc/mmu.h>
#include <inc/memlayout.h>

// Page fault upcall entrypoint.

// This is where we ask the kernel to redirect us to whenever we cause
// a page fault in user space (see the call to sys_set_pgfault_handler
// in pgfault.c).
//
// When a page fault actually occurs, the kernel switches our ESP to
// point to the user exception stack if we're not already on the user
// exception stack, and then it pushes a UTrapframe onto our user
// exception stack:
//
//	trap-time esp
//	trap-time eflags
//	trap-time eip
//	utf_regs.reg_eax
//	...
//	utf_regs.reg_esi
//	utf_regs.reg_edi
//	utf_err (error code)
//	utf_fault_va            <-- %esp
//
// If this is a recursive fault, the kernel will reserve for us a
// blank word above the trap-time esp for scratch work when we unwind
// the recursive call.
//
// We then have call up to the appropriate page fault handler in C
// code, pointed to by the global variable '_pgfault_handler'.

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp
	movl _pgfault_handler, %eax
	call *%eax
	addl $4, %esp # pop function argument
	addl $8, %esp # pop fault_va and err
	# put trap-time eip to the right possition in trap-time stack
	movl 0x20(%esp), %eax # trap-time->eip
	movl 0x28(%esp), %edx # trap-time->esp

#(((UXSTACKTOP-PGSIZE) <= tf->tf_esp) && (tf->tf_esp <= (UXSTACKTOP-1)))
	cmpl %edx, UXSTACKTOP-PGSIZE
	jnge _skip
	cmpl %edx, UXSTACKTOP-1
	jnbe _skip
	subl $4,%edx
	movl %edx,0x28(%esp)
_skip:
	movl %eax,(%edx) # movl eip,(esp-4)
	# restore general regs and eflags
	popal
	addl $4, %esp
	popfl
	popl %esp
	ret
