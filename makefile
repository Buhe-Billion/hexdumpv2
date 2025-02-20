hexdumpv2: hexdumpv2.o
	ld -o hexdumpv2 hexdumpv2.o
hexdumpv2.o: hexdumpv2.asm
	nasm -f elf64 -g -F dwarf hexdumpv2.asm
