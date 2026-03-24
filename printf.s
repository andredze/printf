; directive "default rel" tells the assembler
; to use RIP-relative addressing by default
; for example: instead of absolute address of "MyPrintfCallAddress"
;              it will put RIP-relative address,
;              which can be written as "rel MyPrintfCallAddress"
;              if this directive is not used
default rel

global my_printf

section .text

extern printf

;==================================================================
;------------------------------------------------------------------
; Short:   Writes string to stdout
; In:      %1 --> string to write
;          %2 = string length
; Destroy: rax, rcx, rsi, r11
;------------------------------------------------------------------

%macro PutStr 2
    ; it's better to save rdx and rdi
    ; we do it because syscall is a really slow operation
    ; because of that we will use this macro rarely
    ; and because of that this push will not change much
    push rdx
    push rdi
    ; add string length to counter of chars, transmitted to stdout
    add r15, %2
    ; rax = sys_function_code = 1 = write64()
    mov rax, SYSCALL_CODE_WRITE
    ; rdi = file_descriptor = stdout
    mov rdi, STDOUT_CODE
    ; rsi --> buffer = curr_char = first macro argument
    mov rsi, %1
    ; rdx = string length = second macro argument
    mov rdx, %2

    syscall

    ; get saved rdi
    pop rdi
    ; get saved rdx
    pop rdx

%endmacro

;------------------------------------------------------------------
; Short:   Safely puts char in buffer
; Exp:     PrintfBuffer --> buffer
;          r8 = PrintBuffer current length
; In:      %1 = ascii code of a symbol to put
;          (BYTE REGISTER | IMM)
; Out:     r8++ (for putting new char) | r8 = 0 if buffer flushed
; Destroy: rax, rcx, rsi, r11
;------------------------------------------------------------------

%macro PutCharInBuffer 1
    ; put char at PrintfBuffer + current buffer length (r8)
    lea rax, [PrintfBuffer]
    mov byte [rax + r8], %1
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
; Destroy: rax, rcx, rsi, r11, r12, r13
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
; Out:     r8 = 0
; Destroy: rax, rcx, rsi, r11
;------------------------------------------------------------------

FlushBuffer:
    ; write buffer in stdout
    ; %1 --> printf buffer
    ; %2 = r8 = current buffer length
    lea r11, [PrintfBuffer]
    PutStr r11, r8

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

;------------------<Calling Convention: stdcall>-------------------
; Short:   My analog to libC printf function.
;          This is a trampoline to cdecl_printf,
;          where the actual function implementation is.
; In:      0) rdi --> format string
;             after that should be the arguments for every specifier
;             of the format string in such order (each specifier = 1 argument)
;          1)  rsi
;          2)  rdx
;          3)  rcx
;          4)  r8
;          5)  r9
;          6+) pushed in stack in reversed order
;
;          floats are transferred in xmm registers in right order:
;          0-7) xmm0 - xmm7
;             if there are more, they are put in stack in reversed order
;             as any other type of arguments
;
; Destroy: rax, rbx, r10, r11, r12, r13, r14, r15
; Note:    used System V ABI for x86-64
;------------------------------------------------------------------

my_printf:
    ; save call address in r15
    pop r15

    ; make a trampoline for my __cdecl printf
    ; push 6 register arguments in reversed order
    ; so that the first argument will be pop'ed first
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    ; "push" all xmm registers in stack
    ; allocate 8 bytes for every xmm register (* 8 registers)
    ; 8 bytes as we only need the lowest 8 bytes of every xmm
    sub rsp, 8 * 8

    ; there is no command push for xmm registers,
    ; so we have to move them right to stack
    ; movsd = move doubleword, which
    ; allows us to mov xmm register even so it is 16 bytes long
    movsd [rsp + 8 * 0], xmm0
    movsd [rsp + 8 * 1], xmm1
    movsd [rsp + 8 * 2], xmm2
    movsd [rsp + 8 * 3], xmm3
    movsd [rsp + 8 * 4], xmm4
    movsd [rsp + 8 * 5], xmm5
    movsd [rsp + 8 * 6], xmm6
    movsd [rsp + 8 * 7], xmm7

    ; save call address in memory
    mov [MyPrintfCallAddress], r15

    call cdecl_printf

    ; restore the stack after pushing xmm's
    add rsp, 8 * 8

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    ; save return value in rax as we have to store rax = 0
    ; for calling libC printf
    mov [MyPrintfReturnValue], rax

    ; libC printf expects rax set to number of floats
    ; rax = r14 (count of float's parsed from xmm registers)
    mov rax, r14
    ; wrt ..plt stands for with reference to procedure linkage table (plt)
    ; within the plt there is code to jump to offsets contained in the GOT
    ; GOT = global offset table
    call printf wrt ..plt

    ; get my_printf return value
    mov rax, [MyPrintfReturnValue]

    ; we have ruined the stack, so we can not ret
    ; we saved return address in r15 so we can jump to it
    jmp [MyPrintfCallAddress]

;-------------------<Calling Convention: cdecl>--------------------
; Short:   My "printf" function realisation with cdecl calling convention
; In:      all arguments should be pushed from stack:
;          first 8 bytes must be float values (garbage if there is no argument)
;          after that:
;          [9 byte] --> format string
;          after that in stack should be the arguments for every specifier
;          of the format string (each specifier = 1 argument)
;          in reversed order (first argument has to be pushed last and so on)
; Out:     rax = number of characters transmitted to stdout
;          r14 = number of float arguments transmitted
;                through xmm registers in my_printf call
; Destroy: rax, rbx, rcx, rdx, rdi, rsi, r8, r9, r10, r11, r12, r13, r14
;------------------------------------------------------------------

cdecl_printf:
    ; restore rbp value in stack
    push rbp
    ; rbp --> stack top
    mov rbp, rsp
    ; skip pushed rbp and call address in stack to get float arguments (xmm regs)
    add rbp, 8 * 2
    ; rdx will be used for indexing floats
    mov rdx, rbp
    ; skip pushed xmm regs in stack to get normal arguments
    add rbp, 8 * 8
    ; rbx --> format string
    mov rbx, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8
    ; rcx = MAXIMUM_ITERATIONS
    mov rcx, MAX_ITERS_COUNT
    ; r8 = current print buffer length = 0
    xor r8, r8
    ; r9 = 0 will be used for storing current char
    xor r9, r9
    ; r14 = 0 will be used for counting floats used
    xor r14, r14
    ; r15 = 0 (r15 equals to characters transmitted to stdout)
    ; it will be a return value for my_printf
    xor r15, r15

Next:
    ; r9 = current char
    mov byte r9b, [rbx]
    ; if (curr_symbol == end_symbol) --> print
    cmp byte r9b, END_SYMBOL
    je Done
    ; if (curr_symbol == specifier_symbol)
    cmp byte r9b, SPEC_SYMBOL_START
    je ParseSpecifier
    ; write curr_symbol to stdout
    PutCharInBuffer r9b
    ; rbx++ --> next char
    inc rbx

    loop Next

Done:
    ; flush buffer in stdout
    call FlushBuffer
    ; restore rbp value
    pop rbp
    ; if successfully executed
    ; set return value in rax = r15 (chars transmitted to stdout)
    mov rax, r15

    ret

;------------------------------------------------------------------
; Parses one specifier in the format string
;------------------------------------------------------------------

ParseSpecifier:
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
    lea r11, [SpecifiersJumpTable]
    jmp [r11 - SPEC_SYMBOL_BIN * 8 + r9 * 8]

;------------------------------------------------------------------
; Processes case when the wrong character after "%" was given
;------------------------------------------------------------------

ProcessSpecifierWrong:
    ; just print the SPEC_SYMBOL_START
    ; if it was escaped or it was the wrong spec
    ; (as default libc print does that some times)
    PutCharInBuffer SPEC_SYMBOL_START

    dec cx
    jnz Next

;------------------------------------------------------------------
; Processes case of a specifier "%c" that is putting a char from an argument
;------------------------------------------------------------------

ProcessSpecifierChar:
    ; write "%c" argument (arguments are stored in stack)
    ; rbp --> char to write
    movzx r11, byte [rbp]
    PutCharInBuffer r11b
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    dec rcx
    jnz Next

;------------------------------------------------------------------
; Processes case of a specifier "%s" that is putting a string from an argument.
; If the string is very long, it flushes the buffer and writes the string.
; In other cases, it will be stored in buffer as other symbols are
;------------------------------------------------------------------

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

;------------------------------------------------------------------
; Processes case of a specifier "%d" that prints
; a decimal integer from an argument (can be signed).
;------------------------------------------------------------------

ProcessSpecifierDec:
    ; rax = argument integer
    mov rax, [rbp]
    ; rbp --> expected next argument (may not be any args)
    add rbp, 8

    ; save rdx as we need it for indexing float arguments
    push rdx
    call PrintDecimal
    pop rdx

    dec rcx
    jnz Next

;------------------------------------------------------------------
; Series of processing cases of specifiers "%p", "%x", "%o", "%b".
; they are similar as they all print an integer in the
; numerical system degree of which is a power of two.
;   "%p" === specifier for a pointer
;            (hexadecimal number with "0x" at the start)
;            will write "(nil)" if pointer equals to zero
;   "%x" === specifier for a hexadecimal number
;   "%o" === specifier for an octal number
;   "%b" === specifier for a binary number
;------------------------------------------------------------------
;------------------------------------------------------------------
; Processes case of a null pointer
;------------------------------------------------------------------
ProcessNullptr:
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

;------------------------------------------------------------------
; Processes case of a specifier "%p" that prints a pointer argument
;------------------------------------------------------------------

ProcessSpecifierPointer:
    ; if (ptr == 0) --> output (nil)
    cmp qword [rbp], 0
    je ProcessNullptr

    ; with '%p' specifier,
    ; at the start of a hex value there is "0x"
    PutCharInBuffer '0'
    PutCharInBuffer 'x'

    ; fallthrough

;------------------------------------------------------------------
; Processes case of a specifier "%x" that prints a hexadecimal number argument
;------------------------------------------------------------------

ProcessSpecifierHex:
    ; 2**4 = 16 -- degree of hex num system
    mov r12, 4

    jmp ConvertPowerOfTwoToAscii

;------------------------------------------------------------------
; Processes case of a specifier "%o" that prints an octal number
;------------------------------------------------------------------

ProcessSpecifierOct:
    ; 2**3 = 8 -- degree of oct num system
    mov r12, 3

    jmp ConvertPowerOfTwoToAscii

;------------------------------------------------------------------
; Processes case of a specifier "%b" that prints a binary number
;------------------------------------------------------------------

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

    ; have to save rcx for loop
    push rcx
    ; save rdx as we need it for indexing float arguments
    push rdx
    call PrintNumberInPowerOfTwoSystem
    pop rdx
    pop rcx

    dec rcx
    jnz Next

;------------------------------------------------------------------
; Processes case of a specifier "%f"
; that prints a float from an argument (can be signed).
;------------------------------------------------------------------

ProcessSpecifierFloat:
    ; get next float argument (r14 = counter of floats)
    cmp r14, 8
    jl .LessThan8FloatsWereParsed
    ; else --> get as a normal argument from rbp
    movsd xmm8, [rbp]
    ; set rbp ready for getting next argument
    add rbp, 8
    jmp .GotFloat

.LessThan8FloatsWereParsed:
    ; if less than 8 args were used, they are indexed with rdx
    movsd xmm8, [rdx]
    ; set rdx ready for getting next float value
    add rdx, 8
    ; count of floats++
    inc r14

.GotFloat:
    ; check for NaN and Infinity:
    ; save float in rax
    movq rax, xmm8
    ; save float in rdi
    mov rdi, rax
    ; double values are stored like that:
    ;    63    62             52 51         0
    ; [ sign ][    exponent     ][   frac   ]
    ;
    ; if exponent is all 1s --> it is a special value (nan or inf)
    ;   if frac is all 0s   --> its +inf or -inf (depends on sign bit)
    ;   if frac != 0        --> its nan
    ; compare exponent with special exp
    ; exponents bits would be all 1s
    ; so if we take negative they will be all 0s
    not rdi
    ; extract only the exponent bits
    ; (set other bits to zero)
    and rdi, [SPECIAL_FLOAT_EXPONENT_MASK]
    ; if the result is zero --> than we have a special value
    cmp rdi, 0
    je PrintFloatSpecial

    ; else --> we have a normal float
    call PrintFloatSign

    push rdx
    call PrintPositiveFloat
    pop rdx

    dec rcx
    jnz Next

PrintFloatSpecial:
    ; count zeros to the first bit that equals 1
    ; rdi = amount of zeros in the start of xmm8
    tzcnt rdi, rax
    ; if the fractal part is all zeros
    cmp rdi, 52
    ; than it is infinity
    je .PrintInfinity

    ; else it is nan
    PutCharInBuffer 'n'
    PutCharInBuffer 'a'
    PutCharInBuffer 'n'

    dec rcx
    jnz Next

.PrintInfinity:
    ; print the sign as inf can be signed
    call PrintFloatSign

    ; print the "inf" string
    PutCharInBuffer 'i'
    PutCharInBuffer 'n'
    PutCharInBuffer 'f'

    dec rcx
    jnz Next

;------------------------------------------------------------------
; Short:   Converts float to abs(float) + prints a sign in PrintfBuffer
; In:      xmm8 = float value
; Out:     xmm8 = abs(xmm8)
; Destroy: rax
;------------------------------------------------------------------

PrintFloatSign:
    ; get mask for signed bits of packed doubles of float arg in rax
    movmskpd rax, xmm8
    ; bit for our float value should be in 0 bit, so apply the mask
    and rax, 0x01
    ; if positive or zero
    cmp rax, 0
    jne .Negative
    ; if positive or zero than do nothing
    ret
    ; else if negative
.Negative:
    ; print minus sign
    PutCharInBuffer '-'
    ; convert xmm8 to it's negative
    movq rax, xmm8
    ; set sign bit to 0 --> positive
    btr rax, 63
    ; save in xmm8
    movq xmm8, rax

    ret

;------------------------------------------------------------------
; Short:   Prints a float value in ASCII in PrintfBuffer
;          with precision = PRECISION
; Exp:     float value >= 0
; In:      xmm8 = float value
; Destroy: rax, rcx, rdx, rdi, rsi, r11, r12, r13, xmm8, xmm9
;------------------------------------------------------------------

PrintPositiveFloat:
    ; save xmm8 in xmm9 to later get floating part
    movsd xmm9, xmm8

    ; convert float value to integer with no rounding (get the integer part)
    ; (with double precision)
    cvttsd2si rax, xmm8
    ; print the integer part
    ; save rdx as we need it for indexing float arguments
    push rax
    call PrintDecimal
    ; print point
    PutCharInBuffer '.'

    pop rax
    ; convert integer part back to xmm
    cvtsi2sd xmm8, rax
    ; xmm9 = fractal part
    ; subtract from number it's integer part to get the fractal part
    subsd xmm9, xmm8
    ; get the fractal part to integer part
    mulsd xmm9, [FLOAT_TEN_TO_POWER_FIVE]
    ; convert xmm9 fractal part to integer register
    cvtsd2si rax, xmm9
    ; we should print every float with precision = 6
    ; so if fractal part is zero --> we have to put .000000
    cmp rax, 0
    je .PrintZeroFractalPart
    ; print the fractal part
    call PrintDecimal

    ret

; zero fractal part is an exception
; because when we multiply by zero it remains zero
; however we need to put PRECISION amount of characters
.PrintZeroFractalPart:
    ; put zeros exactly PRECISION times
    mov rdi, PRECISION

.Next:
    ; print ASCII zero
    PutCharInBuffer '0'

    dec rdi
    jnz .Next

    ret

;------------------------------------------------------------------
; Short:   Writes in printf buffer value converted to desired numerical system
;          DEGREE OF NUMERICAL SYSTEM SHOULD BE A POWER OF 2
; In:      r10 = integer value
;          r12 = log_2(numerical system degree)
; Example: if hex numerical system ==> degree = 16 = 2**4 ==> r12 = 4
; Destroy: rax, rcx, rdx, rdi, rsi, r10, r11, r12, r13
;------------------------------------------------------------------

PrintNumberInPowerOfTwoSystem:
    ; get rdi = mask for getting lowest part of number
    ; (hex:0x0F, oct:0x08, bin:0x01)
    mov rcx, r12
    ; rdi = 1
    mov rdi, 1
    ; rdi = 2 ** cl
    shl rdi, cl
    ; rdi = 2 ** cl - 1
    dec rdi
    ; r13 used for indexing buffer
    mov r13, INT_BUFFER_SIZE - 1

.NextByte:
    ; copy to r11
    mov r11, r10
    ; get lowest byte
    and r11, rdi

    cmp r11, 0x0a
    ; if (r11 >= 0x0a) --> convert letter
    jge .Letter
    ; convert to ascii if digit --> add '0' to a number
    add r11, '0'
    ; skip converting letter
    jmp .DoneConvert
.Letter:
    ; convert to ascii if letter --> add 'a' to a number but - 10 as ('a' = 10)
    add r11, 'a' - 10
.DoneConvert:
    ; store char in IntBuffer in reversed order
    lea r12, [IntBuffer]
    mov byte [r12 + r13], r11b
    ; go to storing next char (r13--)
    dec r13
    ; move to the next byte
    shr r10, cl
    ; if not zero --> continue
    cmp r10, 0
    jne .NextByte
    ; r13 --> start of buffer str
    lea r10, [IntBuffer]
    add r13, r10
    inc r13
    ; string length = end buffer ptr - start buffer ptr
    mov r12, r10
    add r12, INT_BUFFER_SIZE
    sub r12, r13
    ; when ended --> print buffer
    ; r13 --> string
    ; r12 = string length
    call PutStrInBuffer

    ret

;------------------------------------------------------------------
; Short:   Writes in printf buffer value in decimal numerical system
; In:      rax = integer value
; Destroy: rax, rcx, rdx, rdi, rsi, r11, r12, r13
;------------------------------------------------------------------

PrintDecimal:
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
    ; rdi = MAX_ITERS_COUNT
    mov rdi, MAX_ITERS_COUNT

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
    lea r13, [IntBuffer]
    mov byte [r13 + r12], dl
    ; go to storing next char (r12--)
    dec r12

    dec rdi
    jnz .NextDigit

.Done:
    ; when ended --> print buffer
    ; r13 --> string = current_char_ptr (IntBuffer + r12) + 1
    lea r13, [IntBuffer]
    add r13, r12
    inc r13
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

;==================================================================

; This variable is used to store my_printf return value
; as it will be replaced by libC printf return value after it's call
MyPrintfReturnValue   dq 0

; This variable is used to store my_printf call address
; it is used to return from my_printf after executing cdecl_printf
MyPrintfCallAddress   dq 0

; That is buffer for storing ASCII symbols of integers
; in ProcessSpecifier for hex, oct, bin and dec
INT_BUFFER_SIZE     equ 64
IntBuffer           times INT_BUFFER_SIZE db 0x00

; That is buffer for my_printf output
; it is made to do less syscalls
; Buffer allows to make syscall only when it filled
; it is done with the FlushBuffer function
PRINTF_BUFFER_SIZE  equ 2048
PrintfBuffer        times PRINTF_BUFFER_SIZE db 0

;==================================================================

section .rodata

;==================================================================

; constant for comparing float with inf and nan
; infinity will do the job because it sets all exponent bits to 1,
; and frac bits to 0. It is positive so sign bit is also 0
; float infinity has the special token
SPECIAL_FLOAT_EXPONENT_MASK dq __?Infinity?__
; used for converting fractal part of a float to an integer
FLOAT_TEN_TO_POWER_FIVE dq 10e+5
; precision for printing floats
PRECISION           equ 6
; constant for maximum iterations in loops
MAX_ITERS_COUNT     equ 16384

SYSCALL_CODE_WRITE  equ 1
SYSCALL_CODE_EXIT   equ 60

STDOUT_CODE         equ 0x01

; strings are NULL terminated
END_SYMBOL          equ 0x00

; start of any specifier
SPEC_SYMBOL_START   equ '%'
; first possible specifier
SPEC_SYMBOL_BIN     equ 'b'
; last possible specifier
SPEC_SYMBOL_HEX     equ 'x'

; It is a jump table for handling different specifiers in my_printf function
; It uses ASCII code of a specifier for indexing
SpecifiersJumpTable dq ProcessSpecifierBin      ; 'b'
                    dq ProcessSpecifierChar     ; 'c'
                    dq ProcessSpecifierDec      ; 'd'
                    dq ProcessSpecifierWrong    ; 'e'
                    dq ProcessSpecifierFloat    ; 'f'
                    times 'o'-'g' dq ProcessSpecifierWrong ; from 'g' to 'n'
                    dq ProcessSpecifierOct      ; 'o'
                    dq ProcessSpecifierPointer  ; 'p'
                    times 's'-'q' dq ProcessSpecifierWrong ; from 'q' to 'r'
                    dq ProcessSpecifierString   ; 's'
                    times 'x'-'t' dq ProcessSpecifierWrong ; from 't' to 'w'
                    dq ProcessSpecifierHex      ; 'x'

;==================================================================
