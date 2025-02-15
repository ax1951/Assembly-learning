.include "linux.s"
.globl write_message
.type write_message, @function

.section .text
.equ ST_FILEDES, 8
.equ ST_MESSAGE, 12

write_message:
    pushl %ebp
    movl %esp, %ebp

    #Get the length of the message 
    pushl ST_MESSAGE(%ebp)
    call count_chars
    addl $4, %esp

    movl %eax, %edx
    movl $SYS_WRITE, %eax
    movl ST_FILEDES(%ebp), %ebx
    movl ST_MESSAGE(%ebp), %ecx
    int $LINUX_SYSCALL

    movl %ebp, %esp
    popl %ebp
    ret
    