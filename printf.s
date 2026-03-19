section .text
;------------------------------------------------------------------

global _start

_start:
    mov rdi, Message

    call Printf

; exit(0)
    ; rax = 60 = exit()
    mov rax, 60
    ; rdi = return code = 00 = success
    xor rdi, rdi

    syscall

;-------------------<Calling Convention: cdecl>--------------------
; Short:   My "printf" function realisation
; In:      RDI --> string
;          RSI =
;          RDX =
;------------------------------------------------------------------

Printf:
    push rbp
    mov rbp, rsp

    ; r11 = number of characters copied to buffer
    xor r11, r11

    ; rcx = MAXIMUM_ITERATIONS
    xor rcx, rcx
    dec rcx

    ; rbx --> buffer
    mov rbx, Buffer

;------------------------------------
.Next:
    ; if (curr_symbol == end_symbol) --> print
    cmp byte [rdi], END_SYMBOL
    je .Done

    ; if (curr_symbol == specifier_symbol)
    cmp byte [rdi], SPEC_SYMBOL
    je .Specifier

    ; store 1 char in buffer
    mov r12, [rdi]
    mov [rbx], r12
    inc r11

    ; rdi --> next char
    inc rdi
    ; rbx --> next char in buffer
    inc rbx

    loop .Next
    jmp .Done

;------------------------------------

.Specifier:

    loop .Next
;------------------------------------

.Done:

; write(Buffer)
;------------------------------------
    ; r11 = number of characters in buffer that were filled
    ; it exists to not write all buffer in stdout if we don't need to

    ; rax = sys_function_code = 1 = write64()
    mov rax, SYSCALL_WRITE_CODE
    ; rdi = file_descriptor = stdout
    mov rdi, STDOUT_CODE
    ; rsi --> buffer
    mov rsi, Buffer
    ; r11 = string length
    mov rdx, r11

    syscall
;------------------------------------

    pop rbp

    ret

;------------------------------------------------------------------

section .data
;------------------------------------------------------------------

SYSCALL_WRITE_CODE  equ 0x01
STDOUT_CODE         equ 0x01

BUFFER_SIZE         equ 2048

Buffer              times BUFFER_SIZE db 0

LF                  equ 0x0a

END_SYMBOL          equ 0x00
SPEC_SYMBOL         equ '%'

Message             db  "salam alekum", LF
MessageLen          equ $ - Message

;------------------------------------------------------------------
