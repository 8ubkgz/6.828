// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	uint32_t id = 5;
	asm("int $3");
	cprintf("hello, world %u\n", id);
//	cprintf("i am environment %08x\n", thisenv->env_id);
}
