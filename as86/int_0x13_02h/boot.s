BOOTSEG  = 0x07c0
boot_sp = 0x0500

entry start
start:
	jmpi go, #BOOTSEG;
go:
	;start debug here
	mov ax, #BOOTSEG
	mov ss, ax
	mov ds, ax
	mov ax, #boot_sp
	mov sp, ax
	mov [b13_driver_num], #0x0
	mov [i1302_rd_secs], #1
	movb [i1302_start_sec], #3
	movb [i1302_track_num], #0
	movb [i1302_head_num], #0
	mov [i1302_rd_buff_seg], #0x9000
	mov [i1302_rd_buff_offset], #0
	call i1302_read
	;finish
	mov al, #0

;~~~~~~~~~~~~      int 0x13      ~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~      AH = 0x02      ~~~~~~~~~~~~~~~~~~~~~~~
;input, 输入参数列表
i1302_rd_secs:
	.word 0
i1302_start_sec:
	.byte 0
i1302_track_num:;磁道号,目前只支持1个字节大小
	.byte 0
i1302_head_num:
	.byte 0
i1302_rd_buff_seg:
	.word 0x9000
i1302_rd_buff_offset:
	.word 0x0200

;output, 返回值列表
i1302_rd_rsp:
	.byte 0

;函数开始
i1302_read:
	pusha;  备份所有寄存器

;i1302_chk_params:
	;判断入口参数合法性
	mov al, [b13_track_secs]
	cmp al, [i1302_start_sec]
	jc i1302_read_fail;   磁道最大扇区数 小于 起始扇区数, 非法参数
	mov al, [b13_track_num_max]
	cmp al, [i1302_track_num]
	jc i1302_read_fail;   磁道号大于最大磁道号, 非法参数
	mov al, [b13_head_num_max]
	cmp al, [i1302_head_num]
	jc i1302_read_fail;   磁头号大于最大磁头号, 非法参数
	call i1302_read_all
	popa
	ret
i1302_read_fail:
	mov [i1302_rd_rsp], #1
	popa
	ret

i1302_read_all:;  创建局部变量
	mov al, #0; curr_secs, default zero, 单次读取的扇区数
	;磁道剩余扇区数, 默认为磁道最大扇区数
	; track_rest_secs, rest secs for current track, default is max
	mov ah, [b13_track_secs]
	push ax; 局部变量保存进堆栈

;更新当次需要读取的sector数
i1302_read_start:
	mov ax, [i1302_rd_secs];
	cmp ax, #0
	jz i1302_read_ok;如果需要读取的扇区数为0, 读取完成
	call i1302_read_next
	jmp i1302_read_start
i1302_read_ok:
	mov [i1302_rd_rsp], #0
	pop ax
	ret

i1302_read_next:
	mov al, [b13_track_secs];获取磁道最大扇区数
	add al, #1
	;磁道剩余扇区数 = 磁道最大扇区数 + 1 - 起始扇区数
	sub al, [i1302_start_sec]
	;
	mov bx,sp
	add bx, #2; skip the call stack
	;track_rest_secs
	mov (bx + 1), al; 设置磁道剩余扇区数局部变量
	
	mov ah, #0; 磁道剩余扇区数, 目前只支持1字节大小, 去掉高位跟cx比较
	mov cx, [i1302_rd_secs];取出需要读取的所有扇区数
	cmp cx, ax;    比较 需要读取的扇区数 和 磁道剩余扇区数
	jz i1302_rd_track_rest;   需要读取的扇区数 = 磁道剩余扇区数
	jc i1302_rd_track_rest;   需要读取的扇区数 < 磁道剩余扇区数
	mov (bx), al; 设置本次需要读取的扇区数 = 磁道剩余扇区数
	jmp i1302_chk_offset
i1302_rd_track_rest:
	mov (bx), cl
i1302_chk_offset:
	;计算当前读取的扇区数 是否超出偏移地址
	movb cl, (bx);当前需要读取的扇区数
	xor ch, ch
	shl cx, #9; 左移9位相当于cx * 512
	add cx, [i1302_rd_buff_offset]; 本次需要读的字节数 + 当前地址偏移
	jnc i1302_do_int; 如果加起来没超过64K, 则可以全部读取
	je i1302_do_int; 如果加起来没超过64K, 则可以全部读取
	;如果加起来超过了64K, 则需要重新继续读取的扇区数, 不能超过64K
	xor ax, ax;    清0
	sub ax, [i1302_rd_buff_offset]; 0 - 偏移地址 = 偏移地址的64K的补值
	shr ax, #9;  也就是当前段剩余未写入地址, 右移9位就是 除于 512 = 扇区数
	mov (bx), al;    将扇区数 保存到局部变量
;jmp i1302_do_int
i1302_do_int:
	mov ah, #0x02
	mov al, (bx);    本次读取的扇区数
	mov ch, [i1302_track_num]
	mov cl, [i1302_start_sec]
	and cl, #0x3f; 磁道号,目前只支持1个字节大小
	mov dh, [i1302_head_num]
	mov dl, [b13_driver_num]
	mov es, [i1302_rd_buff_seg]
	mov bx, [i1302_rd_buff_offset]
	int 0x13
	jnc i1302_do_int_ok
;i1302_do_int_fail:
	jmp i1302_do_int;如果失败, 则死循环读取
;
i1302_do_int_ok:;  读取成功,则更新相关参数
	;更新需要读取的扇区数 - 已经读取的扇区数
	xor ah, ah
	sub [i1302_rd_secs], ax
	;扇区数 + 起始扇区号 > 磁道最大扇区数?
	;mov ch, #0; 清空高位数据, cl = 起始扇区号
	;xor ah, ah
	;add cx, ax; 扇区数 + 起始扇区号
	add cl, al; 扇区数 + 起始扇区号
	cmp [b13_track_secs], cl
	jc i1302_rd_track_end;磁道最大扇区数 < 扇区数 + 起始扇区号, 本磁道已经读完

	;磁道最大扇区数 >= 扇区数 + 起始扇区号
	; 更新起始扇区号 = 扇区数 + 当前起始扇区号, 备下次读取
	mov [i1302_start_sec], cl
	jmp i1302_update_seg

;磁道最大扇区数 < 扇区数 + 起始扇区号, 本磁道已经读完
i1302_rd_track_end:
	cmp [i1302_head_num], #0
	jz i1302_zero_head
	;不等于0
	mov [i1302_head_num], #0;磁头号置0
	add [i1302_track_num], #1;磁道号 + 1
	mov [i1302_start_sec], #1;起始扇区数 = 1
	jmp i1302_update_offset

;等于0
i1302_zero_head:
	mov [i1302_head_num], #1;磁头号置1, 磁道号不变
	mov [i1302_start_sec], #1;起始扇区数 = 1
i1302_update_offset:
	xor ah, ah;清除高位
	shl ax, #9
	add [i1302_rd_buff_offset], ax
	jnc i1302_rd_continue;如果小于64K, 则重新计算扇区数,继续读取磁盘数据
	je i1302_update_seg; 如果加起来刚好64K, 则更新段地址
i1302_rd_continue:
	ret
	;如果没超过,则更新偏移地址

i1302_update_seg:
	;段偏移指向下一个64K, 偏移地址清0
	mov ax, [i1302_rd_buff_seg]
	add ah, #0x10;
	mov [i1302_rd_buff_seg], ax
	mov [i1302_rd_buff_offset], #0
	ret;  重新计算扇区数,继续读取磁盘数据


;---------------------------------   base parameters   ------------------------
;b13_driver_num
;  00H ~ 7FH: floppy disk
;  80H ~ FFH: hard disk
b13_driver_num:
	.byte 0
b13_track_num_max:
	.byte 80
b13_head_num_max:
	.byte 1
;sectors for each track, default as 18 for 1.44
b13_track_secs:
	.byte 0x12;18

.org 510
	.word 0xAA55	
