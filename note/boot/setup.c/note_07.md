# 六行代码进入保护模式
```
mov al,#0xD1        ; command write
out #0x64,al
mov al,#0xDF        ; A20 on
out #0x60,al
```
- 打开A20地址线：为了突破地址信号线20位的宽度变成32位可用。要考虑兼容性必须保持一个只能用20位地址线的模式，所以在此进行手动开启

## 对芯片编程
```
; well, that went ok, I hope. Now we have to reprogram the interrupts :-(
; we put them right after the intel-reserved hardware interrupts, at
; int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
; messed this up with the original PC, and they haven't been able to
; rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
; which is used for the internal hardware interrupts as well. We just
; have to reprogram the 8259's, and it isn't fun.

    mov al,#0x11        ; initialization sequence
    out #0x20,al        ; send it to 8259A-1
    .word   0x00eb,0x00eb       ; jmp $+2, jmp $+2
    out #0xA0,al        ; and to 8259A-2
    .word   0x00eb,0x00eb
    mov al,#0x20        ; start of hardware int's (0x20)
    out #0x21,al
    .word   0x00eb,0x00eb
    mov al,#0x28        ; start of hardware int's 2 (0x28)
    out #0xA1,al
    .word   0x00eb,0x00eb
    mov al,#0x04        ; 8259-1 is master
    out #0x21,al
    .word   0x00eb,0x00eb
    mov al,#0x02        ; 8259-2 is slave
    out #0xA1,al
    .word   0x00eb,0x00eb
    mov al,#0x01        ; 8086 mode for both
    out #0x21,al
    .word   0x00eb,0x00eb
    out #0xA1,al
    .word   0x00eb,0x00eb
    mov al,#0xFF        ; mask off all interrupts for now
    out #0x21,al
    .word   0x00eb,0x00eb
    out #0xA1,al
```
- 这是对可编程中断控制器8259芯片进行编程
- 中断号不能冲突，Intel有保留中断，但是IBM与保留中断发送冲突，所以我们得重新对其进行编程，不得不做但是一点意思没有
- 8259芯片引脚与中断号对应关系——

## 切换模式
```
mov ax,#0x0001  ; protected mode (PE) bit
lmsw ax      ; This is it;
jmpi 0,8     ; jmp offset 0 of segment 8 (cs)
```
- 前两行将`cr0`这个寄存器的位0置1，模式就从实模式切换到保护模式
- 段间跳转：8代表cs（代码段寄存器）的值，0表示偏移地址
- 此时已经是保护模式了，内存寻址方式变了，段寄存器中的值被当作段选择子
    - `gdt`：第 0 项是空值，第一项被表示为代码段描述符，是个可读可执行的段，第二项为数据段描述符，是个可读可写段，不过他们的段基址都是 0。
    - 段基址是 0，偏移也是 0，那加一块就还是 0。跳转到内存地址的 0 地址处，开始执行。就是操作系统全部代码的 system 这个大模块，由 Makefile 文件可知，是由 head.s 和 main.c 以及其余各模块的操作系统代码合并来的，可以理解为操作系统的全部核心代码编译后的结果。

```
tools/system: boot/head.o init/main.o \
    $(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)
    $(LD) $(LDFLAGS) boot/head.o init/main.o \
    $(ARCHIVES) \
    $(DRIVERS) \
    $(MATH) \
    $(LIBS) \
    -o tools/system > System.map
```
