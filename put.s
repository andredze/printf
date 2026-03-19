section .text

global _start

_start:
; write(Message)
    ; rax = 1 = write64()
    mov rax, 1
    ; rdi = file_descriptor = stdout
    mov rdi, 0x01
    ; rsi = buffer -> Message
    mov rsi, Message
    ; rdx = string len
    mov rdx, MessageLen

    syscall

    mov rax, 0x3C
    xor rdi, rdi
    syscall

section .data

Msg:    db "darova, zaebal", 0x0a
MsgLen  equ $ - Msg
