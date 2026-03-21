
nasm -f elf64 -l printf.lst printf.s

g++ test.cpp -I googletest/googletest/include -c test.o

g++ test.o printf.o -no-pie googletest/build/lib/libgtest.a -o test

# ld -melf_x86_64 --dynamic-linker=/lib64/ld-linux-x86-64.so.2 printf.o -lc -o printf
