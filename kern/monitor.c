// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/trap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display information about the kernel", mon_backtrace },
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t eip, ebp = read_ebp();
	uint32_t ii = 0;

	struct Eipdebuginfo _eip_info;

	while (0 != ebp) {
		eip = *(uint32_t*)(ebp + sizeof(uint32_t));
		cprintf("ebp %x eip %x args ",
		ebp,
		eip);
		
		// five args (or local vars from caller)
		for (ii = 0; ii < 5; ++ii)
			cprintf("%08x ",
				*(uint32_t*)(ebp + (ii + 2) * sizeof(uint32_t)));
		cprintf("\n");

		if (0 == debuginfo_eip(eip, &_eip_info))
			cprintf("%s:%d: %.*s+%d\n", _eip_info.eip_file,
					       _eip_info.eip_line,
					       _eip_info.eip_fn_namelen,
			      		       _eip_info.eip_fn_name,
					       (eip - _eip_info.eip_fn_addr));
		else
			cprintf("no info has been found\n");
	ebp = (uint32_t)(*(uint32_t*)ebp);
	}
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	if (tf != NULL) {
		print_trapframe(tf);
		if (tf->tf_trapno == T_BRKPT) return;
	}

	while (1) {
		buf = readline("K> ");

		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}


void
mon_dbg(struct Trapframe *tf) {
	char *buf;
	size_t j,i = 0;

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("DBG> ");

		if (!strcmp(buf, "s")) {
			for(j = i; j < i + 8; j++){
				cprintf("%p : %02x", (uint32_t*)tf->tf_eip+j, *((uint8_t*)((uint32_t*)tf->tf_eip+j)+0));
				cprintf("%02x",    				 			  *((uint8_t*)((uint32_t*)tf->tf_eip+j)+1));
				cprintf("%02x",    				 			  *((uint8_t*)((uint32_t*)tf->tf_eip+j)+2));
				cprintf("%02x\n",  				 			  *((uint8_t*)((uint32_t*)tf->tf_eip+j)+3));
			}
			i = j;
			cprintf("\n");
		}
		// set breakpoint on next instr
		if (!strncmp(buf, "b", 1)) {
			if(strlen(buf) == 1) {
			// store one byte = *(uint8_t*)tf->tf_eip; use reg_oesp
//				tf->tf_regs.reg_oesp = tf->tf_eip /*+ sizeof(cur_ins)*/;
				*(uint8_t*)tf->tf_eip /* + sizeof(cur_ins)*/ = 0xcc;
			}
			else {
				// need somehow to check if addr is valid
				
//				if (*(((uint8_t*)tf->tf_eip)-1) == 0xcc) { //< restore previously replaced ins
//						*(((uint8_t*)tf->tf_eip)-1) = tf->tf_regs.reg_oesp;
//						tf->tf_eip -= 1;
//			}
				tf->tf_regs.reg_oesp = *(uint8_t*)strtol(buf+2, NULL, 16);
				*(uint8_t*)strtol(buf+2, NULL, 16) = 0xcc;
			}
		}
		// signle instruction
		if (!strcmp(buf, "si")) {
				tf->tf_eflags |= (uint32_t)0x100;
				return;
		}
		if (!strcmp(buf, "ca")) {
				tf->tf_eflags &= ~(uint32_t)0x100;
				return;
		}
		if (!strcmp(buf, "c"))
				break;
	}
}
