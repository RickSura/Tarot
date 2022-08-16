# 段寄存器历史包袱
模式转换——16位实模式转变为32位的保护模式
## 模式转换
```
lidt  idt_48      ; load idt with 0,0
lgdt  gdt_48      ; load gdt with whatever appropriate

idt_48:
    .word   0     ; idt limit=0
    .word   0,0   ; idt base=0L
```
- 实模式下CPU计算物理地址：段基左移四位加上偏移地址
- 保护模式下：
    - 段基址被称作段选择子，里面存储着段描述符的索引
    - 通过索引可以从全局描述符表gdt中找到一个段描述符，段描述符里存储着段基址
    - 段基址取出来再和偏移地址相加就得到了物理地址
- gdt由操作系统把这个位置信息存储在一个叫gdtr的寄存器中——`lgdt gdt_48`
    - 作用为把后面的值`gdt_48`放在gdtr寄存器中
```
gdt_48:
    .word   0x800       ; gdt limit=2048, 256 GDT entries
    .word   512+gdt,0x9 ; gdt base = 0X9xxxx
```
```
gdt:
    .word   0,0,0,0     ; dummy

    .word   0x07FF      ; 8Mb - limit=2047 (2048*4096=8Mb)
    .word   0x0000      ; base address=0
    .word   0x9A00      ; code read/exec
    .word   0x00C0      ; granularity=4096, 386

    .word   0x07FF      ; 8Mb - limit=2047 (2048*4096=8Mb)
    .word   0x0000      ; base address=0
    .word   0x9200      ; data read/write
    .word   0x00C0      ; granularity=4096, 386
```

目前全局描述符表有三个段描述符，第一个为空，第二个是代码段描述符（type=code），第三个是数据段描述符（type=data），第二个和第三个段描述符的段基址都是 0，也就是之后在逻辑地址转换物理地址的时候，通过段选择子查找到无论是代码段还是数据段，取出的段基址都是 0，那么物理地址将直接等于程序员给出的逻辑地址（准确说是逻辑地址中的偏移地址）。

## 总结
操作系统设置了个全局描述符表 gdt，为后面切换到保护模式后，能去那里寻找到段描述符，然后拼凑成最终的物理地址，就这个作用。
