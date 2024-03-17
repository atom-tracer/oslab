/* Protected Mode Hello World */
.code16

.global start
start:
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss

	# 关中断
	cli				

	# 启动A20总线
	inb $0x92, %al 
	orb $0x02, %al
	outb %al, $0x92

	# 加载GDTR
	data32 addr32 lgdt gdtDesc # loading gdtr, data32, addr32

	# 设置CR0的PE位为1
	movl %cr0, %eax
	orb $0x1,%al
	movl %eax,%cr0

	# 长跳转切换至保护模式
	data32 ljmp $0x08, $start32 # reload code segment selector and ljmp to start32, data32

.code32
start32:
	movw $0x10, %ax # setting data segment selector
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %ss
	movw $0x18, %ax # setting graphics data segment selector
	movw %ax, %gs
	
	movl $0x8000, %eax # setting esp
	movl %eax, %esp

	# 输出Hello World
    pushl $13 # pushing the size to print into stack
    pushl $message # pushing the address of message into stack
    call displayStr # calling the display function


loop32:
	jmp loop32

message:
	.string "Hello, World!\n\0"

displayStr:
    pushl %ebp
    movl 8(%esp), %ebx # addr of message to ebx
    movl 12(%esp), %ecx # length to ecx
	movl $(80*5*2), %edi #initial coordinate,line 5,times 2 due to 2-byte charinfo
	movb $0x0c, %ah #set display mode
	

printNextChar:
	movb (%ebx),%al # fill the ascii
	movw %ax,%gs:(%edi) #move the 2-byte char info to screen
	addl $2,%edi #next coordinate
	addl $1,%ebx #next char
	decl %ecx
	cmpl $0x0,%ecx
	jne printNextChar
	popl %ebp
	ret

.p2align 2
gdt: # 8 bytes for each table entry, at least 1 entry
	# .word limit[15:0],base[15:0]
	# .byte base[23:16],(0x90|(type)),(0xc0|(limit[19:16])),base[31:24]
	# GDT第一个表项为空
	.word 0,0
	.byte 0,0,0,0

	# code segment entry
	.word 0xffff,0
	.byte 0,0x9a,0xcf,0 #0x9a mean read-only

	# data segment entry
	.word 0xffff,0
	.byte 0,0x92,0xcf,0 #0x92 mean writeable

	# graphics segment entry
	.word 0xffff,0x8000
	.byte 0xb,0x92,0xcf,0 # VGA显存地址0x8000

gdtDesc: 
	.word (gdtDesc - gdt -1) 
	.long gdt 