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
	call i1300_reset_floppy_disk

;~~~~~~~~~~~~      int 0x13      ~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~      AH = 0x00      ~~~~~~~~~~~~~~~~~~~~~~~
;desc: reset disk system
;input: dl
;  00H ~ 7FH: floppy disk
;  80H ~ FFH: hard disk
;output:
;  cf = 0,ah = 0   ;success
;  cf != 0, ah = status number

;;;;;;;;;;;;;;      reset_disk      ;;;;;;;;;;;;;;
;reset_floppy_disk
;input
;  dl = b13_driver_num, global
;output
;  i1300rsp
i1300_reset_floppy_disk:
	xor ah, ah
	mov dl, [b13_driver_num]
	int 0x13
	mov [i1300rsp], ah
	ret
;output
i1300rsp:
	.byte 0; 

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
