#!/bin/bash

# ------------------------------------------------------------------ #

BLUE_COLOR='\033[0;34m'
GREEN_COLOR='\033[0;32m'
YELLOW_COLOR='\033[1;33m'

RESET_COLOR='\033[0m'

# ------------------------------------------------------------------ #

InFrameStart()
{
    printf "${BLUE_COLOR}[ START ]${RESET_COLOR} %s\n" "$1"
}

InFrameDoing()
{
    printf "${YELLOW_COLOR}[ DOING ]${RESET_COLOR} %s\n" "$1"
}

InFrameSuccess()
{
    printf "${GREEN_COLOR}[SUCCESS]${RESET_COLOR} %s\n" "$1"
}

InFrameDone()
{
    printf "${BLUE_COLOR}[ DONE  ]${RESET_COLOR} %s\n" "$1"
}

# ------------------------------------------------------------------ #

# stop if error
set -e

# ------------------------------------------------------------------ #

InFrameStart "Building test_my_printf"

# ------------------------------------------------------------------ #

InFrameDoing "Compiling assembler code printf.s..."
nasm -f elf64 -l printf.lst printf.s
InFrameSuccess "Compiling assembler code printf.s..."

# ------------------------------------------------------------------ #

InFrameDoing "Compiling test.cpp"
g++ -fPIE -c test.cpp -I googletest/googletest/include -o test.o
InFrameSuccess "Compiling test.cpp"

# ------------------------------------------------------------------ #

InFrameDoing "Linking"
g++ -pie test.o printf.o googletest/build/lib/libgtest.a -o test
InFrameSuccess "Linking"

# ------------------------------------------------------------------ #

InFrameDone "Built test_my_printf"

# ------------------------------------------------------------------ #

# ld -melf_x86_64 --dynamic-linker=/lib64/ld-linux-x86-64.so.2 printf.o -lc -o printf
