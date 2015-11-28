/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(isr0, T_DIVIDE);
TRAPHANDLER_NOEC(isr1, T_DEBUG);
TRAPHANDLER_NOEC(isr2, T_NMI);
TRAPHANDLER_NOEC(isr3, T_BRKPT);
TRAPHANDLER_NOEC(syscall_isr, 0x50);
// TRAPHANDLER ( hT_DEBUG   , T_DEBUG   ); 
// TRAPHANDLER ( hT_NMI     , T_NMI     ); 
// TRAPHANDLER ( hT_BRKPT   , T_BRKPT   ); 
// TRAPHANDLER ( hT_OFLOW   , T_OFLOW   ); 
// TRAPHANDLER ( hT_BOUND   , T_BOUND   ); 
// TRAPHANDLER ( hT_ILLOP   , T_ILLOP   ); 
// TRAPHANDLER ( hT_DEVICE  , T_DEVICE  ); 
// TRAPHANDLER ( hT_DBLFLT  , T_DBLFLT  ); 
// TRAPHANDLER ( hT_TSS     , T_TSS     ); 
// TRAPHANDLER ( hT_SEGNP   , T_SEGNP   ); 
// TRAPHANDLER ( hT_STACK   , T_STACK   ); 
// TRAPHANDLER ( hT_GPFLT   , T_GPFLT   ); 
// TRAPHANDLER ( hT_PGFLT   , T_PGFLT   ); 
// TRAPHANDLER ( hT_FPERR   , T_FPERR   ); 
// TRAPHANDLER ( hT_ALIGN   , T_ALIGN   ); 
// TRAPHANDLER ( hT_MCHK    , T_MCHK    ); 
// TRAPHANDLER ( hT_SIMDERR , T_SIMDERR ); 
// TRAPHANDLER ( hT_SYSCALL , T_SYSCALL ); 
// TRAPHANDLER ( hT_DEFAULT , T_DEFAULT ); 

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	movw %ds,%ax
	pushl %eax
	movw %es,%ax
	pushl %eax
	pushal
	mov $GD_KT, %eax
	mov %eax,%ds
	mov %eax,%es
	
	pushl %esp
	call trap

