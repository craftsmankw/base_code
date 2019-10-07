# Makefile for the simple example kernel.
AS86	=as86 -0 -a
LD86	=ld86 -0
AS	=as --32
LD	=ld
LDFLAGS =-m elf_i386 -Ttext 0 -e startup_32 -s -x -M 

all:	Image

Image: boot
	dd bs=32 if=boot of=Image skip=1
	cat Image2 >> Image

boot:	boot.o
	$(LD86) -s -o boot boot.o

boot.o:	boot.s
	$(AS86) -o boot.o boot.s
	#rm -f boot_new.s



clean:
	rm -f Image System.map core boot head *.o system
