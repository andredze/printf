nasm -f elf64 -l printf.lst printf.s
ld -s -o printf printf.o
