# 把硬盘中剩下的也放到内存来
- 访问内存：
    1. 如何访问数据的数据段
    2. 如何访问代码的代码段
    3. 如何访问栈的栈顶指针

## Code

### 1
```
load_setup:
    mov dx,#0x0000      ; drive 0, head 0
    mov cx,#0x0002      ; sector 2, track 0
    mov bx,#0x0200      ; address = 512, in 0x9000
    mov ax,#0x0200+4    ; service 2, nr of sectors
    int 0x13            ; read it
    jnc ok_load_setup   ; ok - continue
    mov dx,#0x0000
    mov ax,#0x0000      ; reset the diskette
    int 0x13
    jmp load_setup

ok_load_setup:
    ...
```
- int指令：发起中断，指令之前的几条指令对寄存器的赋值都是作为这个中断程序的参数。
    - 中断发起后，CPU会通过中断号，去寻找对应的中断处理程序的入口地址，并跳转过去执行，逻辑上就相当于执行了一个函数
    - 0x13中断处理程序是BIOS预留函数，是读取磁盘的相关功能函数
- 总的来说就是，从硬盘的第2个扇区开始，把数据加载到内存0x90200处，共加载4个扇区

### 2
- 如果复制成功跳转到ok_load_setup标签，失败则在load_setup函数中一直循环
```
ok_load_setup:
    ...
    mov ax,#0x1000
    mov es,ax       ; segment of 0x10000
    call read_it
    ...
    jmpi 0,0x9020
```
主要代码作用是把从硬盘第6个扇区开始往后的240个扇区，加载到内存0x10000处，类似之前从硬盘中挪到内存，至此，整个操作系统的全部代码就已经全部从硬盘中被搬迁到内存中了。
最后通过段间跳转指令 jmpi 跳转到0x9020处，就是硬盘第二个扇区开始处的内容

## 整个操作系统编译过程
> 通过Makefile和build.c配合完成

1. 把 bootsect.s 编译成 bootsect 放在硬盘的 1 扇区。
2. 把 setup.s 编译成 setup 放在硬盘的 2~5 扇区。
3. 把剩下的全部代码（head.s 作为开头）编译成 system 放在硬盘的随后 240 个扇区。

## 强耦合性
