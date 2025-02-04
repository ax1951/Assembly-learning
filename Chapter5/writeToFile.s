# PURPOSE: write a string to a file
.section .data
FILENAME:
.ascii "heynow.txt\0"

STRING:
.ascii "Hey diddle diddle!\0"

.section .bss
.equ BUFFER_SIZE, 50
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text

# process:
#     1. create the output file
#     2. store the file descriptor
#     3. read the string into a buffer
#     4. write the buffer to the file
#     5. close the file
#     6. exit

# linux open file flags
# https://man7.org/linux/man-pages/man2/open.2.html
# O_RDONLY   00
# O_WRONLY   01
# O_RDWR     02
# O_CREAT    0100
# O_EXCL     0200
# O_TRUNC    01000
# O_APPEND   02000
# O_NONBLOCK 04000
# O_SYNC     04010000

# constants
.equ SYS_EXIT, 1
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ LINUX_SYSCALL, 0x80
.equ O_CREATE_WRONLY_TRUNC, 01101

.equ ST_FD_OUT, -4

.globl _start
_start:
    # allocate space for write file descriptor
    movl %esp, %ebp
    subl $4, %esp

    # create the file
    movl $SYS_OPEN, %eax
    movl $FILENAME, %ebx
    movl $O_CREATE_WRONLY_TRUNC, %ecx
    movl $0666, %edx
    int $LINUX_SYSCALL

    # check error code
    cmpl $0, %eax
    jl final

    # store the fd 
    movl %eax, ST_FD_OUT(%ebp)

    # load the string into the buffer
    movl $0, %edi
load_loop:
    movb STRING(,%edi,1), %al
    cmpb $0, %al
    je end_loop

    movb %al, BUFFER_DATA(,%edi,1)
    incl %edi
    jmp load_loop

end_loop:
    # %edi hold the buffer size
    # write the buffer to the file
    movl $SYS_WRITE, %eax
    movl ST_FD_OUT(%ebp), %ebx
    movl $BUFFER_DATA, %ecx
    movl %edi, %edx
    int $LINUX_SYSCALL

    # check return code
    cmpl $0, %eax
    jl final

    # if all good, close the file
    movl $SYS_CLOSE, %eax
    movl ST_FD_OUT(%ebp), %ebx
    int $LINUX_SYSCALL

final:
    # restore the stack
    movl %ebp, %esp

    # exit
    movl %eax, %ebx
    movl $SYS_EXIT, %eax
    int $LINUX_SYSCALL 
