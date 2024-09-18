CC = gcc
CFLAGS = -Wall -m32

all: main.o image.o decode128.o code128_table.o
	$(CC) $(CFLAGS) -o program main.o image.o decode128.o code128_table.o

decode128.o: decode128.s
	nasm -f elf32 -o decode128.o decode128.s

code128_table.o: code128_table.asm
	nasm -f elf32 -o code128_table.o code128_table.asm

main.o: main.c
	$(CC) $(CFLAGS) -c -o main.o main.c

image.o: image.c
	$(CC) $(CFLAGS) -c -o image.o image.c

clean:
	rm -f *.o