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

_start:
    ; push arguments with cdecl calling convention
    ; first argument pushed last (LIFO)

    push 256
    push 16
    push 256
    push '4'
    push Message

    call my_printf

;------------------------------------

    mov rdi, Message
    mov rsi, '4'
    mov rdx, 256
    mov rcx, 16
    mov r8, 256

    xor rax, rax

    call printf

;------------------------------------

; exit(0)
    ; rax = 60 = exit()
    mov rax, SYSCALL_CODE_EXIT
    ; rdi = return code = 00 = success
    xor rdi, rdi

    syscall

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

    ; restore call address
    push r15

    xor rax, rax
    call printf

    ret

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
    cmp byte [rbx], SPEC_SYMBOL
    je Specifier

    ; write curr_symbol to stdout
    PutChar rbx

    ; rbx++ --> next char
    inc rbx

    loop Next
    jmp Done

;------------------------------------

Specifier:
    ; skip SPEC_SYMBOL ("%")
    inc rbx

; //TODO what to do if string ends on %
    movzx r13, byte [rbx]
    sub r13, SPEC_BIN_SYMBOL
    mov r14, [SpecifiersJumpTable + r13 * 8]
    jmp r14

;     cmp byte [rbx], SPEC_CHAR_SYMBOL
;     je .ProcessCharSpecifier
;
;     cmp byte [rbx], SPEC_HEX_SYMBOL
;     je .ProcessHexSpecifier
;
;     cmp byte [rbx], SPEC_OCT_SYMBOL
;     je .ProcessOctSpecifier
;
;     cmp byte [rbx], SPEC_BIN_SYMBOL
;     je .ProcessBinSpecifier

    loop Next
;------------------------------------

Done:
    ; restore rbp value
    pop rbp

    ret

;------------------------------------

ProcessWrongSpecifier:
ProcessCharSpecifier:
    ; skip CHAR_SPEC_SYMBOL ("c")
    inc rbx
    ; write "%c" argument (they are stored in stack)
    ; rbp --> char to write
    PutChar rbp
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    loop Next

;------------------------------------

ProcessHexSpecifier:
    ; 2**4 = 16 -- degree of hex num system
    mov r12, 4

    jmp ConvertInteger

;------------------------------------

ProcessOctSpecifier:
    ; 2**3 = 8 -- degree of oct num system
    mov r12, 3

    jmp ConvertInteger

;------------------------------------

ProcessBinSpecifier:
    ; 2**1 = 2 -- degree of bin num system
    mov r12, 1

    ; fallthrough

;------------------------------------

ConvertInteger:

    ; skip BIN_SPEC_SYMBOL ("b")
    inc rbx
    ; write "%b" argument (they are stored in stack)

    ; r10 = argument (integer) to make bin
    mov r10, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    call PrintConvertedInteger

    dec rcx
    jnz Next

;------------------------------------------------------------------
; Short:   Writes in stdout value converted to desired numerical system
; In:      R10 = integer value
;          R12 = log_2(numerical system degree)
; Destroy: R10, R11
;------------------------------------------------------------------

PrintConvertedInteger:
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
    mov r13, IntBufferSize - 1

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
    mov rcx, IntBuffer + IntBufferSize
    sub rcx, r13

    ; when ended --> print buffer
    PutStr r13, rcx

    pop rcx

    ret

;==================================================================

section .data
;------------------------------------------------------------------

SYSCALL_CODE_WRITE  equ 1
SYSCALL_CODE_EXIT   equ 60
STDOUT_CODE         equ 0x01

END_SYMBOL          equ 0x00
SPEC_SYMBOL         equ '%'
SPEC_CHAR_SYMBOL    equ 'c'
SPEC_HEX_SYMBOL     equ 'x'
SPEC_OCT_SYMBOL     equ 'o'
SPEC_BIN_SYMBOL     equ 'b'
SPEC_DEC_SYMBOL     equ 'd'
SPEC_STR_SYMBOL     equ 's'

SpecifiersJumpTable dq ProcessBinSpecifier      ; 'b'
                    dq ProcessCharSpecifier     ; 'c'
                    ; db ProcessDecSpecifier    ; 'd'
                    dq ProcessWrongSpecifier    ; 'd'
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessOctSpecifier      ; 'o'
                    dq ProcessHexSpecifier      ; 'p'
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier    ; 's'
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessWrongSpecifier
                    dq ProcessHexSpecifier      ; 'x'

LF                  equ 0x0a
Message             db  "darova zaebal, ya syel %c sobak; hex 52 = %p; oct 16 = %o; bin 256 = %b", LF, 0x00
MessageLen          equ $ - Message

IntBuffer           times 64 db 0x00
IntBufferSize       equ $ - IntBuffer

;------------------------------------------------------------------
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
