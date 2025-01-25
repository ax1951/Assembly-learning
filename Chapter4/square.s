.section .data
.section .text

.type square, @function
.globl _start

_start:
    pushl $10
    call square
    addl $4, %esp

    movl $1, %eax
    int $0x80

square:
    pushl %ebp
    movl %esp, %ebp
    movl 8(%ebp), %ebx
    imull %ebx, %ebx
    movl %ebp, %esp
    popl %ebp
    ret

