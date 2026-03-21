
nasm -f elf64 -l printf.lst printf.s

g++ test.cpp -c test.o

g++ -no-pie test.o printf.o -o test

# ld -melf_x86_64 --dynamic-linker=/lib64/ld-linux-x86-64.so.2 printf.o -lc -o printf
