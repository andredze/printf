global _start

section .text

;==================================================================

;------------------------------------------------------------------
; Short:   Writes one character to stdout
; In:      %1 --> character to write
; Destroy: RAX, RDX, RSI, RDI
;------------------------------------------------------------------

%macro PutChar 1
    ; rax = sys_function_code = 1 = write64()
    mov rax, SYSCALL_CODE_WRITE
    ; rdi = file_descriptor = stdout
    mov rdi, STDOUT_CODE
    ; rsi --> buffer = curr_char = first macro argument
    mov rsi, %1
    ; rdx = string length = 1 char
    mov rdx, 1

    syscall
%endmacro

;------------------------------------------------------------------

_start:
    ; push arguments with cdecl calling convention
    ; first argument pushed last (LIFO)

    push '4'
    push Message

    call Printf

; exit(0)
    ; rax = 60 = exit()
    mov rax, SYSCALL_CODE_EXIT
    ; rdi = return code = 00 = success
    xor rdi, rdi

    syscall

;-------------------<Calling Convention: cdecl>--------------------
; Short:   My "printf" function realisation
; In:
;------------------------------------------------------------------

Printf:
    ; restore rbp value in stack
    push rbp
    ; rbp --> stack top
    mov rbp, rsp

    ; skip pushed rbp and call address in stack to get arguments
    add rbp, 16

    ; rbx --> format string
    mov rbx, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    ; rcx = MAXIMUM_ITERATIONS
    xor rcx, rcx
    dec rcx

;------------------------------------
.Next:
    ; if (curr_symbol == end_symbol) --> print
    cmp byte [rbx], END_SYMBOL
    je .Done

    ; if (curr_symbol == specifier_symbol)
    cmp byte [rbx], SPEC_SYMBOL
    je .Specifier

    ; write curr_symbol to stdout
    PutChar rbx

    ; rbx++ --> next char
    inc rbx

    loop .Next
    jmp .Done

;------------------------------------

.Specifier:
    ; skip SPEC_SYMBOL ("%")
    inc rbx

; //TODO what to do if string ends on %
    ; if (curr_symbol == end_symbol) --> error (?)
    cmp byte [rbx], END_SYMBOL
    je .Done

    cmp byte [rbx], SPEC_CHAR_SYMBOL
    je .ProcessCharSpecifier

    loop .Next
;------------------------------------

.Done:
    ; restore rbp value
    pop rbp

    ret

;------------------------------------

.ProcessCharSpecifier:
    ; skip CHAR_SPEC_SYMBOL ("c")
    inc rbx
    ; write "%c" argument (they are stored in stack)
    ; rbp --> char to write
    PutChar rbp
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    loop .Next

;==================================================================

section .data
;------------------------------------------------------------------

SYSCALL_CODE_WRITE  equ 1
SYSCALL_CODE_EXIT   equ 60
STDOUT_CODE         equ 0x01

END_SYMBOL          equ 0x00
SPEC_SYMBOL         equ '%'
SPEC_CHAR_SYMBOL    equ 'c'

LF                  equ 0x0a
Message             db  "darova zaebal, ya syel %c sobak", LF, 0x00
MessageLen          equ $ - Message

CharBuffer          db 0x00

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
