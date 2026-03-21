global my_printf

section .text

;==================================================================
;------------------------------------------------------------------
; Short:   Safely puts char in buffer
; Exp:     PrintfBuffer --> buffer
;          r8 = PrintBuffer current length
; In:      %1 = ascii code of a symbol to put
;          (BYTE REGISTER | IMM)
; Out:     r8++ (for putting new char) | r8 = 0 if buffer flushed
; Destroy: RAX, RCX, RDX, RDI, RSI, R11
;------------------------------------------------------------------

%macro PutCharInBuffer 1
    ; put char at PrintfBuffer + current buffer length (r8)
    mov byte [PrintfBuffer + r8], %1
    ; buffer length++
    inc r8
    ; check for buffer length
    cmp r8, PRINTF_BUFFER_SIZE
    ; if there is space left in buffer --> Done
    jl %%Done
    ; else --> Flush the Buffer
    call FlushBuffer
%%Done:

%endmacro

;------------------------------------------------------------------
; Short:   Safely puts string in buffer
; Exp:     PrintfBuffer --> buffer
;          r8 = PrintBuffer current length
; In:      r13 --> string
;          r12 = string length
; Out:     r8 += string length (for putting the string)
;       || r8 = 0 if buffer flushed
; Destroy: RAX, RCX, RDX, RDI, RSI, R11, R12, R13
;------------------------------------------------------------------

PutStrInBuffer:
    ; if length == 0 --> done
    cmp r12, 0
    je .Done

.Next:
    mov r11, [r13]
    ; print current char in buffer
    PutCharInBuffer r11b
    ; go to next char (string_ptr++)
    inc r13
    ; string_length--
    dec r12
    ; if (string_length == 0) --> quit
    jnz .Next

.Done:
    ret

;------------------------------------------------------------------
; Short:   Writes the current state of the printf buffer in stdout
; In:      r8 = number of characters in buffer that were filled
;          (it exists to not write all buffer in stdout if we don't need to)
; Destroy: RAX, RCX, RDX, RDI, RSI, R11
;------------------------------------------------------------------

FlushBuffer:
    ; rax = sys_function_code = 1 = write64()
    mov rax, SYSCALL_CODE_WRITE
    ; rdi = file_descriptor = stdout
    mov rdi, STDOUT_CODE
    ; rsi --> printf buffer
    mov rsi, PrintfBuffer
    ; r11 = current buffer length
    mov rdx, r8

    syscall

    ; set current buffer length = 0
    xor r8, r8

    ret

;------------------------------------------------------------------
; Short:   Count string length (till the '\0' terminator)
; In:      r13 --> string
; Out:     r12 = string length
; Destroy: r13
;------------------------------------------------------------------

StrLen:
    ; r12 = iterator
    mov r12, MAX_ITERS_COUNT

.Next:
    ; if NULL terminator --> end
    cmp byte [r13], 0
    je .Done

    ; go to next symbol
    inc r13
    ; decrease counter
    dec r12

    cmp r12, 0
    jne .Next

.Done:
    ; r12 = MAX_ITERS_COUNT - length
    ; string length = -r12 + MAX_ITERS_COUNT
    neg r12
    add r12, MAX_ITERS_COUNT

    ret

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

;------------------<Calling Convention: stdcall>-------------------
; Short:   My analog to libC printf function.
;          This is a trampoline to cdecl_printf,
;          where the actual function is
; Out:     -
; Destroy: -
; Note:    calling convention: System V ABI for x86-64
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

    ; xor rax, rax
    ; call printf

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

    ; r8 = current buffer length
    ; (it can be > 0 if it is not the first printf call in program)
    mov r8, [CurrentPrintfBufferLength]

    ; rcx = MAXIMUM_ITERATIONS
    xor rcx, rcx
    dec rcx

    ; r8 = current print buffer length = 0
    xor r8, r8

    ; r9 = 0 will be used for storing current char
    xor r9, r9

;------------------------------------
Next:
    ; r9 = current char
    mov byte r9b, [rbx]
    ; if (curr_symbol == end_symbol) --> print
    cmp byte r9b, END_SYMBOL
    je Done

    ; if (curr_symbol == specifier_symbol)
    cmp byte r9b, SPEC_SYMBOL_START
    je Specifier

    ; write curr_symbol to stdout
    PutCharInBuffer r9b

    ; rbx++ --> next char
    inc rbx

    loop Next

Done:
    ; flush buffer in stdout
    call FlushBuffer

    ; at the end we have to store the buffer length in
    ; memory for future calls
    mov r8, [CurrentPrintfBufferLength]

    ; restore rbp value
    pop rbp

    ret

;------------------------------------

Specifier:
    ; skip SPEC_SYMBOL ("%")
    inc rbx

    ; r9b = specifier symbol character
    mov r9b, byte [rbx]
    ; skip specifier symbol character
    inc rbx

    ; if char repeats the SPEC_SYMBOL --> it was escaped
    cmp byte r9b, SPEC_SYMBOL_START
    je ProcessSpecifierWrong

    ; check the jump table bounds
    ; if (char < first specifier) --> wrong
    cmp byte r9b, SPEC_SYMBOL_BIN
    jl ProcessSpecifierWrong

    ; if (char > last specifier) --> wrong
    cmp byte r9b, SPEC_SYMBOL_HEX
    jg ProcessSpecifierWrong
    ; jump to ProcessSpecifier by the letter
    ; - SPEC_SYMBOL_BIN * 8 to get the distance from
    ; SPEC_SYMBOL_BIN character (first specifier)
    ; * 8 as pointers are stored with 8 bytes (64 bit architecture)
    jmp [SpecifiersJumpTable - SPEC_SYMBOL_BIN * 8 + r9 * 8]

;------------------------------------

ProcessSpecifierWrong:
    ; just print the SPEC_SYMBOL_START
    ; if it was escaped or it was the wrong spec
    ; (as default libc print does that)
    PutCharInBuffer SPEC_SYMBOL_START

    loop Next

;------------------------------------

ProcessSpecifierChar:
    ; write "%c" argument (they are stored in stack)

    ; rbp --> char to write
    movzx r11, byte [rbp]
    PutCharInBuffer r11b

    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    dec rcx
    jnz Next

;------------------------------------

ProcessSpecifierString:
    ; r13 --> string to print
    mov r13, [rbp]
    ; r13 --> string
    ; r12 will be string length
    call StrLen
    ; r13 --> string as it was destroyed
    mov r13, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8
    ; compare string length with buffer size
    cmp r12, PRINTF_BUFFER_SIZE
    ; if it is bigger --> print it right to stdout with syscall
    jge .PutStrToStdout
    ; else: store string in buffer
    call PutStrInBuffer

    dec rcx
    jnz Next

.PutStrToStdout:
    ; flush buffer before printing string
    call FlushBuffer
    ; print string
    PutStr r13, r12

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

PrintNullptr:
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    ; if nullptr:
    PutCharInBuffer '('
    PutCharInBuffer 'n'
    PutCharInBuffer 'i'
    PutCharInBuffer 'l'
    PutCharInBuffer ')'

    dec rcx
    jnz Next

;------------------------------------

ProcessSpecifierPointer:
    ; if (ptr == 0) --> output (nil)
    cmp qword [rbp], 0
    je PrintNullptr

    ; with '%p' specifier,
    ; at the start of a hex value there is "0x"
    PutCharInBuffer '0'
    PutCharInBuffer 'x'

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
    mov r12, IntBuffer + INT_BUFFER_SIZE
    sub r12, r13

    ; when ended --> print buffer
    ; r13 --> string
    ; r12 = string length
    call PutStrInBuffer

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
    ; check int for zero
    ; as we can not divide by zero
    cmp eax, 0
    je DecimalIsZero

    ; check int sign for negatives
    cmp eax, 0
    jge .DoneWithSign

    ; if negative --> print '-' and convert to positive
    ; print '-'
    push rax
    PutCharInBuffer '-'
    pop rax

    ; convert integer to positive
    neg eax

.DoneWithSign:
    ; r12 will be used for indexing buffer (from the end)
    mov r12, INT_BUFFER_SIZE - 1
    ; r14 = MAX_LOOP_ITERS
    mov r14, -1

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

    ; store char in IntBuffer from the end (it will be in right order)
    mov byte [IntBuffer + r12], dl
    ; go to storing next char (r12--)
    dec r12

    dec r14
    jnz .NextDigit

.Done:
    ; when ended --> print buffer
    ; r13 --> string = current_char_ptr + 1
    mov r13, r12
    add r13, IntBuffer + 1
    ; string length = int_buffer_end_ptr - current_char_ptr - 1
    ;               = INT_BUFFER_SIZE - 1 - r12
    ;               = - r12 - 1 + INT_BUFFER_SIZE
    neg r12
    add r12, INT_BUFFER_SIZE - 1
    ; put string in buffer as it's size is less than PRINT_BUFFER_SIZE
    call PutStrInBuffer

    ret

DecimalIsZero:
    PutCharInBuffer '0'

    ret

;==================================================================

section .data
;------------------------------------------------------------------

MAX_ITERS_COUNT     equ 16384

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
                    dq ProcessSpecifierPointer  ; 'p'
                    dq ProcessSpecifierWrong    ; 'q'
                    dq ProcessSpecifierWrong    ; 'r'
                    dq ProcessSpecifierString   ; 's'
                    dq ProcessSpecifierWrong    ; 't'
                    dq ProcessSpecifierWrong    ; 'u'
                    dq ProcessSpecifierWrong    ; 'v'
                    dq ProcessSpecifierWrong    ; 'w'
                    dq ProcessSpecifierHex      ; 'x'

INT_BUFFER_SIZE     equ 64
IntBuffer           times INT_BUFFER_SIZE db 0x00

PRINTF_BUFFER_SIZE  equ 2048
PrintfBuffer        times PRINTF_BUFFER_SIZE db 0

; This variable will be used only on entrance to my_printf
; and on exit. During the printf call printf buffer length
; is stored in r8 register for speed. By default it initializes with 0,
; but it will change with my_printf calls.
CurrentPrintfBufferLength db 0
