
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 08             	sub    $0x8,%esp
	cprintf("entering test_backtrace %d\n", x);
f0100046:	83 ec 08             	sub    $0x8,%esp
f0100049:	ff 75 08             	pushl  0x8(%ebp)
f010004c:	68 00 22 10 f0       	push   $0xf0102200
f0100051:	e8 0e 0e 00 00       	call   f0100e64 <cprintf>
f0100056:	83 c4 10             	add    $0x10,%esp
	if (x > 0)
f0100059:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010005d:	7e 14                	jle    f0100073 <test_backtrace+0x33>
		test_backtrace(x-1);
f010005f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100062:	83 e8 01             	sub    $0x1,%eax
f0100065:	83 ec 0c             	sub    $0xc,%esp
f0100068:	50                   	push   %eax
f0100069:	e8 d2 ff ff ff       	call   f0100040 <test_backtrace>
f010006e:	83 c4 10             	add    $0x10,%esp
f0100071:	eb 11                	jmp    f0100084 <test_backtrace+0x44>
	else
		mon_backtrace(0, 0, 0);
f0100073:	83 ec 04             	sub    $0x4,%esp
f0100076:	6a 00                	push   $0x0
f0100078:	6a 00                	push   $0x0
f010007a:	6a 00                	push   $0x0
f010007c:	e8 ef 0a 00 00       	call   f0100b70 <mon_backtrace>
f0100081:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f0100084:	83 ec 08             	sub    $0x8,%esp
f0100087:	ff 75 08             	pushl  0x8(%ebp)
f010008a:	68 1c 22 10 f0       	push   $0xf010221c
f010008f:	e8 d0 0d 00 00       	call   f0100e64 <cprintf>
f0100094:	83 c4 10             	add    $0x10,%esp
}
f0100097:	90                   	nop
f0100098:	c9                   	leave  
f0100099:	c3                   	ret    

f010009a <i386_init>:

void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a0:	ba a4 3b 11 f0       	mov    $0xf0113ba4,%edx
f01000a5:	b8 44 35 11 f0       	mov    $0xf0113544,%eax
f01000aa:	29 c2                	sub    %eax,%edx
f01000ac:	89 d0                	mov    %edx,%eax
f01000ae:	83 ec 04             	sub    $0x4,%esp
f01000b1:	50                   	push   %eax
f01000b2:	6a 00                	push   $0x0
f01000b4:	68 44 35 11 f0       	push   $0xf0113544
f01000b9:	e8 60 1b 00 00       	call   f0101c1e <memset>
f01000be:	83 c4 10             	add    $0x10,%esp

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c1:	e8 f3 08 00 00       	call   f01009b9 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000c6:	83 ec 08             	sub    $0x8,%esp
f01000c9:	68 ac 1a 00 00       	push   $0x1aac
f01000ce:	68 37 22 10 f0       	push   $0xf0102237
f01000d3:	e8 8c 0d 00 00       	call   f0100e64 <cprintf>
f01000d8:	83 c4 10             	add    $0x10,%esp

	int x=1,y=3,z=4;
f01000db:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
f01000e2:	c7 45 f0 03 00 00 00 	movl   $0x3,-0x10(%ebp)
f01000e9:	c7 45 ec 04 00 00 00 	movl   $0x4,-0x14(%ebp)
	cprintf("x %d y %x z %d\n", x,y,z);
f01000f0:	ff 75 ec             	pushl  -0x14(%ebp)
f01000f3:	ff 75 f0             	pushl  -0x10(%ebp)
f01000f6:	ff 75 f4             	pushl  -0xc(%ebp)
f01000f9:	68 52 22 10 f0       	push   $0xf0102252
f01000fe:	e8 61 0d 00 00       	call   f0100e64 <cprintf>
f0100103:	83 c4 10             	add    $0x10,%esp

	unsigned int i=0x00646c72;
f0100106:	c7 45 e8 72 6c 64 00 	movl   $0x646c72,-0x18(%ebp)
	cprintf("H%x Wo%s\n", 57616, &i);
f010010d:	83 ec 04             	sub    $0x4,%esp
f0100110:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0100113:	50                   	push   %eax
f0100114:	68 10 e1 00 00       	push   $0xe110
f0100119:	68 62 22 10 f0       	push   $0xf0102262
f010011e:	e8 41 0d 00 00       	call   f0100e64 <cprintf>
f0100123:	83 c4 10             	add    $0x10,%esp

	cprintf("x=%d y=%d\n", 3);
f0100126:	83 ec 08             	sub    $0x8,%esp
f0100129:	6a 03                	push   $0x3
f010012b:	68 6c 22 10 f0       	push   $0xf010226c
f0100130:	e8 2f 0d 00 00       	call   f0100e64 <cprintf>
f0100135:	83 c4 10             	add    $0x10,%esp
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100138:	83 ec 0c             	sub    $0xc,%esp
f010013b:	6a 05                	push   $0x5
f010013d:	e8 fe fe ff ff       	call   f0100040 <test_backtrace>
f0100142:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100145:	83 ec 0c             	sub    $0xc,%esp
f0100148:	6a 00                	push   $0x0
f010014a:	e8 72 0c 00 00       	call   f0100dc1 <monitor>
f010014f:	83 c4 10             	add    $0x10,%esp
f0100152:	eb f1                	jmp    f0100145 <i386_init+0xab>

f0100154 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100154:	55                   	push   %ebp
f0100155:	89 e5                	mov    %esp,%ebp
f0100157:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f010015a:	a1 a0 3b 11 f0       	mov    0xf0113ba0,%eax
f010015f:	85 c0                	test   %eax,%eax
f0100161:	74 02                	je     f0100165 <_panic+0x11>
		goto dead;
f0100163:	eb 48                	jmp    f01001ad <_panic+0x59>
	panicstr = fmt;
f0100165:	8b 45 10             	mov    0x10(%ebp),%eax
f0100168:	a3 a0 3b 11 f0       	mov    %eax,0xf0113ba0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010016d:	fa                   	cli    
f010016e:	fc                   	cld    

	va_start(ap, fmt);
f010016f:	8d 45 14             	lea    0x14(%ebp),%eax
f0100172:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100175:	83 ec 04             	sub    $0x4,%esp
f0100178:	ff 75 0c             	pushl  0xc(%ebp)
f010017b:	ff 75 08             	pushl  0x8(%ebp)
f010017e:	68 77 22 10 f0       	push   $0xf0102277
f0100183:	e8 dc 0c 00 00       	call   f0100e64 <cprintf>
f0100188:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f010018b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010018e:	83 ec 08             	sub    $0x8,%esp
f0100191:	50                   	push   %eax
f0100192:	ff 75 10             	pushl  0x10(%ebp)
f0100195:	e8 a1 0c 00 00       	call   f0100e3b <vcprintf>
f010019a:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f010019d:	83 ec 0c             	sub    $0xc,%esp
f01001a0:	68 8f 22 10 f0       	push   $0xf010228f
f01001a5:	e8 ba 0c 00 00       	call   f0100e64 <cprintf>
f01001aa:	83 c4 10             	add    $0x10,%esp
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01001ad:	83 ec 0c             	sub    $0xc,%esp
f01001b0:	6a 00                	push   $0x0
f01001b2:	e8 0a 0c 00 00       	call   f0100dc1 <monitor>
f01001b7:	83 c4 10             	add    $0x10,%esp
f01001ba:	eb f1                	jmp    f01001ad <_panic+0x59>

f01001bc <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01001c2:	8d 45 14             	lea    0x14(%ebp),%eax
f01001c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f01001c8:	83 ec 04             	sub    $0x4,%esp
f01001cb:	ff 75 0c             	pushl  0xc(%ebp)
f01001ce:	ff 75 08             	pushl  0x8(%ebp)
f01001d1:	68 91 22 10 f0       	push   $0xf0102291
f01001d6:	e8 89 0c 00 00       	call   f0100e64 <cprintf>
f01001db:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f01001de:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01001e1:	83 ec 08             	sub    $0x8,%esp
f01001e4:	50                   	push   %eax
f01001e5:	ff 75 10             	pushl  0x10(%ebp)
f01001e8:	e8 4e 0c 00 00       	call   f0100e3b <vcprintf>
f01001ed:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f01001f0:	83 ec 0c             	sub    $0xc,%esp
f01001f3:	68 8f 22 10 f0       	push   $0xf010228f
f01001f8:	e8 67 0c 00 00       	call   f0100e64 <cprintf>
f01001fd:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f0100200:	90                   	nop
f0100201:	c9                   	leave  
f0100202:	c3                   	ret    

f0100203 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100203:	55                   	push   %ebp
f0100204:	89 e5                	mov    %esp,%ebp
f0100206:	83 ec 20             	sub    $0x20,%esp
f0100209:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100210:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100213:	89 c2                	mov    %eax,%edx
f0100215:	ec                   	in     (%dx),%al
f0100216:	88 45 ec             	mov    %al,-0x14(%ebp)
f0100219:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)
f0100220:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100223:	89 c2                	mov    %eax,%edx
f0100225:	ec                   	in     (%dx),%al
f0100226:	88 45 ed             	mov    %al,-0x13(%ebp)
f0100229:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)
f0100230:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100233:	89 c2                	mov    %eax,%edx
f0100235:	ec                   	in     (%dx),%al
f0100236:	88 45 ee             	mov    %al,-0x12(%ebp)
f0100239:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
f0100240:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100243:	89 c2                	mov    %eax,%edx
f0100245:	ec                   	in     (%dx),%al
f0100246:	88 45 ef             	mov    %al,-0x11(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f0100249:	90                   	nop
f010024a:	c9                   	leave  
f010024b:	c3                   	ret    

f010024c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010024c:	55                   	push   %ebp
f010024d:	89 e5                	mov    %esp,%ebp
f010024f:	83 ec 10             	sub    $0x10,%esp
f0100252:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
f0100259:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010025c:	89 c2                	mov    %eax,%edx
f010025e:	ec                   	in     (%dx),%al
f010025f:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f0100262:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100266:	0f b6 c0             	movzbl %al,%eax
f0100269:	83 e0 01             	and    $0x1,%eax
f010026c:	85 c0                	test   %eax,%eax
f010026e:	75 07                	jne    f0100277 <serial_proc_data+0x2b>
		return -1;
f0100270:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100275:	eb 17                	jmp    f010028e <serial_proc_data+0x42>
f0100277:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010027e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100281:	89 c2                	mov    %eax,%edx
f0100283:	ec                   	in     (%dx),%al
f0100284:	88 45 f6             	mov    %al,-0xa(%ebp)
	return data;
f0100287:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
	return inb(COM1+COM_RX);
f010028b:	0f b6 c0             	movzbl %al,%eax
}
f010028e:	c9                   	leave  
f010028f:	c3                   	ret    

f0100290 <serial_intr>:

void
serial_intr(void)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp
f0100293:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100296:	0f b6 05 60 35 11 f0 	movzbl 0xf0113560,%eax
f010029d:	84 c0                	test   %al,%al
f010029f:	74 10                	je     f01002b1 <serial_intr+0x21>
		cons_intr(serial_proc_data);
f01002a1:	83 ec 0c             	sub    $0xc,%esp
f01002a4:	68 4c 02 10 f0       	push   $0xf010024c
f01002a9:	e8 34 06 00 00       	call   f01008e2 <cons_intr>
f01002ae:	83 c4 10             	add    $0x10,%esp
}
f01002b1:	90                   	nop
f01002b2:	c9                   	leave  
f01002b3:	c3                   	ret    

f01002b4 <serial_putc>:

static void
serial_putc(int c)
{
f01002b4:	55                   	push   %ebp
f01002b5:	89 e5                	mov    %esp,%ebp
f01002b7:	83 ec 10             	sub    $0x10,%esp
	int i;

	for (i = 0;
f01002ba:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01002c1:	eb 09                	jmp    f01002cc <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002c3:	e8 3b ff ff ff       	call   f0100203 <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01002cc:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01002d6:	89 c2                	mov    %eax,%edx
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	88 45 f3             	mov    %al,-0xd(%ebp)
	return data;
f01002dc:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	0f b6 c0             	movzbl %al,%eax
f01002e3:	83 e0 20             	and    $0x20,%eax
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002e6:	85 c0                	test   %eax,%eax
f01002e8:	75 09                	jne    f01002f3 <serial_putc+0x3f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002ea:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
f01002f1:	7e d0                	jle    f01002c3 <serial_putc+0xf>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01002f6:	0f b6 c0             	movzbl %al,%eax
f01002f9:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)
f0100300:	88 45 f2             	mov    %al,-0xe(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100303:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
f0100307:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010030a:	ee                   	out    %al,(%dx)
}
f010030b:	90                   	nop
f010030c:	c9                   	leave  
f010030d:	c3                   	ret    

f010030e <serial_init>:

static void
serial_init(void)
{
f010030e:	55                   	push   %ebp
f010030f:	89 e5                	mov    %esp,%ebp
f0100311:	83 ec 40             	sub    $0x40,%esp
f0100314:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f010031b:	c6 45 ce 00          	movb   $0x0,-0x32(%ebp)
f010031f:	0f b6 45 ce          	movzbl -0x32(%ebp),%eax
f0100323:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100326:	ee                   	out    %al,(%dx)
f0100327:	c7 45 f8 fb 03 00 00 	movl   $0x3fb,-0x8(%ebp)
f010032e:	c6 45 cf 80          	movb   $0x80,-0x31(%ebp)
f0100332:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
f0100336:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100339:	ee                   	out    %al,(%dx)
f010033a:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
f0100341:	c6 45 d0 0c          	movb   $0xc,-0x30(%ebp)
f0100345:	0f b6 45 d0          	movzbl -0x30(%ebp),%eax
f0100349:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010034c:	ee                   	out    %al,(%dx)
f010034d:	c7 45 f0 f9 03 00 00 	movl   $0x3f9,-0x10(%ebp)
f0100354:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
f0100358:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
f010035c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010035f:	ee                   	out    %al,(%dx)
f0100360:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
f0100367:	c6 45 d2 03          	movb   $0x3,-0x2e(%ebp)
f010036b:	0f b6 45 d2          	movzbl -0x2e(%ebp),%eax
f010036f:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100372:	ee                   	out    %al,(%dx)
f0100373:	c7 45 e8 fc 03 00 00 	movl   $0x3fc,-0x18(%ebp)
f010037a:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f010037e:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
f0100382:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100385:	ee                   	out    %al,(%dx)
f0100386:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f010038d:	c6 45 d4 01          	movb   $0x1,-0x2c(%ebp)
f0100391:	0f b6 45 d4          	movzbl -0x2c(%ebp),%eax
f0100395:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100398:	ee                   	out    %al,(%dx)
f0100399:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01003a3:	89 c2                	mov    %eax,%edx
f01003a5:	ec                   	in     (%dx),%al
f01003a6:	88 45 d5             	mov    %al,-0x2b(%ebp)
	return data;
f01003a9:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01003ad:	3c ff                	cmp    $0xff,%al
f01003af:	0f 95 c0             	setne  %al
f01003b2:	a2 60 35 11 f0       	mov    %al,0xf0113560
f01003b7:	c7 45 dc fa 03 00 00 	movl   $0x3fa,-0x24(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003be:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01003c1:	89 c2                	mov    %eax,%edx
f01003c3:	ec                   	in     (%dx),%al
f01003c4:	88 45 d6             	mov    %al,-0x2a(%ebp)
f01003c7:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
f01003ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01003d1:	89 c2                	mov    %eax,%edx
f01003d3:	ec                   	in     (%dx),%al
f01003d4:	88 45 d7             	mov    %al,-0x29(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f01003d7:	90                   	nop
f01003d8:	c9                   	leave  
f01003d9:	c3                   	ret    

f01003da <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f01003da:	55                   	push   %ebp
f01003db:	89 e5                	mov    %esp,%ebp
f01003dd:	83 ec 20             	sub    $0x20,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003e0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01003e7:	eb 09                	jmp    f01003f2 <lpt_putc+0x18>
		delay();
f01003e9:	e8 15 fe ff ff       	call   f0100203 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003ee:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01003f2:	c7 45 ec 79 03 00 00 	movl   $0x379,-0x14(%ebp)
f01003f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01003fc:	89 c2                	mov    %eax,%edx
f01003fe:	ec                   	in     (%dx),%al
f01003ff:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f0100402:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
f0100406:	84 c0                	test   %al,%al
f0100408:	78 09                	js     f0100413 <lpt_putc+0x39>
f010040a:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
f0100411:	7e d6                	jle    f01003e9 <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f0100413:	8b 45 08             	mov    0x8(%ebp),%eax
f0100416:	0f b6 c0             	movzbl %al,%eax
f0100419:	c7 45 f4 78 03 00 00 	movl   $0x378,-0xc(%ebp)
f0100420:	88 45 e8             	mov    %al,-0x18(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100423:	0f b6 45 e8          	movzbl -0x18(%ebp),%eax
f0100427:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010042a:	ee                   	out    %al,(%dx)
f010042b:	c7 45 f0 7a 03 00 00 	movl   $0x37a,-0x10(%ebp)
f0100432:	c6 45 e9 0d          	movb   $0xd,-0x17(%ebp)
f0100436:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
f010043a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010043d:	ee                   	out    %al,(%dx)
f010043e:	c7 45 f8 7a 03 00 00 	movl   $0x37a,-0x8(%ebp)
f0100445:	c6 45 ea 08          	movb   $0x8,-0x16(%ebp)
f0100449:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
f010044d:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100450:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f0100451:	90                   	nop
f0100452:	c9                   	leave  
f0100453:	c3                   	ret    

f0100454 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f0100454:	55                   	push   %ebp
f0100455:	89 e5                	mov    %esp,%ebp
f0100457:	83 ec 20             	sub    $0x20,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010045a:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f0100461:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100464:	0f b7 00             	movzwl (%eax),%eax
f0100467:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16_t) 0xA55A;
f010046b:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010046e:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f0100473:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100476:	0f b7 00             	movzwl (%eax),%eax
f0100479:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010047d:	74 13                	je     f0100492 <cga_init+0x3e>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010047f:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f0100486:	c7 05 64 35 11 f0 b4 	movl   $0x3b4,0xf0113564
f010048d:	03 00 00 
f0100490:	eb 14                	jmp    f01004a6 <cga_init+0x52>
	} else {
		*cp = was;
f0100492:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100495:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
f0100499:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
f010049c:	c7 05 64 35 11 f0 d4 	movl   $0x3d4,0xf0113564
f01004a3:	03 00 00 
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01004a6:	a1 64 35 11 f0       	mov    0xf0113564,%eax
f01004ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01004ae:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
f01004b2:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
f01004b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01004b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01004ba:	a1 64 35 11 f0       	mov    0xf0113564,%eax
f01004bf:	83 c0 01             	add    $0x1,%eax
f01004c2:	89 45 ec             	mov    %eax,-0x14(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01004c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01004c8:	89 c2                	mov    %eax,%edx
f01004ca:	ec                   	in     (%dx),%al
f01004cb:	88 45 e1             	mov    %al,-0x1f(%ebp)
	return data;
f01004ce:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
f01004d2:	0f b6 c0             	movzbl %al,%eax
f01004d5:	c1 e0 08             	shl    $0x8,%eax
f01004d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f01004db:	a1 64 35 11 f0       	mov    0xf0113564,%eax
f01004e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01004e3:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004e7:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax
f01004eb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01004ee:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f01004ef:	a1 64 35 11 f0       	mov    0xf0113564,%eax
f01004f4:	83 c0 01             	add    $0x1,%eax
f01004f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01004fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01004fd:	89 c2                	mov    %eax,%edx
f01004ff:	ec                   	in     (%dx),%al
f0100500:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f0100503:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100507:	0f b6 c0             	movzbl %al,%eax
f010050a:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
f010050d:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100510:	a3 68 35 11 f0       	mov    %eax,0xf0113568
	crt_pos = pos;
f0100515:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100518:	66 a3 6c 35 11 f0    	mov    %ax,0xf011356c
}
f010051e:	90                   	nop
f010051f:	c9                   	leave  
f0100520:	c3                   	ret    

f0100521 <cga_putc>:



static void
cga_putc(int c)
{
f0100521:	55                   	push   %ebp
f0100522:	89 e5                	mov    %esp,%ebp
f0100524:	53                   	push   %ebx
f0100525:	83 ec 24             	sub    $0x24,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100528:	8b 45 08             	mov    0x8(%ebp),%eax
f010052b:	b0 00                	mov    $0x0,%al
f010052d:	85 c0                	test   %eax,%eax
f010052f:	75 07                	jne    f0100538 <cga_putc+0x17>
		c |= 0x2700;
f0100531:	81 4d 08 00 27 00 00 	orl    $0x2700,0x8(%ebp)

	switch (c & 0xff) {
f0100538:	8b 45 08             	mov    0x8(%ebp),%eax
f010053b:	0f b6 c0             	movzbl %al,%eax
f010053e:	83 f8 09             	cmp    $0x9,%eax
f0100541:	0f 84 ab 00 00 00    	je     f01005f2 <cga_putc+0xd1>
f0100547:	83 f8 09             	cmp    $0x9,%eax
f010054a:	7f 0a                	jg     f0100556 <cga_putc+0x35>
f010054c:	83 f8 08             	cmp    $0x8,%eax
f010054f:	74 14                	je     f0100565 <cga_putc+0x44>
f0100551:	e9 df 00 00 00       	jmp    f0100635 <cga_putc+0x114>
f0100556:	83 f8 0a             	cmp    $0xa,%eax
f0100559:	74 4d                	je     f01005a8 <cga_putc+0x87>
f010055b:	83 f8 0d             	cmp    $0xd,%eax
f010055e:	74 58                	je     f01005b8 <cga_putc+0x97>
f0100560:	e9 d0 00 00 00       	jmp    f0100635 <cga_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
f0100565:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f010056c:	66 85 c0             	test   %ax,%ax
f010056f:	0f 84 e6 00 00 00    	je     f010065b <cga_putc+0x13a>
			crt_pos--;
f0100575:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f010057c:	83 e8 01             	sub    $0x1,%eax
f010057f:	66 a3 6c 35 11 f0    	mov    %ax,0xf011356c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100585:	a1 68 35 11 f0       	mov    0xf0113568,%eax
f010058a:	0f b7 15 6c 35 11 f0 	movzwl 0xf011356c,%edx
f0100591:	0f b7 d2             	movzwl %dx,%edx
f0100594:	01 d2                	add    %edx,%edx
f0100596:	01 d0                	add    %edx,%eax
f0100598:	8b 55 08             	mov    0x8(%ebp),%edx
f010059b:	b2 00                	mov    $0x0,%dl
f010059d:	83 ca 20             	or     $0x20,%edx
f01005a0:	66 89 10             	mov    %dx,(%eax)
		}
		break;
f01005a3:	e9 b3 00 00 00       	jmp    f010065b <cga_putc+0x13a>
	case '\n':
		crt_pos += CRT_COLS;
f01005a8:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f01005af:	83 c0 50             	add    $0x50,%eax
f01005b2:	66 a3 6c 35 11 f0    	mov    %ax,0xf011356c
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01005b8:	0f b7 1d 6c 35 11 f0 	movzwl 0xf011356c,%ebx
f01005bf:	0f b7 0d 6c 35 11 f0 	movzwl 0xf011356c,%ecx
f01005c6:	0f b7 c1             	movzwl %cx,%eax
f01005c9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01005cf:	c1 e8 10             	shr    $0x10,%eax
f01005d2:	89 c2                	mov    %eax,%edx
f01005d4:	66 c1 ea 06          	shr    $0x6,%dx
f01005d8:	89 d0                	mov    %edx,%eax
f01005da:	c1 e0 02             	shl    $0x2,%eax
f01005dd:	01 d0                	add    %edx,%eax
f01005df:	c1 e0 04             	shl    $0x4,%eax
f01005e2:	29 c1                	sub    %eax,%ecx
f01005e4:	89 ca                	mov    %ecx,%edx
f01005e6:	89 d8                	mov    %ebx,%eax
f01005e8:	29 d0                	sub    %edx,%eax
f01005ea:	66 a3 6c 35 11 f0    	mov    %ax,0xf011356c
		break;
f01005f0:	eb 6a                	jmp    f010065c <cga_putc+0x13b>
	case '\t':
		cons_putc(' ');
f01005f2:	83 ec 0c             	sub    $0xc,%esp
f01005f5:	6a 20                	push   $0x20
f01005f7:	e8 90 03 00 00       	call   f010098c <cons_putc>
f01005fc:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f01005ff:	83 ec 0c             	sub    $0xc,%esp
f0100602:	6a 20                	push   $0x20
f0100604:	e8 83 03 00 00       	call   f010098c <cons_putc>
f0100609:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010060c:	83 ec 0c             	sub    $0xc,%esp
f010060f:	6a 20                	push   $0x20
f0100611:	e8 76 03 00 00       	call   f010098c <cons_putc>
f0100616:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100619:	83 ec 0c             	sub    $0xc,%esp
f010061c:	6a 20                	push   $0x20
f010061e:	e8 69 03 00 00       	call   f010098c <cons_putc>
f0100623:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100626:	83 ec 0c             	sub    $0xc,%esp
f0100629:	6a 20                	push   $0x20
f010062b:	e8 5c 03 00 00       	call   f010098c <cons_putc>
f0100630:	83 c4 10             	add    $0x10,%esp
		break;
f0100633:	eb 27                	jmp    f010065c <cga_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100635:	8b 0d 68 35 11 f0    	mov    0xf0113568,%ecx
f010063b:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f0100642:	8d 50 01             	lea    0x1(%eax),%edx
f0100645:	66 89 15 6c 35 11 f0 	mov    %dx,0xf011356c
f010064c:	0f b7 c0             	movzwl %ax,%eax
f010064f:	01 c0                	add    %eax,%eax
f0100651:	01 c8                	add    %ecx,%eax
f0100653:	8b 55 08             	mov    0x8(%ebp),%edx
f0100656:	66 89 10             	mov    %dx,(%eax)
		break;
f0100659:	eb 01                	jmp    f010065c <cga_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
f010065b:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010065c:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f0100663:	66 3d cf 07          	cmp    $0x7cf,%ax
f0100667:	76 59                	jbe    f01006c2 <cga_putc+0x1a1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100669:	a1 68 35 11 f0       	mov    0xf0113568,%eax
f010066e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100674:	a1 68 35 11 f0       	mov    0xf0113568,%eax
f0100679:	83 ec 04             	sub    $0x4,%esp
f010067c:	68 00 0f 00 00       	push   $0xf00
f0100681:	52                   	push   %edx
f0100682:	50                   	push   %eax
f0100683:	e8 04 16 00 00       	call   f0101c8c <memmove>
f0100688:	83 c4 10             	add    $0x10,%esp
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010068b:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f0100692:	eb 15                	jmp    f01006a9 <cga_putc+0x188>
			crt_buf[i] = 0x2700 | ' ';
f0100694:	a1 68 35 11 f0       	mov    0xf0113568,%eax
f0100699:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010069c:	01 d2                	add    %edx,%edx
f010069e:	01 d0                	add    %edx,%eax
f01006a0:	66 c7 00 20 27       	movw   $0x2720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01006a5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f01006a9:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f01006b0:	7e e2                	jle    f0100694 <cga_putc+0x173>
			crt_buf[i] = 0x2700 | ' ';
		crt_pos -= CRT_COLS;
f01006b2:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f01006b9:	83 e8 50             	sub    $0x50,%eax
f01006bc:	66 a3 6c 35 11 f0    	mov    %ax,0xf011356c
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01006c2:	a1 64 35 11 f0       	mov    0xf0113564,%eax
f01006c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01006ca:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ce:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
f01006d2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01006d5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01006d6:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f01006dd:	66 c1 e8 08          	shr    $0x8,%ax
f01006e1:	0f b6 c0             	movzbl %al,%eax
f01006e4:	8b 15 64 35 11 f0    	mov    0xf0113564,%edx
f01006ea:	83 c2 01             	add    $0x1,%edx
f01006ed:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01006f0:	88 45 e1             	mov    %al,-0x1f(%ebp)
f01006f3:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
f01006f7:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01006fa:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f01006fb:	a1 64 35 11 f0       	mov    0xf0113564,%eax
f0100700:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0100703:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
f0100707:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax
f010070b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010070e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f010070f:	0f b7 05 6c 35 11 f0 	movzwl 0xf011356c,%eax
f0100716:	0f b6 c0             	movzbl %al,%eax
f0100719:	8b 15 64 35 11 f0    	mov    0xf0113564,%edx
f010071f:	83 c2 01             	add    $0x1,%edx
f0100722:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100725:	88 45 e3             	mov    %al,-0x1d(%ebp)
f0100728:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010072c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010072f:	ee                   	out    %al,(%dx)
}
f0100730:	90                   	nop
f0100731:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100734:	c9                   	leave  
f0100735:	c3                   	ret    

f0100736 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100736:	55                   	push   %ebp
f0100737:	89 e5                	mov    %esp,%ebp
f0100739:	83 ec 28             	sub    $0x28,%esp
f010073c:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100743:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100746:	89 c2                	mov    %eax,%edx
f0100748:	ec                   	in     (%dx),%al
f0100749:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010074c:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100750:	0f b6 c0             	movzbl %al,%eax
f0100753:	83 e0 01             	and    $0x1,%eax
f0100756:	85 c0                	test   %eax,%eax
f0100758:	75 0a                	jne    f0100764 <kbd_proc_data+0x2e>
		return -1;
f010075a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010075f:	e9 5d 01 00 00       	jmp    f01008c1 <kbd_proc_data+0x18b>
f0100764:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010076b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010076e:	89 c2                	mov    %eax,%edx
f0100770:	ec                   	in     (%dx),%al
f0100771:	88 45 e2             	mov    %al,-0x1e(%ebp)
	return data;
f0100774:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax

	data = inb(KBDATAP);
f0100778:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f010077b:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f010077f:	75 17                	jne    f0100798 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
f0100781:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f0100786:	83 c8 40             	or     $0x40,%eax
f0100789:	a3 88 37 11 f0       	mov    %eax,0xf0113788
		return 0;
f010078e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100793:	e9 29 01 00 00       	jmp    f01008c1 <kbd_proc_data+0x18b>
	} else if (data & 0x80) {
f0100798:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010079c:	84 c0                	test   %al,%al
f010079e:	79 47                	jns    f01007e7 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01007a0:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f01007a5:	83 e0 40             	and    $0x40,%eax
f01007a8:	85 c0                	test   %eax,%eax
f01007aa:	75 09                	jne    f01007b5 <kbd_proc_data+0x7f>
f01007ac:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007b0:	83 e0 7f             	and    $0x7f,%eax
f01007b3:	eb 04                	jmp    f01007b9 <kbd_proc_data+0x83>
f01007b5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007b9:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f01007bc:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007c0:	0f b6 80 00 30 11 f0 	movzbl -0xfeed000(%eax),%eax
f01007c7:	83 c8 40             	or     $0x40,%eax
f01007ca:	0f b6 c0             	movzbl %al,%eax
f01007cd:	f7 d0                	not    %eax
f01007cf:	89 c2                	mov    %eax,%edx
f01007d1:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f01007d6:	21 d0                	and    %edx,%eax
f01007d8:	a3 88 37 11 f0       	mov    %eax,0xf0113788
		return 0;
f01007dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e2:	e9 da 00 00 00       	jmp    f01008c1 <kbd_proc_data+0x18b>
	} else if (shift & E0ESC) {
f01007e7:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f01007ec:	83 e0 40             	and    $0x40,%eax
f01007ef:	85 c0                	test   %eax,%eax
f01007f1:	74 11                	je     f0100804 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01007f3:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f01007f7:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f01007fc:	83 e0 bf             	and    $0xffffffbf,%eax
f01007ff:	a3 88 37 11 f0       	mov    %eax,0xf0113788
	}

	shift |= shiftcode[data];
f0100804:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100808:	0f b6 80 00 30 11 f0 	movzbl -0xfeed000(%eax),%eax
f010080f:	0f b6 d0             	movzbl %al,%edx
f0100812:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f0100817:	09 d0                	or     %edx,%eax
f0100819:	a3 88 37 11 f0       	mov    %eax,0xf0113788
	shift ^= togglecode[data];
f010081e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100822:	0f b6 80 00 31 11 f0 	movzbl -0xfeecf00(%eax),%eax
f0100829:	0f b6 d0             	movzbl %al,%edx
f010082c:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f0100831:	31 d0                	xor    %edx,%eax
f0100833:	a3 88 37 11 f0       	mov    %eax,0xf0113788

	c = charcode[shift & (CTL | SHIFT)][data];
f0100838:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f010083d:	83 e0 03             	and    $0x3,%eax
f0100840:	8b 14 85 00 35 11 f0 	mov    -0xfeecb00(,%eax,4),%edx
f0100847:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010084b:	01 d0                	add    %edx,%eax
f010084d:	0f b6 00             	movzbl (%eax),%eax
f0100850:	0f b6 c0             	movzbl %al,%eax
f0100853:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f0100856:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f010085b:	83 e0 08             	and    $0x8,%eax
f010085e:	85 c0                	test   %eax,%eax
f0100860:	74 22                	je     f0100884 <kbd_proc_data+0x14e>
		if ('a' <= c && c <= 'z')
f0100862:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f0100866:	7e 0c                	jle    f0100874 <kbd_proc_data+0x13e>
f0100868:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f010086c:	7f 06                	jg     f0100874 <kbd_proc_data+0x13e>
			c += 'A' - 'a';
f010086e:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f0100872:	eb 10                	jmp    f0100884 <kbd_proc_data+0x14e>
		else if ('A' <= c && c <= 'Z')
f0100874:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f0100878:	7e 0a                	jle    f0100884 <kbd_proc_data+0x14e>
f010087a:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f010087e:	7f 04                	jg     f0100884 <kbd_proc_data+0x14e>
			c += 'a' - 'A';
f0100880:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100884:	a1 88 37 11 f0       	mov    0xf0113788,%eax
f0100889:	f7 d0                	not    %eax
f010088b:	83 e0 06             	and    $0x6,%eax
f010088e:	85 c0                	test   %eax,%eax
f0100890:	75 2c                	jne    f01008be <kbd_proc_data+0x188>
f0100892:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f0100899:	75 23                	jne    f01008be <kbd_proc_data+0x188>
		cprintf("Rebooting!\n");
f010089b:	83 ec 0c             	sub    $0xc,%esp
f010089e:	68 ab 22 10 f0       	push   $0xf01022ab
f01008a3:	e8 bc 05 00 00       	call   f0100e64 <cprintf>
f01008a8:	83 c4 10             	add    $0x10,%esp
f01008ab:	c7 45 e8 92 00 00 00 	movl   $0x92,-0x18(%ebp)
f01008b2:	c6 45 e1 03          	movb   $0x3,-0x1f(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01008b6:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
f01008ba:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01008bd:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01008be:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01008c1:	c9                   	leave  
f01008c2:	c3                   	ret    

f01008c3 <kbd_intr>:

void
kbd_intr(void)
{
f01008c3:	55                   	push   %ebp
f01008c4:	89 e5                	mov    %esp,%ebp
f01008c6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01008c9:	83 ec 0c             	sub    $0xc,%esp
f01008cc:	68 36 07 10 f0       	push   $0xf0100736
f01008d1:	e8 0c 00 00 00       	call   f01008e2 <cons_intr>
f01008d6:	83 c4 10             	add    $0x10,%esp
}
f01008d9:	90                   	nop
f01008da:	c9                   	leave  
f01008db:	c3                   	ret    

f01008dc <kbd_init>:

static void
kbd_init(void)
{
f01008dc:	55                   	push   %ebp
f01008dd:	89 e5                	mov    %esp,%ebp
}
f01008df:	90                   	nop
f01008e0:	5d                   	pop    %ebp
f01008e1:	c3                   	ret    

f01008e2 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01008e2:	55                   	push   %ebp
f01008e3:	89 e5                	mov    %esp,%ebp
f01008e5:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f01008e8:	eb 35                	jmp    f010091f <cons_intr+0x3d>
		if (c == 0)
f01008ea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01008ee:	75 02                	jne    f01008f2 <cons_intr+0x10>
			continue;
f01008f0:	eb 2d                	jmp    f010091f <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f01008f2:	a1 84 37 11 f0       	mov    0xf0113784,%eax
f01008f7:	8d 50 01             	lea    0x1(%eax),%edx
f01008fa:	89 15 84 37 11 f0    	mov    %edx,0xf0113784
f0100900:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100903:	88 90 80 35 11 f0    	mov    %dl,-0xfeeca80(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100909:	a1 84 37 11 f0       	mov    0xf0113784,%eax
f010090e:	3d 00 02 00 00       	cmp    $0x200,%eax
f0100913:	75 0a                	jne    f010091f <cons_intr+0x3d>
			cons.wpos = 0;
f0100915:	c7 05 84 37 11 f0 00 	movl   $0x0,0xf0113784
f010091c:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010091f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100922:	ff d0                	call   *%eax
f0100924:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100927:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f010092b:	75 bd                	jne    f01008ea <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010092d:	90                   	nop
f010092e:	c9                   	leave  
f010092f:	c3                   	ret    

f0100930 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100930:	55                   	push   %ebp
f0100931:	89 e5                	mov    %esp,%ebp
f0100933:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100936:	e8 55 f9 ff ff       	call   f0100290 <serial_intr>
	kbd_intr();
f010093b:	e8 83 ff ff ff       	call   f01008c3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100940:	8b 15 80 37 11 f0    	mov    0xf0113780,%edx
f0100946:	a1 84 37 11 f0       	mov    0xf0113784,%eax
f010094b:	39 c2                	cmp    %eax,%edx
f010094d:	74 36                	je     f0100985 <cons_getc+0x55>
		c = cons.buf[cons.rpos++];
f010094f:	a1 80 37 11 f0       	mov    0xf0113780,%eax
f0100954:	8d 50 01             	lea    0x1(%eax),%edx
f0100957:	89 15 80 37 11 f0    	mov    %edx,0xf0113780
f010095d:	0f b6 80 80 35 11 f0 	movzbl -0xfeeca80(%eax),%eax
f0100964:	0f b6 c0             	movzbl %al,%eax
f0100967:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f010096a:	a1 80 37 11 f0       	mov    0xf0113780,%eax
f010096f:	3d 00 02 00 00       	cmp    $0x200,%eax
f0100974:	75 0a                	jne    f0100980 <cons_getc+0x50>
			cons.rpos = 0;
f0100976:	c7 05 80 37 11 f0 00 	movl   $0x0,0xf0113780
f010097d:	00 00 00 
		return c;
f0100980:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100983:	eb 05                	jmp    f010098a <cons_getc+0x5a>
	}
	return 0;
f0100985:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010098a:	c9                   	leave  
f010098b:	c3                   	ret    

f010098c <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
f010098c:	55                   	push   %ebp
f010098d:	89 e5                	mov    %esp,%ebp
f010098f:	83 ec 08             	sub    $0x8,%esp
	serial_putc(c);
f0100992:	ff 75 08             	pushl  0x8(%ebp)
f0100995:	e8 1a f9 ff ff       	call   f01002b4 <serial_putc>
f010099a:	83 c4 04             	add    $0x4,%esp
	lpt_putc(c);
f010099d:	ff 75 08             	pushl  0x8(%ebp)
f01009a0:	e8 35 fa ff ff       	call   f01003da <lpt_putc>
f01009a5:	83 c4 04             	add    $0x4,%esp
	cga_putc(c);
f01009a8:	83 ec 0c             	sub    $0xc,%esp
f01009ab:	ff 75 08             	pushl  0x8(%ebp)
f01009ae:	e8 6e fb ff ff       	call   f0100521 <cga_putc>
f01009b3:	83 c4 10             	add    $0x10,%esp
}
f01009b6:	90                   	nop
f01009b7:	c9                   	leave  
f01009b8:	c3                   	ret    

f01009b9 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01009b9:	55                   	push   %ebp
f01009ba:	89 e5                	mov    %esp,%ebp
f01009bc:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01009bf:	e8 90 fa ff ff       	call   f0100454 <cga_init>
	kbd_init();
f01009c4:	e8 13 ff ff ff       	call   f01008dc <kbd_init>
	serial_init();
f01009c9:	e8 40 f9 ff ff       	call   f010030e <serial_init>

	if (!serial_exists)
f01009ce:	0f b6 05 60 35 11 f0 	movzbl 0xf0113560,%eax
f01009d5:	83 f0 01             	xor    $0x1,%eax
f01009d8:	84 c0                	test   %al,%al
f01009da:	74 10                	je     f01009ec <cons_init+0x33>
		cprintf("Serial port does not exist!\n");
f01009dc:	83 ec 0c             	sub    $0xc,%esp
f01009df:	68 b7 22 10 f0       	push   $0xf01022b7
f01009e4:	e8 7b 04 00 00       	call   f0100e64 <cprintf>
f01009e9:	83 c4 10             	add    $0x10,%esp
}
f01009ec:	90                   	nop
f01009ed:	c9                   	leave  
f01009ee:	c3                   	ret    

f01009ef <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01009ef:	55                   	push   %ebp
f01009f0:	89 e5                	mov    %esp,%ebp
f01009f2:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01009f5:	83 ec 0c             	sub    $0xc,%esp
f01009f8:	ff 75 08             	pushl  0x8(%ebp)
f01009fb:	e8 8c ff ff ff       	call   f010098c <cons_putc>
f0100a00:	83 c4 10             	add    $0x10,%esp
}
f0100a03:	90                   	nop
f0100a04:	c9                   	leave  
f0100a05:	c3                   	ret    

f0100a06 <getchar>:

int
getchar(void)
{
f0100a06:	55                   	push   %ebp
f0100a07:	89 e5                	mov    %esp,%ebp
f0100a09:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100a0c:	e8 1f ff ff ff       	call   f0100930 <cons_getc>
f0100a11:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100a14:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100a18:	74 f2                	je     f0100a0c <getchar+0x6>
		/* do nothing */;
	return c;
f0100a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100a1d:	c9                   	leave  
f0100a1e:	c3                   	ret    

f0100a1f <iscons>:

int
iscons(int fdnum)
{
f0100a1f:	55                   	push   %ebp
f0100a20:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f0100a22:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0100a27:	5d                   	pop    %ebp
f0100a28:	c3                   	ret    

f0100a29 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100a29:	55                   	push   %ebp
f0100a2a:	89 e5                	mov    %esp,%ebp
f0100a2c:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100a2f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100a36:	eb 3c                	jmp    f0100a74 <mon_help+0x4b>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100a38:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a3b:	89 d0                	mov    %edx,%eax
f0100a3d:	01 c0                	add    %eax,%eax
f0100a3f:	01 d0                	add    %edx,%eax
f0100a41:	c1 e0 02             	shl    $0x2,%eax
f0100a44:	05 24 35 11 f0       	add    $0xf0113524,%eax
f0100a49:	8b 08                	mov    (%eax),%ecx
f0100a4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a4e:	89 d0                	mov    %edx,%eax
f0100a50:	01 c0                	add    %eax,%eax
f0100a52:	01 d0                	add    %edx,%eax
f0100a54:	c1 e0 02             	shl    $0x2,%eax
f0100a57:	05 20 35 11 f0       	add    $0xf0113520,%eax
f0100a5c:	8b 00                	mov    (%eax),%eax
f0100a5e:	83 ec 04             	sub    $0x4,%esp
f0100a61:	51                   	push   %ecx
f0100a62:	50                   	push   %eax
f0100a63:	68 2f 23 10 f0       	push   $0xf010232f
f0100a68:	e8 f7 03 00 00       	call   f0100e64 <cprintf>
f0100a6d:	83 c4 10             	add    $0x10,%esp
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100a70:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f0100a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a77:	83 f8 02             	cmp    $0x2,%eax
f0100a7a:	76 bc                	jbe    f0100a38 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
f0100a7c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100a81:	c9                   	leave  
f0100a82:	c3                   	ret    

f0100a83 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100a83:	55                   	push   %ebp
f0100a84:	89 e5                	mov    %esp,%ebp
f0100a86:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100a89:	83 ec 0c             	sub    $0xc,%esp
f0100a8c:	68 38 23 10 f0       	push   $0xf0102338
f0100a91:	e8 ce 03 00 00       	call   f0100e64 <cprintf>
f0100a96:	83 c4 10             	add    $0x10,%esp
	cprintf("  _start                  %08x (phys)\n", _start);
f0100a99:	83 ec 08             	sub    $0x8,%esp
f0100a9c:	68 0c 00 10 00       	push   $0x10000c
f0100aa1:	68 54 23 10 f0       	push   $0xf0102354
f0100aa6:	e8 b9 03 00 00       	call   f0100e64 <cprintf>
f0100aab:	83 c4 10             	add    $0x10,%esp
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100aae:	b8 0c 00 10 00       	mov    $0x10000c,%eax
f0100ab3:	83 ec 04             	sub    $0x4,%esp
f0100ab6:	50                   	push   %eax
f0100ab7:	68 0c 00 10 f0       	push   $0xf010000c
f0100abc:	68 7c 23 10 f0       	push   $0xf010237c
f0100ac1:	e8 9e 03 00 00       	call   f0100e64 <cprintf>
f0100ac6:	83 c4 10             	add    $0x10,%esp
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100ac9:	b8 f1 21 10 00       	mov    $0x1021f1,%eax
f0100ace:	83 ec 04             	sub    $0x4,%esp
f0100ad1:	50                   	push   %eax
f0100ad2:	68 f1 21 10 f0       	push   $0xf01021f1
f0100ad7:	68 a0 23 10 f0       	push   $0xf01023a0
f0100adc:	e8 83 03 00 00       	call   f0100e64 <cprintf>
f0100ae1:	83 c4 10             	add    $0x10,%esp
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100ae4:	b8 44 35 11 00       	mov    $0x113544,%eax
f0100ae9:	83 ec 04             	sub    $0x4,%esp
f0100aec:	50                   	push   %eax
f0100aed:	68 44 35 11 f0       	push   $0xf0113544
f0100af2:	68 c4 23 10 f0       	push   $0xf01023c4
f0100af7:	e8 68 03 00 00       	call   f0100e64 <cprintf>
f0100afc:	83 c4 10             	add    $0x10,%esp
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100aff:	b8 a4 3b 11 00       	mov    $0x113ba4,%eax
f0100b04:	83 ec 04             	sub    $0x4,%esp
f0100b07:	50                   	push   %eax
f0100b08:	68 a4 3b 11 f0       	push   $0xf0113ba4
f0100b0d:	68 e8 23 10 f0       	push   $0xf01023e8
f0100b12:	e8 4d 03 00 00       	call   f0100e64 <cprintf>
f0100b17:	83 c4 10             	add    $0x10,%esp
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100b1a:	c7 45 f4 00 04 00 00 	movl   $0x400,-0xc(%ebp)
f0100b21:	ba 0c 00 10 f0       	mov    $0xf010000c,%edx
f0100b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b29:	29 d0                	sub    %edx,%eax
f0100b2b:	89 c2                	mov    %eax,%edx
f0100b2d:	b8 a4 3b 11 f0       	mov    $0xf0113ba4,%eax
f0100b32:	83 e8 01             	sub    $0x1,%eax
f0100b35:	01 d0                	add    %edx,%eax
f0100b37:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100b42:	f7 75 f4             	divl   -0xc(%ebp)
f0100b45:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b48:	29 d0                	sub    %edx,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100b4a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100b50:	85 c0                	test   %eax,%eax
f0100b52:	0f 48 c2             	cmovs  %edx,%eax
f0100b55:	c1 f8 0a             	sar    $0xa,%eax
f0100b58:	83 ec 08             	sub    $0x8,%esp
f0100b5b:	50                   	push   %eax
f0100b5c:	68 0c 24 10 f0       	push   $0xf010240c
f0100b61:	e8 fe 02 00 00       	call   f0100e64 <cprintf>
f0100b66:	83 c4 10             	add    $0x10,%esp
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
f0100b69:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b6e:	c9                   	leave  
f0100b6f:	c3                   	ret    

f0100b70 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100b70:	55                   	push   %ebp
f0100b71:	89 e5                	mov    %esp,%ebp
f0100b73:	56                   	push   %esi
f0100b74:	53                   	push   %ebx
f0100b75:	83 ec 30             	sub    $0x30,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100b78:	89 e8                	mov    %ebp,%eax
f0100b7a:	89 45 e8             	mov    %eax,-0x18(%ebp)
	return ebp;
f0100b7d:	8b 45 e8             	mov    -0x18(%ebp),%eax
	// Your code here.
	uint32_t eip, ebp = read_ebp();
f0100b80:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t ii = 0;
f0100b83:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	struct Eipdebuginfo _eip_info;

	while (0 != ebp) {
f0100b8a:	e9 c4 00 00 00       	jmp    f0100c53 <mon_backtrace+0xe3>
		eip = *(uint32_t*)(ebp + sizeof(uint32_t));
f0100b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b92:	83 c0 04             	add    $0x4,%eax
f0100b95:	8b 00                	mov    (%eax),%eax
f0100b97:	89 45 ec             	mov    %eax,-0x14(%ebp)
		cprintf("ebp %x eip %x args ",
f0100b9a:	83 ec 04             	sub    $0x4,%esp
f0100b9d:	ff 75 ec             	pushl  -0x14(%ebp)
f0100ba0:	ff 75 f4             	pushl  -0xc(%ebp)
f0100ba3:	68 36 24 10 f0       	push   $0xf0102436
f0100ba8:	e8 b7 02 00 00       	call   f0100e64 <cprintf>
f0100bad:	83 c4 10             	add    $0x10,%esp
		ebp,
		eip);
		
		// five args (or local vars from caller)
		for (ii = 0; ii < 5; ++ii)
f0100bb0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100bb7:	eb 29                	jmp    f0100be2 <mon_backtrace+0x72>
			cprintf("%08x ",
				*(uint32_t*)(ebp + (ii + 2) * sizeof(uint32_t)));
f0100bb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bbc:	83 c0 02             	add    $0x2,%eax
f0100bbf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0100bc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100bc9:	01 d0                	add    %edx,%eax
		ebp,
		eip);
		
		// five args (or local vars from caller)
		for (ii = 0; ii < 5; ++ii)
			cprintf("%08x ",
f0100bcb:	8b 00                	mov    (%eax),%eax
f0100bcd:	83 ec 08             	sub    $0x8,%esp
f0100bd0:	50                   	push   %eax
f0100bd1:	68 4a 24 10 f0       	push   $0xf010244a
f0100bd6:	e8 89 02 00 00       	call   f0100e64 <cprintf>
f0100bdb:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %x eip %x args ",
		ebp,
		eip);
		
		// five args (or local vars from caller)
		for (ii = 0; ii < 5; ++ii)
f0100bde:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
f0100be2:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
f0100be6:	76 d1                	jbe    f0100bb9 <mon_backtrace+0x49>
			cprintf("%08x ",
				*(uint32_t*)(ebp + (ii + 2) * sizeof(uint32_t)));
		cprintf("\n");
f0100be8:	83 ec 0c             	sub    $0xc,%esp
f0100beb:	68 50 24 10 f0       	push   $0xf0102450
f0100bf0:	e8 6f 02 00 00       	call   f0100e64 <cprintf>
f0100bf5:	83 c4 10             	add    $0x10,%esp

		if (0 == debuginfo_eip(eip, &_eip_info))
f0100bf8:	83 ec 08             	sub    $0x8,%esp
f0100bfb:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100bfe:	50                   	push   %eax
f0100bff:	ff 75 ec             	pushl  -0x14(%ebp)
f0100c02:	e8 da 03 00 00       	call   f0100fe1 <debuginfo_eip>
f0100c07:	83 c4 10             	add    $0x10,%esp
f0100c0a:	85 c0                	test   %eax,%eax
f0100c0c:	75 2d                	jne    f0100c3b <mon_backtrace+0xcb>
			cprintf("%s:%d: %.*s+%d\n", _eip_info.eip_file,
					       _eip_info.eip_line,
					       _eip_info.eip_fn_namelen,
			      		       _eip_info.eip_fn_name,
					       (eip - _eip_info.eip_fn_addr));
f0100c0e:	8b 45 e0             	mov    -0x20(%ebp),%eax
			cprintf("%08x ",
				*(uint32_t*)(ebp + (ii + 2) * sizeof(uint32_t)));
		cprintf("\n");

		if (0 == debuginfo_eip(eip, &_eip_info))
			cprintf("%s:%d: %.*s+%d\n", _eip_info.eip_file,
f0100c11:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100c14:	89 d6                	mov    %edx,%esi
f0100c16:	29 c6                	sub    %eax,%esi
f0100c18:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c1b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c1e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c21:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100c24:	83 ec 08             	sub    $0x8,%esp
f0100c27:	56                   	push   %esi
f0100c28:	53                   	push   %ebx
f0100c29:	51                   	push   %ecx
f0100c2a:	52                   	push   %edx
f0100c2b:	50                   	push   %eax
f0100c2c:	68 52 24 10 f0       	push   $0xf0102452
f0100c31:	e8 2e 02 00 00       	call   f0100e64 <cprintf>
f0100c36:	83 c4 20             	add    $0x20,%esp
f0100c39:	eb 10                	jmp    f0100c4b <mon_backtrace+0xdb>
					       _eip_info.eip_line,
					       _eip_info.eip_fn_namelen,
			      		       _eip_info.eip_fn_name,
					       (eip - _eip_info.eip_fn_addr));
		else
			cprintf("no info has been found\n");
f0100c3b:	83 ec 0c             	sub    $0xc,%esp
f0100c3e:	68 62 24 10 f0       	push   $0xf0102462
f0100c43:	e8 1c 02 00 00       	call   f0100e64 <cprintf>
f0100c48:	83 c4 10             	add    $0x10,%esp
	ebp = (uint32_t)(*(uint32_t*)ebp);
f0100c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c4e:	8b 00                	mov    (%eax),%eax
f0100c50:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t eip, ebp = read_ebp();
	uint32_t ii = 0;

	struct Eipdebuginfo _eip_info;

	while (0 != ebp) {
f0100c53:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100c57:	0f 85 32 ff ff ff    	jne    f0100b8f <mon_backtrace+0x1f>
					       (eip - _eip_info.eip_fn_addr));
		else
			cprintf("no info has been found\n");
	ebp = (uint32_t)(*(uint32_t*)ebp);
	}
	return 0;
f0100c5d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c62:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c65:	5b                   	pop    %ebx
f0100c66:	5e                   	pop    %esi
f0100c67:	5d                   	pop    %ebp
f0100c68:	c3                   	ret    

f0100c69 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100c69:	55                   	push   %ebp
f0100c6a:	89 e5                	mov    %esp,%ebp
f0100c6c:	83 ec 58             	sub    $0x58,%esp
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100c6f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	argv[argc] = 0;
f0100c76:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c79:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100c80:	00 
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100c81:	eb 0c                	jmp    f0100c8f <runcmd+0x26>
			*buf++ = 0;
f0100c83:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c86:	8d 50 01             	lea    0x1(%eax),%edx
f0100c89:	89 55 08             	mov    %edx,0x8(%ebp)
f0100c8c:	c6 00 00             	movb   $0x0,(%eax)
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100c8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c92:	0f b6 00             	movzbl (%eax),%eax
f0100c95:	84 c0                	test   %al,%al
f0100c97:	74 1e                	je     f0100cb7 <runcmd+0x4e>
f0100c99:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c9c:	0f b6 00             	movzbl (%eax),%eax
f0100c9f:	0f be c0             	movsbl %al,%eax
f0100ca2:	83 ec 08             	sub    $0x8,%esp
f0100ca5:	50                   	push   %eax
f0100ca6:	68 7a 24 10 f0       	push   $0xf010247a
f0100cab:	e8 0c 0f 00 00       	call   f0101bbc <strchr>
f0100cb0:	83 c4 10             	add    $0x10,%esp
f0100cb3:	85 c0                	test   %eax,%eax
f0100cb5:	75 cc                	jne    f0100c83 <runcmd+0x1a>
			*buf++ = 0;
		if (*buf == 0)
f0100cb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cba:	0f b6 00             	movzbl (%eax),%eax
f0100cbd:	84 c0                	test   %al,%al
f0100cbf:	74 69                	je     f0100d2a <runcmd+0xc1>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100cc1:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
f0100cc5:	75 1c                	jne    f0100ce3 <runcmd+0x7a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100cc7:	83 ec 08             	sub    $0x8,%esp
f0100cca:	6a 10                	push   $0x10
f0100ccc:	68 7f 24 10 f0       	push   $0xf010247f
f0100cd1:	e8 8e 01 00 00       	call   f0100e64 <cprintf>
f0100cd6:	83 c4 10             	add    $0x10,%esp
			return 0;
f0100cd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cde:	e9 dc 00 00 00       	jmp    f0100dbf <runcmd+0x156>
		}
		argv[argc++] = buf;
f0100ce3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ce6:	8d 50 01             	lea    0x1(%eax),%edx
f0100ce9:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0100cec:	8b 55 08             	mov    0x8(%ebp),%edx
f0100cef:	89 54 85 b0          	mov    %edx,-0x50(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100cf3:	eb 04                	jmp    f0100cf9 <runcmd+0x90>
			buf++;
f0100cf5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100cf9:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cfc:	0f b6 00             	movzbl (%eax),%eax
f0100cff:	84 c0                	test   %al,%al
f0100d01:	0f 84 7a ff ff ff    	je     f0100c81 <runcmd+0x18>
f0100d07:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d0a:	0f b6 00             	movzbl (%eax),%eax
f0100d0d:	0f be c0             	movsbl %al,%eax
f0100d10:	83 ec 08             	sub    $0x8,%esp
f0100d13:	50                   	push   %eax
f0100d14:	68 7a 24 10 f0       	push   $0xf010247a
f0100d19:	e8 9e 0e 00 00       	call   f0101bbc <strchr>
f0100d1e:	83 c4 10             	add    $0x10,%esp
f0100d21:	85 c0                	test   %eax,%eax
f0100d23:	74 d0                	je     f0100cf5 <runcmd+0x8c>
			buf++;
	}
f0100d25:	e9 57 ff ff ff       	jmp    f0100c81 <runcmd+0x18>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;
f0100d2a:	90                   	nop
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f0100d2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d2e:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100d35:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100d36:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100d3a:	75 07                	jne    f0100d43 <runcmd+0xda>
		return 0;
f0100d3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d41:	eb 7c                	jmp    f0100dbf <runcmd+0x156>
	for (i = 0; i < NCOMMANDS; i++) {
f0100d43:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100d4a:	eb 52                	jmp    f0100d9e <runcmd+0x135>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100d4c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d4f:	89 d0                	mov    %edx,%eax
f0100d51:	01 c0                	add    %eax,%eax
f0100d53:	01 d0                	add    %edx,%eax
f0100d55:	c1 e0 02             	shl    $0x2,%eax
f0100d58:	05 20 35 11 f0       	add    $0xf0113520,%eax
f0100d5d:	8b 10                	mov    (%eax),%edx
f0100d5f:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100d62:	83 ec 08             	sub    $0x8,%esp
f0100d65:	52                   	push   %edx
f0100d66:	50                   	push   %eax
f0100d67:	e8 bb 0d 00 00       	call   f0101b27 <strcmp>
f0100d6c:	83 c4 10             	add    $0x10,%esp
f0100d6f:	85 c0                	test   %eax,%eax
f0100d71:	75 27                	jne    f0100d9a <runcmd+0x131>
			return commands[i].func(argc, argv, tf);
f0100d73:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d76:	89 d0                	mov    %edx,%eax
f0100d78:	01 c0                	add    %eax,%eax
f0100d7a:	01 d0                	add    %edx,%eax
f0100d7c:	c1 e0 02             	shl    $0x2,%eax
f0100d7f:	05 28 35 11 f0       	add    $0xf0113528,%eax
f0100d84:	8b 00                	mov    (%eax),%eax
f0100d86:	83 ec 04             	sub    $0x4,%esp
f0100d89:	ff 75 0c             	pushl  0xc(%ebp)
f0100d8c:	8d 55 b0             	lea    -0x50(%ebp),%edx
f0100d8f:	52                   	push   %edx
f0100d90:	ff 75 f4             	pushl  -0xc(%ebp)
f0100d93:	ff d0                	call   *%eax
f0100d95:	83 c4 10             	add    $0x10,%esp
f0100d98:	eb 25                	jmp    f0100dbf <runcmd+0x156>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100d9a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
f0100d9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100da1:	83 f8 02             	cmp    $0x2,%eax
f0100da4:	76 a6                	jbe    f0100d4c <runcmd+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100da6:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100da9:	83 ec 08             	sub    $0x8,%esp
f0100dac:	50                   	push   %eax
f0100dad:	68 9c 24 10 f0       	push   $0xf010249c
f0100db2:	e8 ad 00 00 00       	call   f0100e64 <cprintf>
f0100db7:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100dba:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100dbf:	c9                   	leave  
f0100dc0:	c3                   	ret    

f0100dc1 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100dc1:	55                   	push   %ebp
f0100dc2:	89 e5                	mov    %esp,%ebp
f0100dc4:	83 ec 18             	sub    $0x18,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100dc7:	83 ec 0c             	sub    $0xc,%esp
f0100dca:	68 b4 24 10 f0       	push   $0xf01024b4
f0100dcf:	e8 90 00 00 00       	call   f0100e64 <cprintf>
f0100dd4:	83 c4 10             	add    $0x10,%esp
	cprintf("Type 'help' for a list of commands.\n");
f0100dd7:	83 ec 0c             	sub    $0xc,%esp
f0100dda:	68 d8 24 10 f0       	push   $0xf01024d8
f0100ddf:	e8 80 00 00 00       	call   f0100e64 <cprintf>
f0100de4:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100de7:	83 ec 0c             	sub    $0xc,%esp
f0100dea:	68 fd 24 10 f0       	push   $0xf01024fd
f0100def:	e8 eb 0a 00 00       	call   f01018df <readline>
f0100df4:	83 c4 10             	add    $0x10,%esp
f0100df7:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (buf != NULL)
f0100dfa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100dfe:	74 e7                	je     f0100de7 <monitor+0x26>
			if (runcmd(buf, tf) < 0)
f0100e00:	83 ec 08             	sub    $0x8,%esp
f0100e03:	ff 75 08             	pushl  0x8(%ebp)
f0100e06:	ff 75 f4             	pushl  -0xc(%ebp)
f0100e09:	e8 5b fe ff ff       	call   f0100c69 <runcmd>
f0100e0e:	83 c4 10             	add    $0x10,%esp
f0100e11:	85 c0                	test   %eax,%eax
f0100e13:	78 02                	js     f0100e17 <monitor+0x56>
				break;
	}
f0100e15:	eb d0                	jmp    f0100de7 <monitor+0x26>

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
f0100e17:	90                   	nop
	}
}
f0100e18:	90                   	nop
f0100e19:	c9                   	leave  
f0100e1a:	c3                   	ret    

f0100e1b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100e1b:	55                   	push   %ebp
f0100e1c:	89 e5                	mov    %esp,%ebp
f0100e1e:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f0100e21:	83 ec 0c             	sub    $0xc,%esp
f0100e24:	ff 75 08             	pushl  0x8(%ebp)
f0100e27:	e8 c3 fb ff ff       	call   f01009ef <cputchar>
f0100e2c:	83 c4 10             	add    $0x10,%esp
	*cnt++;
f0100e2f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e32:	83 c0 04             	add    $0x4,%eax
f0100e35:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f0100e38:	90                   	nop
f0100e39:	c9                   	leave  
f0100e3a:	c3                   	ret    

f0100e3b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100e3b:	55                   	push   %ebp
f0100e3c:	89 e5                	mov    %esp,%ebp
f0100e3e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100e41:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100e48:	ff 75 0c             	pushl  0xc(%ebp)
f0100e4b:	ff 75 08             	pushl  0x8(%ebp)
f0100e4e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100e51:	50                   	push   %eax
f0100e52:	68 1b 0e 10 f0       	push   $0xf0100e1b
f0100e57:	e8 07 06 00 00       	call   f0101463 <vprintfmt>
f0100e5c:	83 c4 10             	add    $0x10,%esp
	return cnt;
f0100e5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100e62:	c9                   	leave  
f0100e63:	c3                   	ret    

f0100e64 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100e6a:	8d 45 0c             	lea    0xc(%ebp),%eax
f0100e6d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
f0100e70:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100e73:	83 ec 08             	sub    $0x8,%esp
f0100e76:	50                   	push   %eax
f0100e77:	ff 75 08             	pushl  0x8(%ebp)
f0100e7a:	e8 bc ff ff ff       	call   f0100e3b <vcprintf>
f0100e7f:	83 c4 10             	add    $0x10,%esp
f0100e82:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
f0100e85:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100e88:	c9                   	leave  
f0100e89:	c3                   	ret    

f0100e8a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100e8a:	55                   	push   %ebp
f0100e8b:	89 e5                	mov    %esp,%ebp
f0100e8d:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f0100e90:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e93:	8b 00                	mov    (%eax),%eax
f0100e95:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100e98:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e9b:	8b 00                	mov    (%eax),%eax
f0100e9d:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100ea0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	while (l <= r) {
f0100ea7:	e9 d2 00 00 00       	jmp    f0100f7e <stab_binsearch+0xf4>
		int true_m = (l + r) / 2, m = true_m;
f0100eac:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100eaf:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100eb2:	01 d0                	add    %edx,%eax
f0100eb4:	89 c2                	mov    %eax,%edx
f0100eb6:	c1 ea 1f             	shr    $0x1f,%edx
f0100eb9:	01 d0                	add    %edx,%eax
f0100ebb:	d1 f8                	sar    %eax
f0100ebd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100ec0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100ec3:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ec6:	eb 04                	jmp    f0100ecc <stab_binsearch+0x42>
			m--;
f0100ec8:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ecc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ecf:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100ed2:	7c 1f                	jl     f0100ef3 <stab_binsearch+0x69>
f0100ed4:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100ed7:	89 d0                	mov    %edx,%eax
f0100ed9:	01 c0                	add    %eax,%eax
f0100edb:	01 d0                	add    %edx,%eax
f0100edd:	c1 e0 02             	shl    $0x2,%eax
f0100ee0:	89 c2                	mov    %eax,%edx
f0100ee2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ee5:	01 d0                	add    %edx,%eax
f0100ee7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0100eeb:	0f b6 c0             	movzbl %al,%eax
f0100eee:	3b 45 14             	cmp    0x14(%ebp),%eax
f0100ef1:	75 d5                	jne    f0100ec8 <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0100ef3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ef6:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100ef9:	7d 0b                	jge    f0100f06 <stab_binsearch+0x7c>
			l = true_m + 1;
f0100efb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100efe:	83 c0 01             	add    $0x1,%eax
f0100f01:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f0100f04:	eb 78                	jmp    f0100f7e <stab_binsearch+0xf4>
		}

		// actual binary search
		any_matches = 1;
f0100f06:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f0100f0d:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100f10:	89 d0                	mov    %edx,%eax
f0100f12:	01 c0                	add    %eax,%eax
f0100f14:	01 d0                	add    %edx,%eax
f0100f16:	c1 e0 02             	shl    $0x2,%eax
f0100f19:	89 c2                	mov    %eax,%edx
f0100f1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f1e:	01 d0                	add    %edx,%eax
f0100f20:	8b 40 08             	mov    0x8(%eax),%eax
f0100f23:	3b 45 18             	cmp    0x18(%ebp),%eax
f0100f26:	73 13                	jae    f0100f3b <stab_binsearch+0xb1>
			*region_left = m;
f0100f28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f2b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100f2e:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f0100f30:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f33:	83 c0 01             	add    $0x1,%eax
f0100f36:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100f39:	eb 43                	jmp    f0100f7e <stab_binsearch+0xf4>
		} else if (stabs[m].n_value > addr) {
f0100f3b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100f3e:	89 d0                	mov    %edx,%eax
f0100f40:	01 c0                	add    %eax,%eax
f0100f42:	01 d0                	add    %edx,%eax
f0100f44:	c1 e0 02             	shl    $0x2,%eax
f0100f47:	89 c2                	mov    %eax,%edx
f0100f49:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f4c:	01 d0                	add    %edx,%eax
f0100f4e:	8b 40 08             	mov    0x8(%eax),%eax
f0100f51:	3b 45 18             	cmp    0x18(%ebp),%eax
f0100f54:	76 16                	jbe    f0100f6c <stab_binsearch+0xe2>
			*region_right = m - 1;
f0100f56:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f59:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100f5c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f5f:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0100f61:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f64:	83 e8 01             	sub    $0x1,%eax
f0100f67:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100f6a:	eb 12                	jmp    f0100f7e <stab_binsearch+0xf4>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100f6c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f6f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100f72:	89 10                	mov    %edx,(%eax)
			l = m;
f0100f74:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f77:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0100f7a:	83 45 18 01          	addl   $0x1,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100f7e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100f81:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0100f84:	0f 8e 22 ff ff ff    	jle    f0100eac <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100f8a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100f8e:	75 0f                	jne    f0100f9f <stab_binsearch+0x115>
		*region_right = *region_left - 1;
f0100f90:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f93:	8b 00                	mov    (%eax),%eax
f0100f95:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100f98:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f9b:	89 10                	mov    %edx,(%eax)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100f9d:	eb 3f                	jmp    f0100fde <stab_binsearch+0x154>

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100f9f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fa2:	8b 00                	mov    (%eax),%eax
f0100fa4:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100fa7:	eb 04                	jmp    f0100fad <stab_binsearch+0x123>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100fa9:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100fad:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb0:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100fb2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100fb5:	7d 1f                	jge    f0100fd6 <stab_binsearch+0x14c>
		     l > *region_left && stabs[l].n_type != type;
f0100fb7:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100fba:	89 d0                	mov    %edx,%eax
f0100fbc:	01 c0                	add    %eax,%eax
f0100fbe:	01 d0                	add    %edx,%eax
f0100fc0:	c1 e0 02             	shl    $0x2,%eax
f0100fc3:	89 c2                	mov    %eax,%edx
f0100fc5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fc8:	01 d0                	add    %edx,%eax
f0100fca:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0100fce:	0f b6 c0             	movzbl %al,%eax
f0100fd1:	3b 45 14             	cmp    0x14(%ebp),%eax
f0100fd4:	75 d3                	jne    f0100fa9 <stab_binsearch+0x11f>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100fd6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fd9:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100fdc:	89 10                	mov    %edx,(%eax)
	}
}
f0100fde:	90                   	nop
f0100fdf:	c9                   	leave  
f0100fe0:	c3                   	ret    

f0100fe1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100fe1:	55                   	push   %ebp
f0100fe2:	89 e5                	mov    %esp,%ebp
f0100fe4:	83 ec 38             	sub    $0x38,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100fe7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fea:	c7 00 01 25 10 f0    	movl   $0xf0102501,(%eax)
	info->eip_line = 0;
f0100ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ff3:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f0100ffa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ffd:	c7 40 08 01 25 10 f0 	movl   $0xf0102501,0x8(%eax)
	info->eip_fn_namelen = 9;
f0101004:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101007:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f010100e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101011:	8b 55 08             	mov    0x8(%ebp),%edx
f0101014:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f0101017:	8b 45 0c             	mov    0xc(%ebp),%eax
f010101a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101021:	81 7d 08 ff ff 7f ef 	cmpl   $0xef7fffff,0x8(%ebp)
f0101028:	76 26                	jbe    f0101050 <debuginfo_eip+0x6f>
		stabs = __STAB_BEGIN__;
f010102a:	c7 45 f4 70 27 10 f0 	movl   $0xf0102770,-0xc(%ebp)
		stab_end = __STAB_END__;
f0101031:	c7 45 f0 d8 6a 10 f0 	movl   $0xf0106ad8,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0101038:	c7 45 ec d9 6a 10 f0 	movl   $0xf0106ad9,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f010103f:	c7 45 e8 d2 84 10 f0 	movl   $0xf01084d2,-0x18(%ebp)
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101046:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101049:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f010104c:	76 23                	jbe    f0101071 <debuginfo_eip+0x90>
f010104e:	eb 14                	jmp    f0101064 <debuginfo_eip+0x83>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101050:	83 ec 04             	sub    $0x4,%esp
f0101053:	68 0b 25 10 f0       	push   $0xf010250b
f0101058:	6a 7f                	push   $0x7f
f010105a:	68 18 25 10 f0       	push   $0xf0102518
f010105f:	e8 f0 f0 ff ff       	call   f0100154 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101064:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101067:	83 e8 01             	sub    $0x1,%eax
f010106a:	0f b6 00             	movzbl (%eax),%eax
f010106d:	84 c0                	test   %al,%al
f010106f:	74 0a                	je     f010107b <debuginfo_eip+0x9a>
		return -1;
f0101071:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101076:	e9 97 02 00 00       	jmp    f0101312 <debuginfo_eip+0x331>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010107b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101082:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101085:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101088:	29 c2                	sub    %eax,%edx
f010108a:	89 d0                	mov    %edx,%eax
f010108c:	c1 f8 02             	sar    $0x2,%eax
f010108f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101095:	83 e8 01             	sub    $0x1,%eax
f0101098:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010109b:	83 ec 0c             	sub    $0xc,%esp
f010109e:	ff 75 08             	pushl  0x8(%ebp)
f01010a1:	6a 64                	push   $0x64
f01010a3:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01010a6:	50                   	push   %eax
f01010a7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01010aa:	50                   	push   %eax
f01010ab:	ff 75 f4             	pushl  -0xc(%ebp)
f01010ae:	e8 d7 fd ff ff       	call   f0100e8a <stab_binsearch>
f01010b3:	83 c4 20             	add    $0x20,%esp
	if (lfile == 0)
f01010b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010b9:	85 c0                	test   %eax,%eax
f01010bb:	75 0a                	jne    f01010c7 <debuginfo_eip+0xe6>
		return -1;
f01010bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010c2:	e9 4b 02 00 00       	jmp    f0101312 <debuginfo_eip+0x331>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01010c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010ca:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01010cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01010d3:	83 ec 0c             	sub    $0xc,%esp
f01010d6:	ff 75 08             	pushl  0x8(%ebp)
f01010d9:	6a 24                	push   $0x24
f01010db:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01010de:	50                   	push   %eax
f01010df:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01010e2:	50                   	push   %eax
f01010e3:	ff 75 f4             	pushl  -0xc(%ebp)
f01010e6:	e8 9f fd ff ff       	call   f0100e8a <stab_binsearch>
f01010eb:	83 c4 20             	add    $0x20,%esp

	if (lfun <= rfun) {
f01010ee:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010f4:	39 c2                	cmp    %eax,%edx
f01010f6:	7f 7c                	jg     f0101174 <debuginfo_eip+0x193>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01010f8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010fb:	89 c2                	mov    %eax,%edx
f01010fd:	89 d0                	mov    %edx,%eax
f01010ff:	01 c0                	add    %eax,%eax
f0101101:	01 d0                	add    %edx,%eax
f0101103:	c1 e0 02             	shl    $0x2,%eax
f0101106:	89 c2                	mov    %eax,%edx
f0101108:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010110b:	01 d0                	add    %edx,%eax
f010110d:	8b 00                	mov    (%eax),%eax
f010110f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0101112:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101115:	29 d1                	sub    %edx,%ecx
f0101117:	89 ca                	mov    %ecx,%edx
f0101119:	39 d0                	cmp    %edx,%eax
f010111b:	73 22                	jae    f010113f <debuginfo_eip+0x15e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010111d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101120:	89 c2                	mov    %eax,%edx
f0101122:	89 d0                	mov    %edx,%eax
f0101124:	01 c0                	add    %eax,%eax
f0101126:	01 d0                	add    %edx,%eax
f0101128:	c1 e0 02             	shl    $0x2,%eax
f010112b:	89 c2                	mov    %eax,%edx
f010112d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101130:	01 d0                	add    %edx,%eax
f0101132:	8b 10                	mov    (%eax),%edx
f0101134:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101137:	01 c2                	add    %eax,%edx
f0101139:	8b 45 0c             	mov    0xc(%ebp),%eax
f010113c:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = stabs[lfun].n_value;
f010113f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101142:	89 c2                	mov    %eax,%edx
f0101144:	89 d0                	mov    %edx,%eax
f0101146:	01 c0                	add    %eax,%eax
f0101148:	01 d0                	add    %edx,%eax
f010114a:	c1 e0 02             	shl    $0x2,%eax
f010114d:	89 c2                	mov    %eax,%edx
f010114f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101152:	01 d0                	add    %edx,%eax
f0101154:	8b 50 08             	mov    0x8(%eax),%edx
f0101157:	8b 45 0c             	mov    0xc(%ebp),%eax
f010115a:	89 50 10             	mov    %edx,0x10(%eax)
		addr -= info->eip_fn_addr;
f010115d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101160:	8b 40 10             	mov    0x10(%eax),%eax
f0101163:	29 45 08             	sub    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0101166:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101169:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010116c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010116f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101172:	eb 15                	jmp    f0101189 <debuginfo_eip+0x1a8>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101174:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101177:	8b 55 08             	mov    0x8(%ebp),%edx
f010117a:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f010117d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101180:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101183:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101186:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101189:	8b 45 0c             	mov    0xc(%ebp),%eax
f010118c:	8b 40 08             	mov    0x8(%eax),%eax
f010118f:	83 ec 08             	sub    $0x8,%esp
f0101192:	6a 3a                	push   $0x3a
f0101194:	50                   	push   %eax
f0101195:	e8 55 0a 00 00       	call   f0101bef <strfind>
f010119a:	83 c4 10             	add    $0x10,%esp
f010119d:	89 c2                	mov    %eax,%edx
f010119f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011a2:	8b 40 08             	mov    0x8(%eax),%eax
f01011a5:	29 c2                	sub    %eax,%edx
f01011a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011aa:	89 50 0c             	mov    %edx,0xc(%eax)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01011ad:	83 ec 0c             	sub    $0xc,%esp
f01011b0:	ff 75 08             	pushl  0x8(%ebp)
f01011b3:	6a 44                	push   $0x44
f01011b5:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01011b8:	50                   	push   %eax
f01011b9:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01011bc:	50                   	push   %eax
f01011bd:	ff 75 f4             	pushl  -0xc(%ebp)
f01011c0:	e8 c5 fc ff ff       	call   f0100e8a <stab_binsearch>
f01011c5:	83 c4 20             	add    $0x20,%esp
	
	if (lline > rline)
f01011c8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01011cb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011ce:	39 c2                	cmp    %eax,%edx
f01011d0:	7e 0a                	jle    f01011dc <debuginfo_eip+0x1fb>
		return -1;
f01011d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01011d7:	e9 36 01 00 00       	jmp    f0101312 <debuginfo_eip+0x331>
	else
		info->eip_line = stabs[lline].n_desc;
f01011dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011df:	89 c2                	mov    %eax,%edx
f01011e1:	89 d0                	mov    %edx,%eax
f01011e3:	01 c0                	add    %eax,%eax
f01011e5:	01 d0                	add    %edx,%eax
f01011e7:	c1 e0 02             	shl    $0x2,%eax
f01011ea:	89 c2                	mov    %eax,%edx
f01011ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ef:	01 d0                	add    %edx,%eax
f01011f1:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f01011f5:	0f b7 d0             	movzwl %ax,%edx
f01011f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011fb:	89 50 04             	mov    %edx,0x4(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01011fe:	eb 09                	jmp    f0101209 <debuginfo_eip+0x228>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101200:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101203:	83 e8 01             	sub    $0x1,%eax
f0101206:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101209:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010120c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010120f:	39 c2                	cmp    %eax,%edx
f0101211:	7c 56                	jl     f0101269 <debuginfo_eip+0x288>
	       && stabs[lline].n_type != N_SOL
f0101213:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101216:	89 c2                	mov    %eax,%edx
f0101218:	89 d0                	mov    %edx,%eax
f010121a:	01 c0                	add    %eax,%eax
f010121c:	01 d0                	add    %edx,%eax
f010121e:	c1 e0 02             	shl    $0x2,%eax
f0101221:	89 c2                	mov    %eax,%edx
f0101223:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101226:	01 d0                	add    %edx,%eax
f0101228:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f010122c:	3c 84                	cmp    $0x84,%al
f010122e:	74 39                	je     f0101269 <debuginfo_eip+0x288>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101230:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101233:	89 c2                	mov    %eax,%edx
f0101235:	89 d0                	mov    %edx,%eax
f0101237:	01 c0                	add    %eax,%eax
f0101239:	01 d0                	add    %edx,%eax
f010123b:	c1 e0 02             	shl    $0x2,%eax
f010123e:	89 c2                	mov    %eax,%edx
f0101240:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101243:	01 d0                	add    %edx,%eax
f0101245:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0101249:	3c 64                	cmp    $0x64,%al
f010124b:	75 b3                	jne    f0101200 <debuginfo_eip+0x21f>
f010124d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101250:	89 c2                	mov    %eax,%edx
f0101252:	89 d0                	mov    %edx,%eax
f0101254:	01 c0                	add    %eax,%eax
f0101256:	01 d0                	add    %edx,%eax
f0101258:	c1 e0 02             	shl    $0x2,%eax
f010125b:	89 c2                	mov    %eax,%edx
f010125d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101260:	01 d0                	add    %edx,%eax
f0101262:	8b 40 08             	mov    0x8(%eax),%eax
f0101265:	85 c0                	test   %eax,%eax
f0101267:	74 97                	je     f0101200 <debuginfo_eip+0x21f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101269:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010126c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010126f:	39 c2                	cmp    %eax,%edx
f0101271:	7c 46                	jl     f01012b9 <debuginfo_eip+0x2d8>
f0101273:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101276:	89 c2                	mov    %eax,%edx
f0101278:	89 d0                	mov    %edx,%eax
f010127a:	01 c0                	add    %eax,%eax
f010127c:	01 d0                	add    %edx,%eax
f010127e:	c1 e0 02             	shl    $0x2,%eax
f0101281:	89 c2                	mov    %eax,%edx
f0101283:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101286:	01 d0                	add    %edx,%eax
f0101288:	8b 00                	mov    (%eax),%eax
f010128a:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010128d:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101290:	29 d1                	sub    %edx,%ecx
f0101292:	89 ca                	mov    %ecx,%edx
f0101294:	39 d0                	cmp    %edx,%eax
f0101296:	73 21                	jae    f01012b9 <debuginfo_eip+0x2d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101298:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129b:	89 c2                	mov    %eax,%edx
f010129d:	89 d0                	mov    %edx,%eax
f010129f:	01 c0                	add    %eax,%eax
f01012a1:	01 d0                	add    %edx,%eax
f01012a3:	c1 e0 02             	shl    $0x2,%eax
f01012a6:	89 c2                	mov    %eax,%edx
f01012a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012ab:	01 d0                	add    %edx,%eax
f01012ad:	8b 10                	mov    (%eax),%edx
f01012af:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012b2:	01 c2                	add    %eax,%edx
f01012b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012b7:	89 10                	mov    %edx,(%eax)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01012b9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01012bc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01012bf:	39 c2                	cmp    %eax,%edx
f01012c1:	7d 4a                	jge    f010130d <debuginfo_eip+0x32c>
		for (lline = lfun + 1;
f01012c3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01012c6:	83 c0 01             	add    $0x1,%eax
f01012c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012cc:	eb 18                	jmp    f01012e6 <debuginfo_eip+0x305>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01012ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012d1:	8b 40 14             	mov    0x14(%eax),%eax
f01012d4:	8d 50 01             	lea    0x1(%eax),%edx
f01012d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012da:	89 50 14             	mov    %edx,0x14(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01012dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012e0:	83 c0 01             	add    $0x1,%eax
f01012e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01012e6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01012e9:	8b 45 d8             	mov    -0x28(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01012ec:	39 c2                	cmp    %eax,%edx
f01012ee:	7d 1d                	jge    f010130d <debuginfo_eip+0x32c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01012f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012f3:	89 c2                	mov    %eax,%edx
f01012f5:	89 d0                	mov    %edx,%eax
f01012f7:	01 c0                	add    %eax,%eax
f01012f9:	01 d0                	add    %edx,%eax
f01012fb:	c1 e0 02             	shl    $0x2,%eax
f01012fe:	89 c2                	mov    %eax,%edx
f0101300:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101303:	01 d0                	add    %edx,%eax
f0101305:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0101309:	3c a0                	cmp    $0xa0,%al
f010130b:	74 c1                	je     f01012ce <debuginfo_eip+0x2ed>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010130d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101312:	c9                   	leave  
f0101313:	c3                   	ret    

f0101314 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101314:	55                   	push   %ebp
f0101315:	89 e5                	mov    %esp,%ebp
f0101317:	53                   	push   %ebx
f0101318:	83 ec 14             	sub    $0x14,%esp
f010131b:	8b 45 10             	mov    0x10(%ebp),%eax
f010131e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101321:	8b 45 14             	mov    0x14(%ebp),%eax
f0101324:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101327:	8b 45 18             	mov    0x18(%ebp),%eax
f010132a:	ba 00 00 00 00       	mov    $0x0,%edx
f010132f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0101332:	77 55                	ja     f0101389 <printnum+0x75>
f0101334:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0101337:	72 05                	jb     f010133e <printnum+0x2a>
f0101339:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f010133c:	77 4b                	ja     f0101389 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010133e:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0101341:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101344:	8b 45 18             	mov    0x18(%ebp),%eax
f0101347:	ba 00 00 00 00       	mov    $0x0,%edx
f010134c:	52                   	push   %edx
f010134d:	50                   	push   %eax
f010134e:	ff 75 f4             	pushl  -0xc(%ebp)
f0101351:	ff 75 f0             	pushl  -0x10(%ebp)
f0101354:	e8 17 0c 00 00       	call   f0101f70 <__udivdi3>
f0101359:	83 c4 10             	add    $0x10,%esp
f010135c:	83 ec 04             	sub    $0x4,%esp
f010135f:	ff 75 20             	pushl  0x20(%ebp)
f0101362:	53                   	push   %ebx
f0101363:	ff 75 18             	pushl  0x18(%ebp)
f0101366:	52                   	push   %edx
f0101367:	50                   	push   %eax
f0101368:	ff 75 0c             	pushl  0xc(%ebp)
f010136b:	ff 75 08             	pushl  0x8(%ebp)
f010136e:	e8 a1 ff ff ff       	call   f0101314 <printnum>
f0101373:	83 c4 20             	add    $0x20,%esp
f0101376:	eb 1b                	jmp    f0101393 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101378:	83 ec 08             	sub    $0x8,%esp
f010137b:	ff 75 0c             	pushl  0xc(%ebp)
f010137e:	ff 75 20             	pushl  0x20(%ebp)
f0101381:	8b 45 08             	mov    0x8(%ebp),%eax
f0101384:	ff d0                	call   *%eax
f0101386:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101389:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
f010138d:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f0101391:	7f e5                	jg     f0101378 <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101393:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0101396:	bb 00 00 00 00       	mov    $0x0,%ebx
f010139b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010139e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01013a1:	53                   	push   %ebx
f01013a2:	51                   	push   %ecx
f01013a3:	52                   	push   %edx
f01013a4:	50                   	push   %eax
f01013a5:	e8 f6 0c 00 00       	call   f01020a0 <__umoddi3>
f01013aa:	83 c4 10             	add    $0x10,%esp
f01013ad:	05 e0 25 10 f0       	add    $0xf01025e0,%eax
f01013b2:	0f b6 00             	movzbl (%eax),%eax
f01013b5:	0f be c0             	movsbl %al,%eax
f01013b8:	83 ec 08             	sub    $0x8,%esp
f01013bb:	ff 75 0c             	pushl  0xc(%ebp)
f01013be:	50                   	push   %eax
f01013bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c2:	ff d0                	call   *%eax
f01013c4:	83 c4 10             	add    $0x10,%esp
}
f01013c7:	90                   	nop
f01013c8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013cb:	c9                   	leave  
f01013cc:	c3                   	ret    

f01013cd <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01013cd:	55                   	push   %ebp
f01013ce:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01013d0:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f01013d4:	7e 14                	jle    f01013ea <getuint+0x1d>
		return va_arg(*ap, unsigned long long);
f01013d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d9:	8b 00                	mov    (%eax),%eax
f01013db:	8d 48 08             	lea    0x8(%eax),%ecx
f01013de:	8b 55 08             	mov    0x8(%ebp),%edx
f01013e1:	89 0a                	mov    %ecx,(%edx)
f01013e3:	8b 50 04             	mov    0x4(%eax),%edx
f01013e6:	8b 00                	mov    (%eax),%eax
f01013e8:	eb 30                	jmp    f010141a <getuint+0x4d>
	else if (lflag)
f01013ea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01013ee:	74 16                	je     f0101406 <getuint+0x39>
		return va_arg(*ap, unsigned long);
f01013f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f3:	8b 00                	mov    (%eax),%eax
f01013f5:	8d 48 04             	lea    0x4(%eax),%ecx
f01013f8:	8b 55 08             	mov    0x8(%ebp),%edx
f01013fb:	89 0a                	mov    %ecx,(%edx)
f01013fd:	8b 00                	mov    (%eax),%eax
f01013ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101404:	eb 14                	jmp    f010141a <getuint+0x4d>
	else
		return va_arg(*ap, unsigned int);
f0101406:	8b 45 08             	mov    0x8(%ebp),%eax
f0101409:	8b 00                	mov    (%eax),%eax
f010140b:	8d 48 04             	lea    0x4(%eax),%ecx
f010140e:	8b 55 08             	mov    0x8(%ebp),%edx
f0101411:	89 0a                	mov    %ecx,(%edx)
f0101413:	8b 00                	mov    (%eax),%eax
f0101415:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010141a:	5d                   	pop    %ebp
f010141b:	c3                   	ret    

f010141c <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f010141c:	55                   	push   %ebp
f010141d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010141f:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0101423:	7e 14                	jle    f0101439 <getint+0x1d>
		return va_arg(*ap, long long);
f0101425:	8b 45 08             	mov    0x8(%ebp),%eax
f0101428:	8b 00                	mov    (%eax),%eax
f010142a:	8d 48 08             	lea    0x8(%eax),%ecx
f010142d:	8b 55 08             	mov    0x8(%ebp),%edx
f0101430:	89 0a                	mov    %ecx,(%edx)
f0101432:	8b 50 04             	mov    0x4(%eax),%edx
f0101435:	8b 00                	mov    (%eax),%eax
f0101437:	eb 28                	jmp    f0101461 <getint+0x45>
	else if (lflag)
f0101439:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010143d:	74 12                	je     f0101451 <getint+0x35>
		return va_arg(*ap, long);
f010143f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101442:	8b 00                	mov    (%eax),%eax
f0101444:	8d 48 04             	lea    0x4(%eax),%ecx
f0101447:	8b 55 08             	mov    0x8(%ebp),%edx
f010144a:	89 0a                	mov    %ecx,(%edx)
f010144c:	8b 00                	mov    (%eax),%eax
f010144e:	99                   	cltd   
f010144f:	eb 10                	jmp    f0101461 <getint+0x45>
	else
		return va_arg(*ap, int);
f0101451:	8b 45 08             	mov    0x8(%ebp),%eax
f0101454:	8b 00                	mov    (%eax),%eax
f0101456:	8d 48 04             	lea    0x4(%eax),%ecx
f0101459:	8b 55 08             	mov    0x8(%ebp),%edx
f010145c:	89 0a                	mov    %ecx,(%edx)
f010145e:	8b 00                	mov    (%eax),%eax
f0101460:	99                   	cltd   
}
f0101461:	5d                   	pop    %ebp
f0101462:	c3                   	ret    

f0101463 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101463:	55                   	push   %ebp
f0101464:	89 e5                	mov    %esp,%ebp
f0101466:	56                   	push   %esi
f0101467:	53                   	push   %ebx
f0101468:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010146b:	eb 17                	jmp    f0101484 <vprintfmt+0x21>
			if (ch == '\0')
f010146d:	85 db                	test   %ebx,%ebx
f010146f:	0f 84 89 03 00 00    	je     f01017fe <vprintfmt+0x39b>
				return;
			putch(ch, putdat);
f0101475:	83 ec 08             	sub    $0x8,%esp
f0101478:	ff 75 0c             	pushl  0xc(%ebp)
f010147b:	53                   	push   %ebx
f010147c:	8b 45 08             	mov    0x8(%ebp),%eax
f010147f:	ff d0                	call   *%eax
f0101481:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101484:	8b 45 10             	mov    0x10(%ebp),%eax
f0101487:	8d 50 01             	lea    0x1(%eax),%edx
f010148a:	89 55 10             	mov    %edx,0x10(%ebp)
f010148d:	0f b6 00             	movzbl (%eax),%eax
f0101490:	0f b6 d8             	movzbl %al,%ebx
f0101493:	83 fb 25             	cmp    $0x25,%ebx
f0101496:	75 d5                	jne    f010146d <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0101498:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f010149c:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f01014a3:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01014aa:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f01014b1:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014b8:	8b 45 10             	mov    0x10(%ebp),%eax
f01014bb:	8d 50 01             	lea    0x1(%eax),%edx
f01014be:	89 55 10             	mov    %edx,0x10(%ebp)
f01014c1:	0f b6 00             	movzbl (%eax),%eax
f01014c4:	0f b6 d8             	movzbl %al,%ebx
f01014c7:	8d 43 dd             	lea    -0x23(%ebx),%eax
f01014ca:	83 f8 55             	cmp    $0x55,%eax
f01014cd:	0f 87 fe 02 00 00    	ja     f01017d1 <vprintfmt+0x36e>
f01014d3:	8b 04 85 04 26 10 f0 	mov    -0xfefd9fc(,%eax,4),%eax
f01014da:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f01014dc:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f01014e0:	eb d6                	jmp    f01014b8 <vprintfmt+0x55>

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01014e2:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f01014e6:	eb d0                	jmp    f01014b8 <vprintfmt+0x55>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01014e8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f01014ef:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01014f2:	89 d0                	mov    %edx,%eax
f01014f4:	c1 e0 02             	shl    $0x2,%eax
f01014f7:	01 d0                	add    %edx,%eax
f01014f9:	01 c0                	add    %eax,%eax
f01014fb:	01 d8                	add    %ebx,%eax
f01014fd:	83 e8 30             	sub    $0x30,%eax
f0101500:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f0101503:	8b 45 10             	mov    0x10(%ebp),%eax
f0101506:	0f b6 00             	movzbl (%eax),%eax
f0101509:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f010150c:	83 fb 2f             	cmp    $0x2f,%ebx
f010150f:	7e 39                	jle    f010154a <vprintfmt+0xe7>
f0101511:	83 fb 39             	cmp    $0x39,%ebx
f0101514:	7f 34                	jg     f010154a <vprintfmt+0xe7>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101516:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010151a:	eb d3                	jmp    f01014ef <vprintfmt+0x8c>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010151c:	8b 45 14             	mov    0x14(%ebp),%eax
f010151f:	8d 50 04             	lea    0x4(%eax),%edx
f0101522:	89 55 14             	mov    %edx,0x14(%ebp)
f0101525:	8b 00                	mov    (%eax),%eax
f0101527:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f010152a:	eb 1f                	jmp    f010154b <vprintfmt+0xe8>

		case '.':
			if (width < 0)
f010152c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101530:	79 86                	jns    f01014b8 <vprintfmt+0x55>
				width = 0;
f0101532:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f0101539:	e9 7a ff ff ff       	jmp    f01014b8 <vprintfmt+0x55>

		case '#':
			altflag = 1;
f010153e:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101545:	e9 6e ff ff ff       	jmp    f01014b8 <vprintfmt+0x55>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
f010154a:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010154b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010154f:	0f 89 63 ff ff ff    	jns    f01014b8 <vprintfmt+0x55>
				width = precision, precision = -1;
f0101555:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101558:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010155b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f0101562:	e9 51 ff ff ff       	jmp    f01014b8 <vprintfmt+0x55>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101567:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
			goto reswitch;
f010156b:	e9 48 ff ff ff       	jmp    f01014b8 <vprintfmt+0x55>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101570:	8b 45 14             	mov    0x14(%ebp),%eax
f0101573:	8d 50 04             	lea    0x4(%eax),%edx
f0101576:	89 55 14             	mov    %edx,0x14(%ebp)
f0101579:	8b 00                	mov    (%eax),%eax
f010157b:	83 ec 08             	sub    $0x8,%esp
f010157e:	ff 75 0c             	pushl  0xc(%ebp)
f0101581:	50                   	push   %eax
f0101582:	8b 45 08             	mov    0x8(%ebp),%eax
f0101585:	ff d0                	call   *%eax
f0101587:	83 c4 10             	add    $0x10,%esp
			break;
f010158a:	e9 6a 02 00 00       	jmp    f01017f9 <vprintfmt+0x396>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010158f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101592:	8d 50 04             	lea    0x4(%eax),%edx
f0101595:	89 55 14             	mov    %edx,0x14(%ebp)
f0101598:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f010159a:	85 db                	test   %ebx,%ebx
f010159c:	79 02                	jns    f01015a0 <vprintfmt+0x13d>
				err = -err;
f010159e:	f7 db                	neg    %ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01015a0:	83 fb 07             	cmp    $0x7,%ebx
f01015a3:	7f 0b                	jg     f01015b0 <vprintfmt+0x14d>
f01015a5:	8b 34 9d c0 25 10 f0 	mov    -0xfefda40(,%ebx,4),%esi
f01015ac:	85 f6                	test   %esi,%esi
f01015ae:	75 19                	jne    f01015c9 <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f01015b0:	53                   	push   %ebx
f01015b1:	68 f1 25 10 f0       	push   $0xf01025f1
f01015b6:	ff 75 0c             	pushl  0xc(%ebp)
f01015b9:	ff 75 08             	pushl  0x8(%ebp)
f01015bc:	e8 45 02 00 00       	call   f0101806 <printfmt>
f01015c1:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
f01015c4:	e9 30 02 00 00       	jmp    f01017f9 <vprintfmt+0x396>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f01015c9:	56                   	push   %esi
f01015ca:	68 fa 25 10 f0       	push   $0xf01025fa
f01015cf:	ff 75 0c             	pushl  0xc(%ebp)
f01015d2:	ff 75 08             	pushl  0x8(%ebp)
f01015d5:	e8 2c 02 00 00       	call   f0101806 <printfmt>
f01015da:	83 c4 10             	add    $0x10,%esp
			break;
f01015dd:	e9 17 02 00 00       	jmp    f01017f9 <vprintfmt+0x396>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01015e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01015e5:	8d 50 04             	lea    0x4(%eax),%edx
f01015e8:	89 55 14             	mov    %edx,0x14(%ebp)
f01015eb:	8b 30                	mov    (%eax),%esi
f01015ed:	85 f6                	test   %esi,%esi
f01015ef:	75 05                	jne    f01015f6 <vprintfmt+0x193>
				p = "(null)";
f01015f1:	be fd 25 10 f0       	mov    $0xf01025fd,%esi
			if (width > 0 && padc != '-')
f01015f6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015fa:	7e 6f                	jle    f010166b <vprintfmt+0x208>
f01015fc:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f0101600:	74 69                	je     f010166b <vprintfmt+0x208>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101602:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101605:	83 ec 08             	sub    $0x8,%esp
f0101608:	50                   	push   %eax
f0101609:	56                   	push   %esi
f010160a:	e8 f5 03 00 00       	call   f0101a04 <strnlen>
f010160f:	83 c4 10             	add    $0x10,%esp
f0101612:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0101615:	eb 17                	jmp    f010162e <vprintfmt+0x1cb>
					putch(padc, putdat);
f0101617:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f010161b:	83 ec 08             	sub    $0x8,%esp
f010161e:	ff 75 0c             	pushl  0xc(%ebp)
f0101621:	50                   	push   %eax
f0101622:	8b 45 08             	mov    0x8(%ebp),%eax
f0101625:	ff d0                	call   *%eax
f0101627:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010162a:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010162e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101632:	7f e3                	jg     f0101617 <vprintfmt+0x1b4>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101634:	eb 35                	jmp    f010166b <vprintfmt+0x208>
				if (altflag && (ch < ' ' || ch > '~'))
f0101636:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010163a:	74 1c                	je     f0101658 <vprintfmt+0x1f5>
f010163c:	83 fb 1f             	cmp    $0x1f,%ebx
f010163f:	7e 05                	jle    f0101646 <vprintfmt+0x1e3>
f0101641:	83 fb 7e             	cmp    $0x7e,%ebx
f0101644:	7e 12                	jle    f0101658 <vprintfmt+0x1f5>
					putch('?', putdat);
f0101646:	83 ec 08             	sub    $0x8,%esp
f0101649:	ff 75 0c             	pushl  0xc(%ebp)
f010164c:	6a 3f                	push   $0x3f
f010164e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101651:	ff d0                	call   *%eax
f0101653:	83 c4 10             	add    $0x10,%esp
f0101656:	eb 0f                	jmp    f0101667 <vprintfmt+0x204>
				else
					putch(ch, putdat);
f0101658:	83 ec 08             	sub    $0x8,%esp
f010165b:	ff 75 0c             	pushl  0xc(%ebp)
f010165e:	53                   	push   %ebx
f010165f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101662:	ff d0                	call   *%eax
f0101664:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101667:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010166b:	89 f0                	mov    %esi,%eax
f010166d:	8d 70 01             	lea    0x1(%eax),%esi
f0101670:	0f b6 00             	movzbl (%eax),%eax
f0101673:	0f be d8             	movsbl %al,%ebx
f0101676:	85 db                	test   %ebx,%ebx
f0101678:	74 26                	je     f01016a0 <vprintfmt+0x23d>
f010167a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010167e:	78 b6                	js     f0101636 <vprintfmt+0x1d3>
f0101680:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101684:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101688:	79 ac                	jns    f0101636 <vprintfmt+0x1d3>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010168a:	eb 14                	jmp    f01016a0 <vprintfmt+0x23d>
				putch(' ', putdat);
f010168c:	83 ec 08             	sub    $0x8,%esp
f010168f:	ff 75 0c             	pushl  0xc(%ebp)
f0101692:	6a 20                	push   $0x20
f0101694:	8b 45 08             	mov    0x8(%ebp),%eax
f0101697:	ff d0                	call   *%eax
f0101699:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010169c:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01016a0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01016a4:	7f e6                	jg     f010168c <vprintfmt+0x229>
				putch(' ', putdat);
			break;
f01016a6:	e9 4e 01 00 00       	jmp    f01017f9 <vprintfmt+0x396>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01016ab:	83 ec 08             	sub    $0x8,%esp
f01016ae:	ff 75 e8             	pushl  -0x18(%ebp)
f01016b1:	8d 45 14             	lea    0x14(%ebp),%eax
f01016b4:	50                   	push   %eax
f01016b5:	e8 62 fd ff ff       	call   f010141c <getint>
f01016ba:	83 c4 10             	add    $0x10,%esp
f01016bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01016c0:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f01016c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01016c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01016c9:	85 d2                	test   %edx,%edx
f01016cb:	79 23                	jns    f01016f0 <vprintfmt+0x28d>
				putch('-', putdat);
f01016cd:	83 ec 08             	sub    $0x8,%esp
f01016d0:	ff 75 0c             	pushl  0xc(%ebp)
f01016d3:	6a 2d                	push   $0x2d
f01016d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01016d8:	ff d0                	call   *%eax
f01016da:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
f01016dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01016e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01016e3:	f7 d8                	neg    %eax
f01016e5:	83 d2 00             	adc    $0x0,%edx
f01016e8:	f7 da                	neg    %edx
f01016ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01016ed:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f01016f0:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01016f7:	e9 9f 00 00 00       	jmp    f010179b <vprintfmt+0x338>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01016fc:	83 ec 08             	sub    $0x8,%esp
f01016ff:	ff 75 e8             	pushl  -0x18(%ebp)
f0101702:	8d 45 14             	lea    0x14(%ebp),%eax
f0101705:	50                   	push   %eax
f0101706:	e8 c2 fc ff ff       	call   f01013cd <getuint>
f010170b:	83 c4 10             	add    $0x10,%esp
f010170e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101711:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f0101714:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f010171b:	eb 7e                	jmp    f010179b <vprintfmt+0x338>
			// Replace this with your code.
			// putch('X', putdat);
			// putch('X', putdat);
			// putch('X', putdat);

			num = getuint(&ap, lflag);
f010171d:	83 ec 08             	sub    $0x8,%esp
f0101720:	ff 75 e8             	pushl  -0x18(%ebp)
f0101723:	8d 45 14             	lea    0x14(%ebp),%eax
f0101726:	50                   	push   %eax
f0101727:	e8 a1 fc ff ff       	call   f01013cd <getuint>
f010172c:	83 c4 10             	add    $0x10,%esp
f010172f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101732:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 8;
f0101735:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
			goto number;
f010173c:	eb 5d                	jmp    f010179b <vprintfmt+0x338>

		// pointer
		case 'p':
			putch('0', putdat);
f010173e:	83 ec 08             	sub    $0x8,%esp
f0101741:	ff 75 0c             	pushl  0xc(%ebp)
f0101744:	6a 30                	push   $0x30
f0101746:	8b 45 08             	mov    0x8(%ebp),%eax
f0101749:	ff d0                	call   *%eax
f010174b:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
f010174e:	83 ec 08             	sub    $0x8,%esp
f0101751:	ff 75 0c             	pushl  0xc(%ebp)
f0101754:	6a 78                	push   $0x78
f0101756:	8b 45 08             	mov    0x8(%ebp),%eax
f0101759:	ff d0                	call   *%eax
f010175b:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010175e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101761:	8d 50 04             	lea    0x4(%eax),%edx
f0101764:	89 55 14             	mov    %edx,0x14(%ebp)
f0101767:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101769:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010176c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101773:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f010177a:	eb 1f                	jmp    f010179b <vprintfmt+0x338>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010177c:	83 ec 08             	sub    $0x8,%esp
f010177f:	ff 75 e8             	pushl  -0x18(%ebp)
f0101782:	8d 45 14             	lea    0x14(%ebp),%eax
f0101785:	50                   	push   %eax
f0101786:	e8 42 fc ff ff       	call   f01013cd <getuint>
f010178b:	83 c4 10             	add    $0x10,%esp
f010178e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101791:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0101794:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f010179b:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f010179f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017a2:	83 ec 04             	sub    $0x4,%esp
f01017a5:	52                   	push   %edx
f01017a6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01017a9:	50                   	push   %eax
f01017aa:	ff 75 f4             	pushl  -0xc(%ebp)
f01017ad:	ff 75 f0             	pushl  -0x10(%ebp)
f01017b0:	ff 75 0c             	pushl  0xc(%ebp)
f01017b3:	ff 75 08             	pushl  0x8(%ebp)
f01017b6:	e8 59 fb ff ff       	call   f0101314 <printnum>
f01017bb:	83 c4 20             	add    $0x20,%esp
			break;
f01017be:	eb 39                	jmp    f01017f9 <vprintfmt+0x396>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01017c0:	83 ec 08             	sub    $0x8,%esp
f01017c3:	ff 75 0c             	pushl  0xc(%ebp)
f01017c6:	53                   	push   %ebx
f01017c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ca:	ff d0                	call   *%eax
f01017cc:	83 c4 10             	add    $0x10,%esp
			break;
f01017cf:	eb 28                	jmp    f01017f9 <vprintfmt+0x396>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01017d1:	83 ec 08             	sub    $0x8,%esp
f01017d4:	ff 75 0c             	pushl  0xc(%ebp)
f01017d7:	6a 25                	push   $0x25
f01017d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017dc:	ff d0                	call   *%eax
f01017de:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
f01017e1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01017e5:	eb 04                	jmp    f01017eb <vprintfmt+0x388>
f01017e7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01017eb:	8b 45 10             	mov    0x10(%ebp),%eax
f01017ee:	83 e8 01             	sub    $0x1,%eax
f01017f1:	0f b6 00             	movzbl (%eax),%eax
f01017f4:	3c 25                	cmp    $0x25,%al
f01017f6:	75 ef                	jne    f01017e7 <vprintfmt+0x384>
				/* do nothing */;
			break;
f01017f8:	90                   	nop
		}
	}
f01017f9:	e9 6d fc ff ff       	jmp    f010146b <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
f01017fe:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01017ff:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101802:	5b                   	pop    %ebx
f0101803:	5e                   	pop    %esi
f0101804:	5d                   	pop    %ebp
f0101805:	c3                   	ret    

f0101806 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101806:	55                   	push   %ebp
f0101807:	89 e5                	mov    %esp,%ebp
f0101809:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010180c:	8d 45 14             	lea    0x14(%ebp),%eax
f010180f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f0101812:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101815:	50                   	push   %eax
f0101816:	ff 75 10             	pushl  0x10(%ebp)
f0101819:	ff 75 0c             	pushl  0xc(%ebp)
f010181c:	ff 75 08             	pushl  0x8(%ebp)
f010181f:	e8 3f fc ff ff       	call   f0101463 <vprintfmt>
f0101824:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f0101827:	90                   	nop
f0101828:	c9                   	leave  
f0101829:	c3                   	ret    

f010182a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010182a:	55                   	push   %ebp
f010182b:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f010182d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101830:	8b 40 08             	mov    0x8(%eax),%eax
f0101833:	8d 50 01             	lea    0x1(%eax),%edx
f0101836:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101839:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f010183c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010183f:	8b 10                	mov    (%eax),%edx
f0101841:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101844:	8b 40 04             	mov    0x4(%eax),%eax
f0101847:	39 c2                	cmp    %eax,%edx
f0101849:	73 12                	jae    f010185d <sprintputch+0x33>
		*b->buf++ = ch;
f010184b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010184e:	8b 00                	mov    (%eax),%eax
f0101850:	8d 48 01             	lea    0x1(%eax),%ecx
f0101853:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101856:	89 0a                	mov    %ecx,(%edx)
f0101858:	8b 55 08             	mov    0x8(%ebp),%edx
f010185b:	88 10                	mov    %dl,(%eax)
}
f010185d:	90                   	nop
f010185e:	5d                   	pop    %ebp
f010185f:	c3                   	ret    

f0101860 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101860:	55                   	push   %ebp
f0101861:	89 e5                	mov    %esp,%ebp
f0101863:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101866:	8b 45 08             	mov    0x8(%ebp),%eax
f0101869:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010186c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010186f:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101872:	8b 45 08             	mov    0x8(%ebp),%eax
f0101875:	01 d0                	add    %edx,%eax
f0101877:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010187a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101881:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101885:	74 06                	je     f010188d <vsnprintf+0x2d>
f0101887:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010188b:	7f 07                	jg     f0101894 <vsnprintf+0x34>
		return -E_INVAL;
f010188d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101892:	eb 20                	jmp    f01018b4 <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101894:	ff 75 14             	pushl  0x14(%ebp)
f0101897:	ff 75 10             	pushl  0x10(%ebp)
f010189a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010189d:	50                   	push   %eax
f010189e:	68 2a 18 10 f0       	push   $0xf010182a
f01018a3:	e8 bb fb ff ff       	call   f0101463 <vprintfmt>
f01018a8:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
f01018ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018ae:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01018b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01018b4:	c9                   	leave  
f01018b5:	c3                   	ret    

f01018b6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01018b6:	55                   	push   %ebp
f01018b7:	89 e5                	mov    %esp,%ebp
f01018b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01018bc:	8d 45 14             	lea    0x14(%ebp),%eax
f01018bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f01018c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018c5:	50                   	push   %eax
f01018c6:	ff 75 10             	pushl  0x10(%ebp)
f01018c9:	ff 75 0c             	pushl  0xc(%ebp)
f01018cc:	ff 75 08             	pushl  0x8(%ebp)
f01018cf:	e8 8c ff ff ff       	call   f0101860 <vsnprintf>
f01018d4:	83 c4 10             	add    $0x10,%esp
f01018d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return rc;
f01018da:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01018dd:	c9                   	leave  
f01018de:	c3                   	ret    

f01018df <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01018df:	55                   	push   %ebp
f01018e0:	89 e5                	mov    %esp,%ebp
f01018e2:	83 ec 18             	sub    $0x18,%esp
	int i, c, echoing;

	if (prompt != NULL)
f01018e5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01018e9:	74 13                	je     f01018fe <readline+0x1f>
		cprintf("%s", prompt);
f01018eb:	83 ec 08             	sub    $0x8,%esp
f01018ee:	ff 75 08             	pushl  0x8(%ebp)
f01018f1:	68 5c 27 10 f0       	push   $0xf010275c
f01018f6:	e8 69 f5 ff ff       	call   f0100e64 <cprintf>
f01018fb:	83 c4 10             	add    $0x10,%esp

	i = 0;
f01018fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);
f0101905:	83 ec 0c             	sub    $0xc,%esp
f0101908:	6a 00                	push   $0x0
f010190a:	e8 10 f1 ff ff       	call   f0100a1f <iscons>
f010190f:	83 c4 10             	add    $0x10,%esp
f0101912:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f0101915:	e8 ec f0 ff ff       	call   f0100a06 <getchar>
f010191a:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f010191d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0101921:	79 1d                	jns    f0101940 <readline+0x61>
			cprintf("read error: %e\n", c);
f0101923:	83 ec 08             	sub    $0x8,%esp
f0101926:	ff 75 ec             	pushl  -0x14(%ebp)
f0101929:	68 5f 27 10 f0       	push   $0xf010275f
f010192e:	e8 31 f5 ff ff       	call   f0100e64 <cprintf>
f0101933:	83 c4 10             	add    $0x10,%esp
			return NULL;
f0101936:	b8 00 00 00 00       	mov    $0x0,%eax
f010193b:	e9 9c 00 00 00       	jmp    f01019dc <readline+0xfd>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101940:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0101944:	74 06                	je     f010194c <readline+0x6d>
f0101946:	83 7d ec 7f          	cmpl   $0x7f,-0x14(%ebp)
f010194a:	75 1f                	jne    f010196b <readline+0x8c>
f010194c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0101950:	7e 19                	jle    f010196b <readline+0x8c>
			if (echoing)
f0101952:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101956:	74 0d                	je     f0101965 <readline+0x86>
				cputchar('\b');
f0101958:	83 ec 0c             	sub    $0xc,%esp
f010195b:	6a 08                	push   $0x8
f010195d:	e8 8d f0 ff ff       	call   f01009ef <cputchar>
f0101962:	83 c4 10             	add    $0x10,%esp
			i--;
f0101965:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
f0101969:	eb 6c                	jmp    f01019d7 <readline+0xf8>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010196b:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f010196f:	7e 31                	jle    f01019a2 <readline+0xc3>
f0101971:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f0101978:	7f 28                	jg     f01019a2 <readline+0xc3>
			if (echoing)
f010197a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010197e:	74 0e                	je     f010198e <readline+0xaf>
				cputchar(c);
f0101980:	83 ec 0c             	sub    $0xc,%esp
f0101983:	ff 75 ec             	pushl  -0x14(%ebp)
f0101986:	e8 64 f0 ff ff       	call   f01009ef <cputchar>
f010198b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010198e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101991:	8d 50 01             	lea    0x1(%eax),%edx
f0101994:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101997:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010199a:	88 90 a0 37 11 f0    	mov    %dl,-0xfeec860(%eax)
f01019a0:	eb 35                	jmp    f01019d7 <readline+0xf8>
		} else if (c == '\n' || c == '\r') {
f01019a2:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f01019a6:	74 0a                	je     f01019b2 <readline+0xd3>
f01019a8:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f01019ac:	0f 85 63 ff ff ff    	jne    f0101915 <readline+0x36>
			if (echoing)
f01019b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01019b6:	74 0d                	je     f01019c5 <readline+0xe6>
				cputchar('\n');
f01019b8:	83 ec 0c             	sub    $0xc,%esp
f01019bb:	6a 0a                	push   $0xa
f01019bd:	e8 2d f0 ff ff       	call   f01009ef <cputchar>
f01019c2:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01019c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01019c8:	05 a0 37 11 f0       	add    $0xf01137a0,%eax
f01019cd:	c6 00 00             	movb   $0x0,(%eax)
			return buf;
f01019d0:	b8 a0 37 11 f0       	mov    $0xf01137a0,%eax
f01019d5:	eb 05                	jmp    f01019dc <readline+0xfd>
		}
	}
f01019d7:	e9 39 ff ff ff       	jmp    f0101915 <readline+0x36>
}
f01019dc:	c9                   	leave  
f01019dd:	c3                   	ret    

f01019de <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01019de:	55                   	push   %ebp
f01019df:	89 e5                	mov    %esp,%ebp
f01019e1:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f01019e4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01019eb:	eb 08                	jmp    f01019f5 <strlen+0x17>
		n++;
f01019ed:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01019f1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01019f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01019f8:	0f b6 00             	movzbl (%eax),%eax
f01019fb:	84 c0                	test   %al,%al
f01019fd:	75 ee                	jne    f01019ed <strlen+0xf>
		n++;
	return n;
f01019ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0101a02:	c9                   	leave  
f0101a03:	c3                   	ret    

f0101a04 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101a04:	55                   	push   %ebp
f0101a05:	89 e5                	mov    %esp,%ebp
f0101a07:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101a0a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0101a11:	eb 0c                	jmp    f0101a1f <strnlen+0x1b>
		n++;
f0101a13:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101a17:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101a1b:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
f0101a1f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101a23:	74 0a                	je     f0101a2f <strnlen+0x2b>
f0101a25:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a28:	0f b6 00             	movzbl (%eax),%eax
f0101a2b:	84 c0                	test   %al,%al
f0101a2d:	75 e4                	jne    f0101a13 <strnlen+0xf>
		n++;
	return n;
f0101a2f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0101a32:	c9                   	leave  
f0101a33:	c3                   	ret    

f0101a34 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101a34:	55                   	push   %ebp
f0101a35:	89 e5                	mov    %esp,%ebp
f0101a37:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0101a3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a3d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f0101a40:	90                   	nop
f0101a41:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a44:	8d 50 01             	lea    0x1(%eax),%edx
f0101a47:	89 55 08             	mov    %edx,0x8(%ebp)
f0101a4a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101a4d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101a50:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0101a53:	0f b6 12             	movzbl (%edx),%edx
f0101a56:	88 10                	mov    %dl,(%eax)
f0101a58:	0f b6 00             	movzbl (%eax),%eax
f0101a5b:	84 c0                	test   %al,%al
f0101a5d:	75 e2                	jne    f0101a41 <strcpy+0xd>
		/* do nothing */;
	return ret;
f0101a5f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0101a62:	c9                   	leave  
f0101a63:	c3                   	ret    

f0101a64 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101a64:	55                   	push   %ebp
f0101a65:	89 e5                	mov    %esp,%ebp
f0101a67:	83 ec 10             	sub    $0x10,%esp
	int len = strlen(dst);
f0101a6a:	ff 75 08             	pushl  0x8(%ebp)
f0101a6d:	e8 6c ff ff ff       	call   f01019de <strlen>
f0101a72:	83 c4 04             	add    $0x4,%esp
f0101a75:	89 45 fc             	mov    %eax,-0x4(%ebp)
	strcpy(dst + len, src);
f0101a78:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0101a7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a7e:	01 d0                	add    %edx,%eax
f0101a80:	ff 75 0c             	pushl  0xc(%ebp)
f0101a83:	50                   	push   %eax
f0101a84:	e8 ab ff ff ff       	call   f0101a34 <strcpy>
f0101a89:	83 c4 08             	add    $0x8,%esp
	return dst;
f0101a8c:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101a8f:	c9                   	leave  
f0101a90:	c3                   	ret    

f0101a91 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101a91:	55                   	push   %ebp
f0101a92:	89 e5                	mov    %esp,%ebp
f0101a94:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
f0101a97:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a9a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f0101a9d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0101aa4:	eb 23                	jmp    f0101ac9 <strncpy+0x38>
		*dst++ = *src;
f0101aa6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aa9:	8d 50 01             	lea    0x1(%eax),%edx
f0101aac:	89 55 08             	mov    %edx,0x8(%ebp)
f0101aaf:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101ab2:	0f b6 12             	movzbl (%edx),%edx
f0101ab5:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0101ab7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101aba:	0f b6 00             	movzbl (%eax),%eax
f0101abd:	84 c0                	test   %al,%al
f0101abf:	74 04                	je     f0101ac5 <strncpy+0x34>
			src++;
f0101ac1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ac5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0101ac9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101acc:	3b 45 10             	cmp    0x10(%ebp),%eax
f0101acf:	72 d5                	jb     f0101aa6 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0101ad1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0101ad4:	c9                   	leave  
f0101ad5:	c3                   	ret    

f0101ad6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101ad6:	55                   	push   %ebp
f0101ad7:	89 e5                	mov    %esp,%ebp
f0101ad9:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f0101adc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101adf:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0101ae2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101ae6:	74 33                	je     f0101b1b <strlcpy+0x45>
		while (--size > 0 && *src != '\0')
f0101ae8:	eb 17                	jmp    f0101b01 <strlcpy+0x2b>
			*dst++ = *src++;
f0101aea:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aed:	8d 50 01             	lea    0x1(%eax),%edx
f0101af0:	89 55 08             	mov    %edx,0x8(%ebp)
f0101af3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101af6:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101af9:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0101afc:	0f b6 12             	movzbl (%edx),%edx
f0101aff:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101b01:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0101b05:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101b09:	74 0a                	je     f0101b15 <strlcpy+0x3f>
f0101b0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b0e:	0f b6 00             	movzbl (%eax),%eax
f0101b11:	84 c0                	test   %al,%al
f0101b13:	75 d5                	jne    f0101aea <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0101b15:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b18:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101b1b:	8b 55 08             	mov    0x8(%ebp),%edx
f0101b1e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101b21:	29 c2                	sub    %eax,%edx
f0101b23:	89 d0                	mov    %edx,%eax
}
f0101b25:	c9                   	leave  
f0101b26:	c3                   	ret    

f0101b27 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101b27:	55                   	push   %ebp
f0101b28:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0101b2a:	eb 08                	jmp    f0101b34 <strcmp+0xd>
		p++, q++;
f0101b2c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101b30:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101b34:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b37:	0f b6 00             	movzbl (%eax),%eax
f0101b3a:	84 c0                	test   %al,%al
f0101b3c:	74 10                	je     f0101b4e <strcmp+0x27>
f0101b3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b41:	0f b6 10             	movzbl (%eax),%edx
f0101b44:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b47:	0f b6 00             	movzbl (%eax),%eax
f0101b4a:	38 c2                	cmp    %al,%dl
f0101b4c:	74 de                	je     f0101b2c <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101b4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b51:	0f b6 00             	movzbl (%eax),%eax
f0101b54:	0f b6 d0             	movzbl %al,%edx
f0101b57:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b5a:	0f b6 00             	movzbl (%eax),%eax
f0101b5d:	0f b6 c0             	movzbl %al,%eax
f0101b60:	29 c2                	sub    %eax,%edx
f0101b62:	89 d0                	mov    %edx,%eax
}
f0101b64:	5d                   	pop    %ebp
f0101b65:	c3                   	ret    

f0101b66 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101b66:	55                   	push   %ebp
f0101b67:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f0101b69:	eb 0c                	jmp    f0101b77 <strncmp+0x11>
		n--, p++, q++;
f0101b6b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0101b6f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101b73:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101b77:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101b7b:	74 1a                	je     f0101b97 <strncmp+0x31>
f0101b7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b80:	0f b6 00             	movzbl (%eax),%eax
f0101b83:	84 c0                	test   %al,%al
f0101b85:	74 10                	je     f0101b97 <strncmp+0x31>
f0101b87:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b8a:	0f b6 10             	movzbl (%eax),%edx
f0101b8d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b90:	0f b6 00             	movzbl (%eax),%eax
f0101b93:	38 c2                	cmp    %al,%dl
f0101b95:	74 d4                	je     f0101b6b <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0101b97:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101b9b:	75 07                	jne    f0101ba4 <strncmp+0x3e>
		return 0;
f0101b9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ba2:	eb 16                	jmp    f0101bba <strncmp+0x54>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101ba4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ba7:	0f b6 00             	movzbl (%eax),%eax
f0101baa:	0f b6 d0             	movzbl %al,%edx
f0101bad:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bb0:	0f b6 00             	movzbl (%eax),%eax
f0101bb3:	0f b6 c0             	movzbl %al,%eax
f0101bb6:	29 c2                	sub    %eax,%edx
f0101bb8:	89 d0                	mov    %edx,%eax
}
f0101bba:	5d                   	pop    %ebp
f0101bbb:	c3                   	ret    

f0101bbc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101bbc:	55                   	push   %ebp
f0101bbd:	89 e5                	mov    %esp,%ebp
f0101bbf:	83 ec 04             	sub    $0x4,%esp
f0101bc2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bc5:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0101bc8:	eb 14                	jmp    f0101bde <strchr+0x22>
		if (*s == c)
f0101bca:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bcd:	0f b6 00             	movzbl (%eax),%eax
f0101bd0:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0101bd3:	75 05                	jne    f0101bda <strchr+0x1e>
			return (char *) s;
f0101bd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bd8:	eb 13                	jmp    f0101bed <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101bda:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101bde:	8b 45 08             	mov    0x8(%ebp),%eax
f0101be1:	0f b6 00             	movzbl (%eax),%eax
f0101be4:	84 c0                	test   %al,%al
f0101be6:	75 e2                	jne    f0101bca <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0101be8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101bed:	c9                   	leave  
f0101bee:	c3                   	ret    

f0101bef <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101bef:	55                   	push   %ebp
f0101bf0:	89 e5                	mov    %esp,%ebp
f0101bf2:	83 ec 04             	sub    $0x4,%esp
f0101bf5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bf8:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0101bfb:	eb 0f                	jmp    f0101c0c <strfind+0x1d>
		if (*s == c)
f0101bfd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c00:	0f b6 00             	movzbl (%eax),%eax
f0101c03:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0101c06:	74 10                	je     f0101c18 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101c08:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101c0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c0f:	0f b6 00             	movzbl (%eax),%eax
f0101c12:	84 c0                	test   %al,%al
f0101c14:	75 e7                	jne    f0101bfd <strfind+0xe>
f0101c16:	eb 01                	jmp    f0101c19 <strfind+0x2a>
		if (*s == c)
			break;
f0101c18:	90                   	nop
	return (char *) s;
f0101c19:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101c1c:	c9                   	leave  
f0101c1d:	c3                   	ret    

f0101c1e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101c1e:	55                   	push   %ebp
f0101c1f:	89 e5                	mov    %esp,%ebp
f0101c21:	57                   	push   %edi
	char *p;

	if (n == 0)
f0101c22:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101c26:	75 05                	jne    f0101c2d <memset+0xf>
		return v;
f0101c28:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c2b:	eb 5c                	jmp    f0101c89 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
f0101c2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c30:	83 e0 03             	and    $0x3,%eax
f0101c33:	85 c0                	test   %eax,%eax
f0101c35:	75 41                	jne    f0101c78 <memset+0x5a>
f0101c37:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c3a:	83 e0 03             	and    $0x3,%eax
f0101c3d:	85 c0                	test   %eax,%eax
f0101c3f:	75 37                	jne    f0101c78 <memset+0x5a>
		c &= 0xFF;
f0101c41:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101c48:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c4b:	c1 e0 18             	shl    $0x18,%eax
f0101c4e:	89 c2                	mov    %eax,%edx
f0101c50:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c53:	c1 e0 10             	shl    $0x10,%eax
f0101c56:	09 c2                	or     %eax,%edx
f0101c58:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c5b:	c1 e0 08             	shl    $0x8,%eax
f0101c5e:	09 d0                	or     %edx,%eax
f0101c60:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101c63:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c66:	c1 e8 02             	shr    $0x2,%eax
f0101c69:	89 c1                	mov    %eax,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101c6b:	8b 55 08             	mov    0x8(%ebp),%edx
f0101c6e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c71:	89 d7                	mov    %edx,%edi
f0101c73:	fc                   	cld    
f0101c74:	f3 ab                	rep stos %eax,%es:(%edi)
f0101c76:	eb 0e                	jmp    f0101c86 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101c78:	8b 55 08             	mov    0x8(%ebp),%edx
f0101c7b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101c81:	89 d7                	mov    %edx,%edi
f0101c83:	fc                   	cld    
f0101c84:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
f0101c86:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101c89:	5f                   	pop    %edi
f0101c8a:	5d                   	pop    %ebp
f0101c8b:	c3                   	ret    

f0101c8c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101c8c:	55                   	push   %ebp
f0101c8d:	89 e5                	mov    %esp,%ebp
f0101c8f:	57                   	push   %edi
f0101c90:	56                   	push   %esi
f0101c91:	53                   	push   %ebx
f0101c92:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0101c95:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c98:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
f0101c9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c9e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
f0101ca1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101ca4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0101ca7:	73 6d                	jae    f0101d16 <memmove+0x8a>
f0101ca9:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101cac:	8b 45 10             	mov    0x10(%ebp),%eax
f0101caf:	01 d0                	add    %edx,%eax
f0101cb1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0101cb4:	76 60                	jbe    f0101d16 <memmove+0x8a>
		s += n;
f0101cb6:	8b 45 10             	mov    0x10(%ebp),%eax
f0101cb9:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
f0101cbc:	8b 45 10             	mov    0x10(%ebp),%eax
f0101cbf:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101cc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101cc5:	83 e0 03             	and    $0x3,%eax
f0101cc8:	85 c0                	test   %eax,%eax
f0101cca:	75 2f                	jne    f0101cfb <memmove+0x6f>
f0101ccc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ccf:	83 e0 03             	and    $0x3,%eax
f0101cd2:	85 c0                	test   %eax,%eax
f0101cd4:	75 25                	jne    f0101cfb <memmove+0x6f>
f0101cd6:	8b 45 10             	mov    0x10(%ebp),%eax
f0101cd9:	83 e0 03             	and    $0x3,%eax
f0101cdc:	85 c0                	test   %eax,%eax
f0101cde:	75 1b                	jne    f0101cfb <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101ce0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ce3:	83 e8 04             	sub    $0x4,%eax
f0101ce6:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101ce9:	83 ea 04             	sub    $0x4,%edx
f0101cec:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101cef:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101cf2:	89 c7                	mov    %eax,%edi
f0101cf4:	89 d6                	mov    %edx,%esi
f0101cf6:	fd                   	std    
f0101cf7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101cf9:	eb 18                	jmp    f0101d13 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101cfb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101cfe:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101d01:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d04:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101d07:	8b 45 10             	mov    0x10(%ebp),%eax
f0101d0a:	89 d7                	mov    %edx,%edi
f0101d0c:	89 de                	mov    %ebx,%esi
f0101d0e:	89 c1                	mov    %eax,%ecx
f0101d10:	fd                   	std    
f0101d11:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101d13:	fc                   	cld    
f0101d14:	eb 45                	jmp    f0101d5b <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101d16:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d19:	83 e0 03             	and    $0x3,%eax
f0101d1c:	85 c0                	test   %eax,%eax
f0101d1e:	75 2b                	jne    f0101d4b <memmove+0xbf>
f0101d20:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d23:	83 e0 03             	and    $0x3,%eax
f0101d26:	85 c0                	test   %eax,%eax
f0101d28:	75 21                	jne    f0101d4b <memmove+0xbf>
f0101d2a:	8b 45 10             	mov    0x10(%ebp),%eax
f0101d2d:	83 e0 03             	and    $0x3,%eax
f0101d30:	85 c0                	test   %eax,%eax
f0101d32:	75 17                	jne    f0101d4b <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101d34:	8b 45 10             	mov    0x10(%ebp),%eax
f0101d37:	c1 e8 02             	shr    $0x2,%eax
f0101d3a:	89 c1                	mov    %eax,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101d3c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d3f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101d42:	89 c7                	mov    %eax,%edi
f0101d44:	89 d6                	mov    %edx,%esi
f0101d46:	fc                   	cld    
f0101d47:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101d49:	eb 10                	jmp    f0101d5b <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101d4b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d4e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101d51:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101d54:	89 c7                	mov    %eax,%edi
f0101d56:	89 d6                	mov    %edx,%esi
f0101d58:	fc                   	cld    
f0101d59:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
f0101d5b:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101d5e:	83 c4 10             	add    $0x10,%esp
f0101d61:	5b                   	pop    %ebx
f0101d62:	5e                   	pop    %esi
f0101d63:	5f                   	pop    %edi
f0101d64:	5d                   	pop    %ebp
f0101d65:	c3                   	ret    

f0101d66 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101d66:	55                   	push   %ebp
f0101d67:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101d69:	ff 75 10             	pushl  0x10(%ebp)
f0101d6c:	ff 75 0c             	pushl  0xc(%ebp)
f0101d6f:	ff 75 08             	pushl  0x8(%ebp)
f0101d72:	e8 15 ff ff ff       	call   f0101c8c <memmove>
f0101d77:	83 c4 0c             	add    $0xc,%esp
}
f0101d7a:	c9                   	leave  
f0101d7b:	c3                   	ret    

f0101d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101d7c:	55                   	push   %ebp
f0101d7d:	89 e5                	mov    %esp,%ebp
f0101d7f:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
f0101d82:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d85:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
f0101d88:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101d8b:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0101d8e:	eb 30                	jmp    f0101dc0 <memcmp+0x44>
		if (*s1 != *s2)
f0101d90:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101d93:	0f b6 10             	movzbl (%eax),%edx
f0101d96:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101d99:	0f b6 00             	movzbl (%eax),%eax
f0101d9c:	38 c2                	cmp    %al,%dl
f0101d9e:	74 18                	je     f0101db8 <memcmp+0x3c>
			return (int) *s1 - (int) *s2;
f0101da0:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101da3:	0f b6 00             	movzbl (%eax),%eax
f0101da6:	0f b6 d0             	movzbl %al,%edx
f0101da9:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101dac:	0f b6 00             	movzbl (%eax),%eax
f0101daf:	0f b6 c0             	movzbl %al,%eax
f0101db2:	29 c2                	sub    %eax,%edx
f0101db4:	89 d0                	mov    %edx,%eax
f0101db6:	eb 1a                	jmp    f0101dd2 <memcmp+0x56>
		s1++, s2++;
f0101db8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0101dbc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101dc0:	8b 45 10             	mov    0x10(%ebp),%eax
f0101dc3:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101dc6:	89 55 10             	mov    %edx,0x10(%ebp)
f0101dc9:	85 c0                	test   %eax,%eax
f0101dcb:	75 c3                	jne    f0101d90 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101dcd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101dd2:	c9                   	leave  
f0101dd3:	c3                   	ret    

f0101dd4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101dd4:	55                   	push   %ebp
f0101dd5:	89 e5                	mov    %esp,%ebp
f0101dd7:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0101dda:	8b 55 08             	mov    0x8(%ebp),%edx
f0101ddd:	8b 45 10             	mov    0x10(%ebp),%eax
f0101de0:	01 d0                	add    %edx,%eax
f0101de2:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0101de5:	eb 17                	jmp    f0101dfe <memfind+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101de7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dea:	0f b6 00             	movzbl (%eax),%eax
f0101ded:	0f b6 d0             	movzbl %al,%edx
f0101df0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101df3:	0f b6 c0             	movzbl %al,%eax
f0101df6:	39 c2                	cmp    %eax,%edx
f0101df8:	74 0e                	je     f0101e08 <memfind+0x34>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101dfa:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101dfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e01:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0101e04:	72 e1                	jb     f0101de7 <memfind+0x13>
f0101e06:	eb 01                	jmp    f0101e09 <memfind+0x35>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
f0101e08:	90                   	nop
	return (void *) s;
f0101e09:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101e0c:	c9                   	leave  
f0101e0d:	c3                   	ret    

f0101e0e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101e0e:	55                   	push   %ebp
f0101e0f:	89 e5                	mov    %esp,%ebp
f0101e11:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f0101e14:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f0101e1b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101e22:	eb 04                	jmp    f0101e28 <strtol+0x1a>
		s++;
f0101e24:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101e28:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e2b:	0f b6 00             	movzbl (%eax),%eax
f0101e2e:	3c 20                	cmp    $0x20,%al
f0101e30:	74 f2                	je     f0101e24 <strtol+0x16>
f0101e32:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e35:	0f b6 00             	movzbl (%eax),%eax
f0101e38:	3c 09                	cmp    $0x9,%al
f0101e3a:	74 e8                	je     f0101e24 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101e3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e3f:	0f b6 00             	movzbl (%eax),%eax
f0101e42:	3c 2b                	cmp    $0x2b,%al
f0101e44:	75 06                	jne    f0101e4c <strtol+0x3e>
		s++;
f0101e46:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101e4a:	eb 15                	jmp    f0101e61 <strtol+0x53>
	else if (*s == '-')
f0101e4c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e4f:	0f b6 00             	movzbl (%eax),%eax
f0101e52:	3c 2d                	cmp    $0x2d,%al
f0101e54:	75 0b                	jne    f0101e61 <strtol+0x53>
		s++, neg = 1;
f0101e56:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101e5a:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101e61:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101e65:	74 06                	je     f0101e6d <strtol+0x5f>
f0101e67:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0101e6b:	75 24                	jne    f0101e91 <strtol+0x83>
f0101e6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e70:	0f b6 00             	movzbl (%eax),%eax
f0101e73:	3c 30                	cmp    $0x30,%al
f0101e75:	75 1a                	jne    f0101e91 <strtol+0x83>
f0101e77:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e7a:	83 c0 01             	add    $0x1,%eax
f0101e7d:	0f b6 00             	movzbl (%eax),%eax
f0101e80:	3c 78                	cmp    $0x78,%al
f0101e82:	75 0d                	jne    f0101e91 <strtol+0x83>
		s += 2, base = 16;
f0101e84:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0101e88:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0101e8f:	eb 2a                	jmp    f0101ebb <strtol+0xad>
	else if (base == 0 && s[0] == '0')
f0101e91:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101e95:	75 17                	jne    f0101eae <strtol+0xa0>
f0101e97:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e9a:	0f b6 00             	movzbl (%eax),%eax
f0101e9d:	3c 30                	cmp    $0x30,%al
f0101e9f:	75 0d                	jne    f0101eae <strtol+0xa0>
		s++, base = 8;
f0101ea1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101ea5:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0101eac:	eb 0d                	jmp    f0101ebb <strtol+0xad>
	else if (base == 0)
f0101eae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101eb2:	75 07                	jne    f0101ebb <strtol+0xad>
		base = 10;
f0101eb4:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101ebb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ebe:	0f b6 00             	movzbl (%eax),%eax
f0101ec1:	3c 2f                	cmp    $0x2f,%al
f0101ec3:	7e 1b                	jle    f0101ee0 <strtol+0xd2>
f0101ec5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ec8:	0f b6 00             	movzbl (%eax),%eax
f0101ecb:	3c 39                	cmp    $0x39,%al
f0101ecd:	7f 11                	jg     f0101ee0 <strtol+0xd2>
			dig = *s - '0';
f0101ecf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ed2:	0f b6 00             	movzbl (%eax),%eax
f0101ed5:	0f be c0             	movsbl %al,%eax
f0101ed8:	83 e8 30             	sub    $0x30,%eax
f0101edb:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101ede:	eb 48                	jmp    f0101f28 <strtol+0x11a>
		else if (*s >= 'a' && *s <= 'z')
f0101ee0:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ee3:	0f b6 00             	movzbl (%eax),%eax
f0101ee6:	3c 60                	cmp    $0x60,%al
f0101ee8:	7e 1b                	jle    f0101f05 <strtol+0xf7>
f0101eea:	8b 45 08             	mov    0x8(%ebp),%eax
f0101eed:	0f b6 00             	movzbl (%eax),%eax
f0101ef0:	3c 7a                	cmp    $0x7a,%al
f0101ef2:	7f 11                	jg     f0101f05 <strtol+0xf7>
			dig = *s - 'a' + 10;
f0101ef4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ef7:	0f b6 00             	movzbl (%eax),%eax
f0101efa:	0f be c0             	movsbl %al,%eax
f0101efd:	83 e8 57             	sub    $0x57,%eax
f0101f00:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101f03:	eb 23                	jmp    f0101f28 <strtol+0x11a>
		else if (*s >= 'A' && *s <= 'Z')
f0101f05:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f08:	0f b6 00             	movzbl (%eax),%eax
f0101f0b:	3c 40                	cmp    $0x40,%al
f0101f0d:	7e 3c                	jle    f0101f4b <strtol+0x13d>
f0101f0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f12:	0f b6 00             	movzbl (%eax),%eax
f0101f15:	3c 5a                	cmp    $0x5a,%al
f0101f17:	7f 32                	jg     f0101f4b <strtol+0x13d>
			dig = *s - 'A' + 10;
f0101f19:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f1c:	0f b6 00             	movzbl (%eax),%eax
f0101f1f:	0f be c0             	movsbl %al,%eax
f0101f22:	83 e8 37             	sub    $0x37,%eax
f0101f25:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f0101f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101f2b:	3b 45 10             	cmp    0x10(%ebp),%eax
f0101f2e:	7d 1a                	jge    f0101f4a <strtol+0x13c>
			break;
		s++, val = (val * base) + dig;
f0101f30:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101f34:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101f37:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101f3b:	89 c2                	mov    %eax,%edx
f0101f3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101f40:	01 d0                	add    %edx,%eax
f0101f42:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0101f45:	e9 71 ff ff ff       	jmp    f0101ebb <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
f0101f4a:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101f4b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101f4f:	74 08                	je     f0101f59 <strtol+0x14b>
		*endptr = (char *) s;
f0101f51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f54:	8b 55 08             	mov    0x8(%ebp),%edx
f0101f57:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0101f59:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0101f5d:	74 07                	je     f0101f66 <strtol+0x158>
f0101f5f:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101f62:	f7 d8                	neg    %eax
f0101f64:	eb 03                	jmp    f0101f69 <strtol+0x15b>
f0101f66:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0101f69:	c9                   	leave  
f0101f6a:	c3                   	ret    
f0101f6b:	66 90                	xchg   %ax,%ax
f0101f6d:	66 90                	xchg   %ax,%ax
f0101f6f:	90                   	nop

f0101f70 <__udivdi3>:
f0101f70:	55                   	push   %ebp
f0101f71:	57                   	push   %edi
f0101f72:	56                   	push   %esi
f0101f73:	53                   	push   %ebx
f0101f74:	83 ec 1c             	sub    $0x1c,%esp
f0101f77:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0101f7b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0101f7f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101f83:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101f87:	85 f6                	test   %esi,%esi
f0101f89:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101f8d:	89 ca                	mov    %ecx,%edx
f0101f8f:	89 f8                	mov    %edi,%eax
f0101f91:	75 3d                	jne    f0101fd0 <__udivdi3+0x60>
f0101f93:	39 cf                	cmp    %ecx,%edi
f0101f95:	0f 87 c5 00 00 00    	ja     f0102060 <__udivdi3+0xf0>
f0101f9b:	85 ff                	test   %edi,%edi
f0101f9d:	89 fd                	mov    %edi,%ebp
f0101f9f:	75 0b                	jne    f0101fac <__udivdi3+0x3c>
f0101fa1:	b8 01 00 00 00       	mov    $0x1,%eax
f0101fa6:	31 d2                	xor    %edx,%edx
f0101fa8:	f7 f7                	div    %edi
f0101faa:	89 c5                	mov    %eax,%ebp
f0101fac:	89 c8                	mov    %ecx,%eax
f0101fae:	31 d2                	xor    %edx,%edx
f0101fb0:	f7 f5                	div    %ebp
f0101fb2:	89 c1                	mov    %eax,%ecx
f0101fb4:	89 d8                	mov    %ebx,%eax
f0101fb6:	89 cf                	mov    %ecx,%edi
f0101fb8:	f7 f5                	div    %ebp
f0101fba:	89 c3                	mov    %eax,%ebx
f0101fbc:	89 d8                	mov    %ebx,%eax
f0101fbe:	89 fa                	mov    %edi,%edx
f0101fc0:	83 c4 1c             	add    $0x1c,%esp
f0101fc3:	5b                   	pop    %ebx
f0101fc4:	5e                   	pop    %esi
f0101fc5:	5f                   	pop    %edi
f0101fc6:	5d                   	pop    %ebp
f0101fc7:	c3                   	ret    
f0101fc8:	90                   	nop
f0101fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101fd0:	39 ce                	cmp    %ecx,%esi
f0101fd2:	77 74                	ja     f0102048 <__udivdi3+0xd8>
f0101fd4:	0f bd fe             	bsr    %esi,%edi
f0101fd7:	83 f7 1f             	xor    $0x1f,%edi
f0101fda:	0f 84 98 00 00 00    	je     f0102078 <__udivdi3+0x108>
f0101fe0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101fe5:	89 f9                	mov    %edi,%ecx
f0101fe7:	89 c5                	mov    %eax,%ebp
f0101fe9:	29 fb                	sub    %edi,%ebx
f0101feb:	d3 e6                	shl    %cl,%esi
f0101fed:	89 d9                	mov    %ebx,%ecx
f0101fef:	d3 ed                	shr    %cl,%ebp
f0101ff1:	89 f9                	mov    %edi,%ecx
f0101ff3:	d3 e0                	shl    %cl,%eax
f0101ff5:	09 ee                	or     %ebp,%esi
f0101ff7:	89 d9                	mov    %ebx,%ecx
f0101ff9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ffd:	89 d5                	mov    %edx,%ebp
f0101fff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102003:	d3 ed                	shr    %cl,%ebp
f0102005:	89 f9                	mov    %edi,%ecx
f0102007:	d3 e2                	shl    %cl,%edx
f0102009:	89 d9                	mov    %ebx,%ecx
f010200b:	d3 e8                	shr    %cl,%eax
f010200d:	09 c2                	or     %eax,%edx
f010200f:	89 d0                	mov    %edx,%eax
f0102011:	89 ea                	mov    %ebp,%edx
f0102013:	f7 f6                	div    %esi
f0102015:	89 d5                	mov    %edx,%ebp
f0102017:	89 c3                	mov    %eax,%ebx
f0102019:	f7 64 24 0c          	mull   0xc(%esp)
f010201d:	39 d5                	cmp    %edx,%ebp
f010201f:	72 10                	jb     f0102031 <__udivdi3+0xc1>
f0102021:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102025:	89 f9                	mov    %edi,%ecx
f0102027:	d3 e6                	shl    %cl,%esi
f0102029:	39 c6                	cmp    %eax,%esi
f010202b:	73 07                	jae    f0102034 <__udivdi3+0xc4>
f010202d:	39 d5                	cmp    %edx,%ebp
f010202f:	75 03                	jne    f0102034 <__udivdi3+0xc4>
f0102031:	83 eb 01             	sub    $0x1,%ebx
f0102034:	31 ff                	xor    %edi,%edi
f0102036:	89 d8                	mov    %ebx,%eax
f0102038:	89 fa                	mov    %edi,%edx
f010203a:	83 c4 1c             	add    $0x1c,%esp
f010203d:	5b                   	pop    %ebx
f010203e:	5e                   	pop    %esi
f010203f:	5f                   	pop    %edi
f0102040:	5d                   	pop    %ebp
f0102041:	c3                   	ret    
f0102042:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102048:	31 ff                	xor    %edi,%edi
f010204a:	31 db                	xor    %ebx,%ebx
f010204c:	89 d8                	mov    %ebx,%eax
f010204e:	89 fa                	mov    %edi,%edx
f0102050:	83 c4 1c             	add    $0x1c,%esp
f0102053:	5b                   	pop    %ebx
f0102054:	5e                   	pop    %esi
f0102055:	5f                   	pop    %edi
f0102056:	5d                   	pop    %ebp
f0102057:	c3                   	ret    
f0102058:	90                   	nop
f0102059:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102060:	89 d8                	mov    %ebx,%eax
f0102062:	f7 f7                	div    %edi
f0102064:	31 ff                	xor    %edi,%edi
f0102066:	89 c3                	mov    %eax,%ebx
f0102068:	89 d8                	mov    %ebx,%eax
f010206a:	89 fa                	mov    %edi,%edx
f010206c:	83 c4 1c             	add    $0x1c,%esp
f010206f:	5b                   	pop    %ebx
f0102070:	5e                   	pop    %esi
f0102071:	5f                   	pop    %edi
f0102072:	5d                   	pop    %ebp
f0102073:	c3                   	ret    
f0102074:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102078:	39 ce                	cmp    %ecx,%esi
f010207a:	72 0c                	jb     f0102088 <__udivdi3+0x118>
f010207c:	31 db                	xor    %ebx,%ebx
f010207e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102082:	0f 87 34 ff ff ff    	ja     f0101fbc <__udivdi3+0x4c>
f0102088:	bb 01 00 00 00       	mov    $0x1,%ebx
f010208d:	e9 2a ff ff ff       	jmp    f0101fbc <__udivdi3+0x4c>
f0102092:	66 90                	xchg   %ax,%ax
f0102094:	66 90                	xchg   %ax,%ax
f0102096:	66 90                	xchg   %ax,%ax
f0102098:	66 90                	xchg   %ax,%ax
f010209a:	66 90                	xchg   %ax,%ax
f010209c:	66 90                	xchg   %ax,%ax
f010209e:	66 90                	xchg   %ax,%ax

f01020a0 <__umoddi3>:
f01020a0:	55                   	push   %ebp
f01020a1:	57                   	push   %edi
f01020a2:	56                   	push   %esi
f01020a3:	53                   	push   %ebx
f01020a4:	83 ec 1c             	sub    $0x1c,%esp
f01020a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01020ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01020af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01020b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01020b7:	85 d2                	test   %edx,%edx
f01020b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01020bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01020c1:	89 f3                	mov    %esi,%ebx
f01020c3:	89 3c 24             	mov    %edi,(%esp)
f01020c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020ca:	75 1c                	jne    f01020e8 <__umoddi3+0x48>
f01020cc:	39 f7                	cmp    %esi,%edi
f01020ce:	76 50                	jbe    f0102120 <__umoddi3+0x80>
f01020d0:	89 c8                	mov    %ecx,%eax
f01020d2:	89 f2                	mov    %esi,%edx
f01020d4:	f7 f7                	div    %edi
f01020d6:	89 d0                	mov    %edx,%eax
f01020d8:	31 d2                	xor    %edx,%edx
f01020da:	83 c4 1c             	add    $0x1c,%esp
f01020dd:	5b                   	pop    %ebx
f01020de:	5e                   	pop    %esi
f01020df:	5f                   	pop    %edi
f01020e0:	5d                   	pop    %ebp
f01020e1:	c3                   	ret    
f01020e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01020e8:	39 f2                	cmp    %esi,%edx
f01020ea:	89 d0                	mov    %edx,%eax
f01020ec:	77 52                	ja     f0102140 <__umoddi3+0xa0>
f01020ee:	0f bd ea             	bsr    %edx,%ebp
f01020f1:	83 f5 1f             	xor    $0x1f,%ebp
f01020f4:	75 5a                	jne    f0102150 <__umoddi3+0xb0>
f01020f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01020fa:	0f 82 e0 00 00 00    	jb     f01021e0 <__umoddi3+0x140>
f0102100:	39 0c 24             	cmp    %ecx,(%esp)
f0102103:	0f 86 d7 00 00 00    	jbe    f01021e0 <__umoddi3+0x140>
f0102109:	8b 44 24 08          	mov    0x8(%esp),%eax
f010210d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102111:	83 c4 1c             	add    $0x1c,%esp
f0102114:	5b                   	pop    %ebx
f0102115:	5e                   	pop    %esi
f0102116:	5f                   	pop    %edi
f0102117:	5d                   	pop    %ebp
f0102118:	c3                   	ret    
f0102119:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102120:	85 ff                	test   %edi,%edi
f0102122:	89 fd                	mov    %edi,%ebp
f0102124:	75 0b                	jne    f0102131 <__umoddi3+0x91>
f0102126:	b8 01 00 00 00       	mov    $0x1,%eax
f010212b:	31 d2                	xor    %edx,%edx
f010212d:	f7 f7                	div    %edi
f010212f:	89 c5                	mov    %eax,%ebp
f0102131:	89 f0                	mov    %esi,%eax
f0102133:	31 d2                	xor    %edx,%edx
f0102135:	f7 f5                	div    %ebp
f0102137:	89 c8                	mov    %ecx,%eax
f0102139:	f7 f5                	div    %ebp
f010213b:	89 d0                	mov    %edx,%eax
f010213d:	eb 99                	jmp    f01020d8 <__umoddi3+0x38>
f010213f:	90                   	nop
f0102140:	89 c8                	mov    %ecx,%eax
f0102142:	89 f2                	mov    %esi,%edx
f0102144:	83 c4 1c             	add    $0x1c,%esp
f0102147:	5b                   	pop    %ebx
f0102148:	5e                   	pop    %esi
f0102149:	5f                   	pop    %edi
f010214a:	5d                   	pop    %ebp
f010214b:	c3                   	ret    
f010214c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102150:	8b 34 24             	mov    (%esp),%esi
f0102153:	bf 20 00 00 00       	mov    $0x20,%edi
f0102158:	89 e9                	mov    %ebp,%ecx
f010215a:	29 ef                	sub    %ebp,%edi
f010215c:	d3 e0                	shl    %cl,%eax
f010215e:	89 f9                	mov    %edi,%ecx
f0102160:	89 f2                	mov    %esi,%edx
f0102162:	d3 ea                	shr    %cl,%edx
f0102164:	89 e9                	mov    %ebp,%ecx
f0102166:	09 c2                	or     %eax,%edx
f0102168:	89 d8                	mov    %ebx,%eax
f010216a:	89 14 24             	mov    %edx,(%esp)
f010216d:	89 f2                	mov    %esi,%edx
f010216f:	d3 e2                	shl    %cl,%edx
f0102171:	89 f9                	mov    %edi,%ecx
f0102173:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102177:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010217b:	d3 e8                	shr    %cl,%eax
f010217d:	89 e9                	mov    %ebp,%ecx
f010217f:	89 c6                	mov    %eax,%esi
f0102181:	d3 e3                	shl    %cl,%ebx
f0102183:	89 f9                	mov    %edi,%ecx
f0102185:	89 d0                	mov    %edx,%eax
f0102187:	d3 e8                	shr    %cl,%eax
f0102189:	89 e9                	mov    %ebp,%ecx
f010218b:	09 d8                	or     %ebx,%eax
f010218d:	89 d3                	mov    %edx,%ebx
f010218f:	89 f2                	mov    %esi,%edx
f0102191:	f7 34 24             	divl   (%esp)
f0102194:	89 d6                	mov    %edx,%esi
f0102196:	d3 e3                	shl    %cl,%ebx
f0102198:	f7 64 24 04          	mull   0x4(%esp)
f010219c:	39 d6                	cmp    %edx,%esi
f010219e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01021a2:	89 d1                	mov    %edx,%ecx
f01021a4:	89 c3                	mov    %eax,%ebx
f01021a6:	72 08                	jb     f01021b0 <__umoddi3+0x110>
f01021a8:	75 11                	jne    f01021bb <__umoddi3+0x11b>
f01021aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01021ae:	73 0b                	jae    f01021bb <__umoddi3+0x11b>
f01021b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01021b4:	1b 14 24             	sbb    (%esp),%edx
f01021b7:	89 d1                	mov    %edx,%ecx
f01021b9:	89 c3                	mov    %eax,%ebx
f01021bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01021bf:	29 da                	sub    %ebx,%edx
f01021c1:	19 ce                	sbb    %ecx,%esi
f01021c3:	89 f9                	mov    %edi,%ecx
f01021c5:	89 f0                	mov    %esi,%eax
f01021c7:	d3 e0                	shl    %cl,%eax
f01021c9:	89 e9                	mov    %ebp,%ecx
f01021cb:	d3 ea                	shr    %cl,%edx
f01021cd:	89 e9                	mov    %ebp,%ecx
f01021cf:	d3 ee                	shr    %cl,%esi
f01021d1:	09 d0                	or     %edx,%eax
f01021d3:	89 f2                	mov    %esi,%edx
f01021d5:	83 c4 1c             	add    $0x1c,%esp
f01021d8:	5b                   	pop    %ebx
f01021d9:	5e                   	pop    %esi
f01021da:	5f                   	pop    %edi
f01021db:	5d                   	pop    %ebp
f01021dc:	c3                   	ret    
f01021dd:	8d 76 00             	lea    0x0(%esi),%esi
f01021e0:	29 f9                	sub    %edi,%ecx
f01021e2:	19 d6                	sbb    %edx,%esi
f01021e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01021ec:	e9 18 ff ff ff       	jmp    f0102109 <__umoddi3+0x69>
