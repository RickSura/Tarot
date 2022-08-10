;
.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

SETUPLEN = 4				; nr of setup-sectors
BOOTSEG  = 0x07c0			; original address of boot-sector
INITSEG  = 0x9000			; we move boot here - out of the way
SETUPSEG = 0x9020			; setup starts here
SYSSEG   = 0x1000			; system loaded at 0x10000 (65536).
ENDSEG   = SYSSEG + SYSSIZE		; where to stop loading

ROOT_DEV = 0x306

entry start
start:
	mov	ax,#BOOTSEG		; 
	mov	ds,ax			; 之后访问的数据的内存地址都默认加上0x7c00再去内存中寻址
	mov	ax,#INITSEG		;
	mov	es,ax			;
	mov	cx,#256			;
	sub	si,si			;
	sub	di,di			;
	rep				;
	movw				; 将内存地址 0x7c00 开始往后的512字节数据，原封不动赋值到 0x9000 处 
	jmpi	go,INITSEG		; 跳转到 0x9000+go 内存地址处执行
go:	mov	ax,cs			; go 是一个标签编译成机器码会被翻译成一个值，是该标签在文件内的偏移地址 go 的偏移地址+0x9000就是 mov ax,cs 所在内存地址
	mov	ds,ax			;
	mov	es,ax			; 
; put stack at 0x9ff00.栈顶地址设置为了 0x9FF00
	mov	ss,ax
	mov	sp,#0xFF00		; arbitrary value >>512 sp为0xFF00 目前栈顶地址就是 ss:sp 所指向的地址 0x9FF00

; load the setup-sectors directly after the bootblock.
; Note that 'es' is already set up.

load_setup:
	mov	dx,#0x0000		; drive 0, head 0
	mov	cx,#0x0002		; sector 2, track 0
	mov	bx,#0x0200		; address = 512, in INITSEG
	mov	ax,#0x0200+SETUPLEN	; service 2, nr of sectors
	int	0x13			; read it 发起中断，寻找对应的中断处理程序的入口地址并跳转过去执行 逻辑上就是执行了一个预留的函数 0x13是BIOS预留函数 读取磁盘
	jnc	ok_load_setup		; ok - continue
	mov	dx,#0x0000
	mov	ax,#0x0000		; reset the diskette
	int	0x13
	j	load_setup

ok_load_setup:

; Get disk drive parameters, specifically nr of sectors/track 把从硬盘第6个扇区开始往后的240个扇区加载到内存0x10000处 最后通过段间跳转指令跳转到 0x9020处 硬盘第二个扇区开始的内容

	mov	dl,#0x00
	mov	ax,#0x0800		; AH=8 is get drive parameters
	int	0x13
	mov	ch,#0x00
	seg cs
	mov	sectors,cx
	mov	ax,#INITSEG
	mov	es,ax

; Print some inane message

	mov	ah,#0x03		; read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#24
	mov	bx,#0x0007		; page 0, attribute 7 (normal)
	mov	bp,#msg1
	mov	ax,#0x1301		; write string, move cursor
	int	0x10

; ok, we've written the message, now
; we want to load the system (at 0x10000)

	mov	ax,#SYSSEG
	mov	es,ax		; segment of 0x010000
	call	read_it
	call	kill_motor

; After that we check which root-device to use. If the device is
; defined (!= 0), nothing is done and the given device is used.
; Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
; on the number of sectors that the BIOS reports currently.

	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined
	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		; /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		; /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax

; after that (everyting loaded), we jump to
; the setup-routine loaded directly after
; the bootblock:

	jmpi	0,SETUPSEG
; 之后的我暂时也不知道
; This routine loads the system at address 0x10000, making sure
; no 64kB boundaries are crossed. We try to load it as fast as
; possible, loading whole tracks whenever we can.
;
; in:	es - starting address segment (normally 0x1000)
;
sread:	.word 1+SETUPLEN	; sectors read of current track
head:	.word 0			; current head
track:	.word 0			; current track

read_it:
	mov ax,es
	test ax,#0x0fff
die:	jne die			; es must be at 64kB boundary
	xor bx,bx		; bx is starting address within segment
rp_read:
	mov ax,es
	cmp ax,#ENDSEG		; have we loaded all yet?
	jb ok1_read
	ret
ok1_read:
	seg cs
	mov ax,sectors
	sub ax,sread
	mov cx,ax
	shl cx,#9
	add cx,bx
	jnc ok2_read
	je ok2_read
	xor ax,ax
	sub ax,bx
	shr ax,#9
ok2_read:
	call read_track
	mov cx,ax
	add ax,sread
	seg cs
	cmp ax,sectors
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

read_track:
	push ax
	push bx
	push cx
	push dx
	mov dx,track
	mov cx,sread
	inc cx
	mov ch,dl
	mov dx,head
	mov dh,dl
	mov dl,#0
	and dx,#0x0100
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

/*
 * This procedure turns off the floppy drive motor, so
 * that we enter the kernel in a known state, and
 * don't have to worry about it later.
 */
kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
