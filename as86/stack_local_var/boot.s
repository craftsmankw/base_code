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
	call stacl_local_var

stacl_local_var:
	;store local var to stack
	mov ax, [glocal_var1];local_var1
	push ax
	mov bl, [glocal_var2];local_var2
	mov bh, [glocal_var2 + 1];local_var2+1
	push bx
	;get stack addr
	mov bx, sp
	;change 
	seg ss
	add (bx), #1;    local_var2
	seg ss
	add (bx+1), #1;  local_var2 + 1
	seg ss
	add (bx+2), #0x1122;  local_var1
	pop ax
	pop ax
	ret

glocal_var1:
	.word 0xaabb
glocal_var2:
	.byte 1
	.byte 2

.org 510
	.word 0xAA55

