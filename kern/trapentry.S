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
#define TRAPHANDLER(name, num) \
.text; \
	.globl name; /* define global symbol for 'name' */ \
	.type name, @function; /* symbol type is function */ \
	.align 2; /* align function definition */ \
	name: /* function starts here */ \
	pushl $(num); \
	jmp _alltraps; \
.data; \
	.long name

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num) \
.text; \
	.globl name; \
	.type name, @function; \
	.align 2; \
	name: \
	pushl $0; \
	pushl $(num); \
	jmp _alltraps; \
.data;	\
	.long name

.data;
	.globl vectors
vectors:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(isr0, T_DIVIDE);
TRAPHANDLER_NOEC(isr1, T_DEBUG);
TRAPHANDLER_NOEC(isr2, T_NMI);
TRAPHANDLER_NOEC(isr3, T_BRKPT);
TRAPHANDLER_NOEC (isr4  ,  T_OFLOW   ); 
TRAPHANDLER_NOEC (isr5  ,  T_BOUND   ); 
TRAPHANDLER_NOEC (isr6  ,  T_ILLOP   ); 
TRAPHANDLER_NOEC (isr7  ,  T_DEVICE  ); 
TRAPHANDLER_NOEC (isr8  ,  T_DBLFLT  ); 
TRAPHANDLER_NOEC (isr9  ,  T_TSS     ); 
TRAPHANDLER_NOEC (isr10  , T_SEGNP   ); 
TRAPHANDLER_NOEC (isr11  , T_STACK   ); 
TRAPHANDLER (isr12  , T_GPFLT   ); 
//TRAPHANDLER (isr13  , T_PGFLT ); 
.text;
	.globl isr13;
	.type isr13, @function;
	.align 2;
isr13:
	movl %ebp,%eax; //< way to check if error_code has been push by cpu 
	xorl %esp,%eax; //
	andl $4, %eax;; //
	jz _error_pushed;
	pushl $0; //< error code
	pushl $T_GPFLT;
	jmp _alltraps
_error_pushed:
	pushl $T_PGFLT;
	jmp _alltraps;
.data;
	.long isr13

TRAPHANDLER_NOEC (isr14  , T_FPERR  ); 
TRAPHANDLER_NOEC (isr15  , T_ALIGN   ); 
TRAPHANDLER_NOEC (isr16  , T_MCHK    ); 
TRAPHANDLER_NOEC (isr17  , T_SIMDERR ); 
TRAPHANDLER_NOEC (isr18  , T_SYSCALL ); 
TRAPHANDLER_NOEC (isr19  , T_DEFAULT ); 

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
	pushl %es
	pushal
	mov $GD_KT, %eax
	mov %eax,%ds
	mov %eax,%es
	
	pushl %esp
	call trap

