#!/bin/bash

# ------------------------------------------------------------------ #

BLUE_COLOR='\033[0;34m'
GREEN_COLOR='\033[0;32m'
YELLOW_COLOR='\033[1;33m'
RESET_COLOR='\033[0m'

# ------------------------------------------------------------------ #

RunCommand()
{
    local message="$1"
    shift

    printf "${YELLOW_COLOR}[ DOING ]${RESET_COLOR} %s\n\t" "$message"
    set -x
    "$@"
    { set +x; } 2>/dev/null
    printf "${GREEN_COLOR}[SUCCESS]${RESET_COLOR} %s\n" "$message"
}

# ------------------------------------------------------------------ #

# stop if error
set -e

# ------------------------------------------------------------------ #

RunCommand "Compiling assembler code printf.s..." \
    nasm -f elf64 -l printf.lst printf.s

RunCommand "Compiling test.cpp" \
    g++ -fPIE -pthread -c test.cpp -o test.o

RunCommand "Linking" \
    g++ -pie -pthread test.o printf.o -lgtest -o test

# ------------------------------------------------------------------ #

# ld -melf_x86_64 --dynamic-linker=/lib64/ld-linux-x86-64.so.2 printf.o -lc -o printf
