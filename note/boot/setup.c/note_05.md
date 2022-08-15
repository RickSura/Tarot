# 进入保护模式之前移动内存

```
start:
    mov ax,#0x9000  ; this is done in bootsect already, but...
    mov ds,ax
    mov ah,#0x03    ; read cursor pos
    xor bh,bh
    int 0x10        ; save it in known place, con_init fetches
    mov [0],dx      ; it from 0x90000.
```

- `int 0x10`：BIOS提供的显示服务，`ah`寄存器被赋值为`0x03`表示显示服务里具体的读取光标位置功能
- 在这之后，`dx`表示光标位置，高八位行号，低八位列号

## 中间代码——存储在内存中的信息是什么在什么位置

内存地址	长度(字节)	名称
0x90000		2	光标位置
0x90002		2	扩展内存数
0x90004		2	显示页面
0x90006		1	显示模式
0x90007		1	字符列数
0x90008		2	未知
0x9000A		1	显示内存
0x9000B		1	显示状态
0x9000C		2	显卡特性参数
0x9000E		1	屏幕行数
0x9000F		1	屏幕列数
0x90080		16	硬盘1参数表
0x90090		16	硬盘2参数表
0x901FC		2	根设备号

## 接下来
`cli`：关闭中断，后面要把BIOS写好的中断向量表覆盖掉
```
; first we move the system to it's rightful place
    mov ax,#0x0000
    cld         ; 'direction'=0, movs moves forward
do_move:
    mov es,ax       ; destination segment
    add ax,#0x1000
    cmp ax,#0x9000
    jz  end_move
    mov ds,ax       ; source segment
    sub di,di
    sub si,si
    mov cx,#0x8000
    rep movsw
    jmp do_move
; then we load the segment descriptors
end_move:
    ...
```
- `rep movsw`：内存复制

## 总结
- 栈顶：`0x9FF00`
- `0x9000`往上是一些临时存放的变量
- `0x90200`往上是`setup`程序代码
- `0`到`0x80000`这512K被`system`模块占用，这个模块是除了`bootsect`和`setup`之外的全部程序链接在一起的结果，称之为“操作系统的全部”

