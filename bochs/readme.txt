基本调试指令
s : 单步执行
b/vb : 断点设置
c : 继续执行
r : 查看寄存器
sreg : 查看段寄存器
xp /nuf addr： 查看内存
    n:内存单元数，默认为1
    u:表示单元大小，默认为w
        b:1byte
	h:2bytes
	w:4bytes
	g:8bytes
    f:显示格式，默认为x
        x:16进制显示
	d:10进制显示
