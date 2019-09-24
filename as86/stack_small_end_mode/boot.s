BOOTSEG  = 0x07c0
boot_sp = 0x0500

entry start
start:
	jmpi go, #BOOTSEG;
go:
	;start debug here
	mov ax, #BOOTSEG
	mov ss, ax
	mov ax, #boot_sp
	mov sp, ax
	call push_stack_dbg
push_stack_dbg:
	mov al, #0x11
	mov ah, #0x22
	push ax;sp[0] = 0x11,sp[1] = 0x22
	mov bx, sp
	seg ss
	mov cl, (bx)
	seg ss
	mov ch, (bx+1)
	pop ax
	ret

.org 510
	.word 0xAA55

