" 基本配置
filetype on                        " 打开 vim 对基于文件类型的支持
filetype plugin indent on          " 打开 vim 对基于文件类型的插件和缩进
set ai                             " 自动缩进，新行与前面的行保持—致的自动空格
set aw                             " 自动写，转入shell或使用：n编辑其他文件时，当前的缓冲区被写入
set encoding=utf-8                 " Vim内部使用的字符编码方式规定为UTF-8
set ic                             " 在查询及模式匹配时忽赂大小写
set nocompatible                   " Vundle需要，不与vi兼容，采用Vim自己的操作命令
set number                         " 屏幕左边显示行号
set wrap                           " 长行显示自动折行
set scrolloff=5                    " 设定光标离窗口上下边界 5 行时窗口自动滚动
syntax on                          " 自动语法高亮
set mouse=a                        " 使用鼠标
set shiftwidth=4                   " tab缩进4空格
set softtabstop=4                  " 按BackSpace键
