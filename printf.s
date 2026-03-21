global my_printf

section .text

extern printf

;==================================================================

;------------------------------------------------------------------
; Short:   Writes string to stdout
; In:      %1 --> string to write
;          %2 = string length
; Destroy: RAX, RDX, RSI, RDI
;------------------------------------------------------------------

%macro PutStr 2
    ; rax = sys_function_code = 1 = write64()
    mov rax, SYSCALL_CODE_WRITE
    ; rdi = file_descriptor = stdout
    mov rdi, STDOUT_CODE
    ; rsi --> buffer = curr_char = first macro argument
    mov rsi, %1
    ; rdx = string length = second macro argument
    mov rdx, %2

    syscall
%endmacro

;------------------------------------------------------------------
; Short:   Writes one character to stdout
; In:      %1 --> character to write
; Destroy: RAX, RDX, RSI, RDI
;------------------------------------------------------------------

%macro PutChar 1
    ; first arg --> string = curr_char = first macro argument
    ; second arg = string length = 1 char
    PutStr %1, 1
%endmacro

;------------------------------------------------------------------
;
; _start:
;     ; push arguments with cdecl calling convention
;     ; first argument pushed last (LIFO)
;
;     push 256
;     push 16
;     push 256
;     push '4'
;     push Message
;
;     call my_printf
;
; ;------------------------------------
;
;     mov rdi, Message
;     mov rsi, '4'
;     mov rdx, 256
;     mov rcx, 16
;     mov r8, 256
;
;     xor rax, rax
;
;     call printf
;
; ;------------------------------------
;
; ; exit(0)
;     ; rax = 60 = exit()
;     mov rax, SYSCALL_CODE_EXIT
;     ; rdi = return code = 00 = success
;     xor rdi, rdi
;
;     syscall

;------------------<Calling Convention: stdcall>-------------------
; Note:    System V ABI for x86-64
; Short:   -
; Exp:     -
; In:      -
; Out:     -
; Destroy: -
;------------------------------------------------------------------

my_printf:

    ; save call address in r15
    pop r15

    ; push System V ABI arguments in reversed order
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    call cdecl_printf

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    xor rax, rax
    call printf

    ; restore call address
    jmp r15

;-------------------<Calling Convention: cdecl>--------------------
; Short:   My "printf" function realisation
; In:
;------------------------------------------------------------------

cdecl_printf:
    ; restore rbp value in stack
    push rbp
    ; rbp --> stack top
    mov rbp, rsp

    ; skip pushed rbp and call address in stack to get arguments
    add rbp, 8 * 2

    ; rbx --> format string
    mov rbx, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    ; rcx = MAXIMUM_ITERATIONS
    xor rcx, rcx
    dec rcx

;------------------------------------
Next:
    ; if (curr_symbol == end_symbol) --> print
    cmp byte [rbx], END_SYMBOL
    je Done

    ; if (curr_symbol == specifier_symbol)
    cmp byte [rbx], SPEC_SYMBOL_START
    je Specifier

    ; write curr_symbol to stdout
    PutChar rbx

    ; rbx++ --> next char
    inc rbx

    loop Next

Done:
    ; restore rbp value
    pop rbp

    ret

;------------------------------------

Specifier:
    ; skip SPEC_SYMBOL ("%")
    inc rbx

    ; r13 = specifier symbol character
    movzx r13, byte [rbx]
    ; skip specifier symbol character
    inc rbx

    ; if char repeats the SPEC_SYMBOL --> it was escaped
    cmp byte r13b, SPEC_SYMBOL_START
    je ProcessSpecifierWrong

    ; check the jump table bounds
    ; if (char < first specifier) --> wrong
    cmp byte r13b, SPEC_SYMBOL_BIN
    jl ProcessSpecifierWrong

    ; if (char > last specifier) --> wrong
    cmp byte r13b, SPEC_SYMBOL_HEX
    jg ProcessSpecifierWrong
    ; jump to ProcessSpecifier by the letter
    ; - SPEC_SYMBOL_BIN * 8 to get the distance from
    ; SPEC_SYMBOL_BIN character (first specifier)
    ; * 8 as pointers are stored with 8 bytes (64 bit architecture)
    jmp [SpecifiersJumpTable - SPEC_SYMBOL_BIN * 8 + r13 * 8]

;------------------------------------

ProcessSpecifierWrong:
    ; just print the SPEC_SYMBOL_START
    ; if it was escaped or it was the wrong spec
    ; (as default libc print does that)
    PutChar SpecSymbolStart

    loop Next

;------------------------------------

ProcessSpecifierChar:
    ; write "%c" argument (they are stored in stack)
    ; rbp --> char to write
    PutChar rbp
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    dec rcx
    jnz Next

;------------------------------------

ProcessSpecifierString:
    ; r12 --> string to print
    mov r12, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    ; r11 = MAX_LOOP_ITERS
    mov r11, -1

NextPutChar:
    ; if (char == END_SYMBOL) --> done
    cmp byte [r12], END_SYMBOL
    je ProcessStringDone

    ; else --> PutChar
    PutChar r12
    ; go to the next char
    inc r12

    dec r11
    jnz NextPutChar

ProcessStringDone:

    dec rcx
    jnz Next

;------------------------------------

ProcessSpecifierDec:
    ; rax = argument integer
    mov rax, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    call ConvertDecimalToAscii

    dec rcx
    jnz Next

;------------------------------------

ProcessSpecifierHex:
    ; 2**4 = 16 -- degree of hex num system
    mov r12, 4

    jmp ConvertPowerOfTwoToAscii

;------------------------------------

ProcessSpecifierOct:
    ; 2**3 = 8 -- degree of oct num system
    mov r12, 3

    jmp ConvertPowerOfTwoToAscii

;------------------------------------

ProcessSpecifierBin:
    ; 2**1 = 2 -- degree of bin num system
    mov r12, 1

    ; fallthrough

;------------------------------------

ConvertPowerOfTwoToAscii:
    ; r10 = argument integer
    mov r10, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    call PrintConvertedPowerOfTwoToAscii

    dec rcx
    jnz Next

;------------------------------------------------------------------
; Short:   Writes in stdout value converted to desired numerical system
; In:      R10 = integer value
;          R12 = log_2(numerical system degree)
; Destroy: R10, R11
;------------------------------------------------------------------

PrintConvertedPowerOfTwoToAscii:
    push rcx

    ; get r14 = mask for getting lowest part of number
    ; (hex:0x0F, oct:0x08, bin:0x01)
    mov rcx, r12
    ; r14 = 1
    mov r14, 1
    ; r14 = 2 ** cl
    shl r14, cl
    ; r14 = 2 ** cl - 1
    dec r14

    ; r13 used for indexing buffer
    mov r13, INT_BUFFER_SIZE - 1

.NextByte:
    ; copy to r11
    mov r11, r10

    ; get lowest byte
    and r11, r14

    cmp r11, 10
    jge .Letter

    add r11, '0'

    jmp .DoneConvert

.Letter:
    add r11, 'a' - 10

.DoneConvert:
    ; store char in IntBuffer in reversed order
    mov byte [IntBuffer + r13], r11b
    ; go to storing next char (r13--)
    dec r13

    ; in r12 is degree of 2 of numerical system degree
    mov rcx, r12
    ; move to the next byte
    shr r10, cl

    cmp r10, 0
    jne .NextByte

    ; r13 --> start of buffer str
    add r13, IntBuffer + 1

    ; string length = end buffer ptr - start buffer ptr
    mov rcx, IntBuffer + INT_BUFFER_SIZE
    sub rcx, r13

    ; when ended --> print buffer
    PutStr r13, rcx

    pop rcx

    ret

;------------------------------------------------------------------
; Short:   -
; Exp:     -
; In:      -
; Out:     -
; Destroy: -
;------------------------------------------------------------------

ConvertDecimalToAscii:

    ; check int sign
    cmp rax, 0
    jge .DoneWithSign

    ; if negative --> print '-' and convert to positive
    ; print '-'
    PutChar MinusSign

    ; convert to positive
    neg rax

.DoneWithSign:

    ; r14 will be used for indexing buffer
    mov r14, IntBuffer

    ; r13 = MAX_LOOP_ITERS
    mov r13, -1

.NextDigit:

    ; if (number == 0) --> end
    cmp rax, 0
    jle .Done

    ; r11 = divisor = 10
    mov r11, 10

    ; div divides rax by argument:
    ; r11 = divisor = 10
    ; div is putting
    ; rax = quotient
    ; rdx = dividend = 0
    xor rdx, rdx
    div r11
    ; so, rax //= 10
    ; rdx = next digit to put

    ; convert digit to ascii
    add rdx, '0'

    ; store char in IntBuffer in reversed order
    mov byte [r14], dl

    ; go to storing next char (r14++)
    inc r14

    dec r13
    jnz .NextDigit

.Done:

.PrintNext:
    ; print int buffer from the end
    ; go to last digit
    dec r14

    cmp r14, IntBuffer
    jl .DonePrinting

    PutChar r14

    jmp .PrintNext

.DonePrinting:

    ret

;==================================================================

section .data
;------------------------------------------------------------------

SYSCALL_CODE_WRITE  equ 1
SYSCALL_CODE_EXIT   equ 60
STDOUT_CODE         equ 0x01

END_SYMBOL          equ 0x00
SPEC_SYMBOL_START   equ '%'
SPEC_SYMBOL_CHAR    equ 'c'
SPEC_SYMBOL_HEX     equ 'x'
SPEC_SYMBOL_OCT     equ 'o'
SPEC_SYMBOL_BIN     equ 'b'
SPEC_SYMBOL_DEC     equ 'd'
SPEC_SYMBOL_STR     equ 's'

MinusSign           db '-'
SpecSymbolStart     db '%'

SpecifiersJumpTable dq ProcessSpecifierBin      ; 'b'
                    dq ProcessSpecifierChar     ; 'c'
                    dq ProcessSpecifierDec      ; 'd'
                    dq ProcessSpecifierWrong    ; 'e'
                    dq ProcessSpecifierWrong    ; 'f'
                    dq ProcessSpecifierWrong    ; 'g'
                    dq ProcessSpecifierWrong    ; 'h'
                    dq ProcessSpecifierWrong    ; 'j'
                    dq ProcessSpecifierWrong    ; 'i'
                    dq ProcessSpecifierWrong    ; 'k'
                    dq ProcessSpecifierWrong    ; 'l'
                    dq ProcessSpecifierWrong    ; 'm'
                    dq ProcessSpecifierWrong    ; 'n'
                    dq ProcessSpecifierOct      ; 'o'
                    dq ProcessSpecifierHex      ; 'p'
                    dq ProcessSpecifierWrong    ; 'q'
                    dq ProcessSpecifierWrong    ; 'r'
                    dq ProcessSpecifierString   ; 's'
                    dq ProcessSpecifierWrong    ; 't'
                    dq ProcessSpecifierWrong    ; 'u'
                    dq ProcessSpecifierWrong    ; 'v'
                    dq ProcessSpecifierWrong    ; 'w'
                    dq ProcessSpecifierHex      ; 'x'

DigitBuffer         db '0'

IntBuffer           times 64 db 0x00
INT_BUFFER_SIZE     equ $ - IntBuffer

;------------------------------------------------------------------
; LF                  equ 0x0a
; Message             db  "darova zaebal, ya syel %c sobak; hex 52 = %p; oct 16 = %o; bin 256 = %b", LF, 0x00
; MessageLen          equ $ - Message
; BUFFER_SIZE         equ 2048
; Buffer              times BUFFER_SIZE db 0
;
; ; write(Buffer)
; ;------------------------------------
;     ; r11 = number of characters in buffer that were filled
;     ; it exists to not write all buffer in stdout if we don't need to
;
;     ; rax = sys_function_code = 1 = write64()
;     mov rax, SYSCALL_WRITE_CODE
;     ; rdi = file_descriptor = stdout
;     mov rdi, STDOUT_CODE
;     ; rsi --> buffer
;     mov rsi, Buffer
;     ; r11 = string length
;     mov rdx, r11
;
;     syscall
; ;------------------------------------
