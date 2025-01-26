.section .data

.section .text

.globl _start
_start:
    pushl $5
    call factorial
    addl $4, %esp

    movl $1, %eax
    int $0x80


.type factorial,@function
#Result is stored in %ebx
factorial:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    movl $1, %ebx

loop_start:
    cmpl $1, %eax
    je loop_end

    imull %eax, %ebx
    decl %eax
    jmp loop_start

loop_end:
    movl %ebp, %esp
    popl %ebp
    ret
