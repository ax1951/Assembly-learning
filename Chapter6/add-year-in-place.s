.include "linux.s"
.include "record-def.s"

.section .data
input_file_name:
    .ascii "my-records.dat\0"
lseek_error_msg:
    .ascii "Failed to lseek, cannot write records back to the file.\n\0"

.section .bss
.lcomm record_buffer, RECORD_SIZE

#Stack offsets of local variables 
.equ ST_IN_OUT_DESCRIPTOR, -4
.equ ST_WRITE_POSITION, -8

.section .text
.globl _start
_start:
    #Copy stack pointer and make room for local variables
    movl %esp, %ebp
    subl $8, %esp

    #Open file for reading and writing
    movl $SYS_OPEN, %eax
    movl $input_file_name, %ebx
    movl $O_RDWR, %ecx
    movl $0666, %edx
    int $LINUX_SYSCALL

    movl %eax, ST_IN_OUT_DESCRIPTOR(%ebp)
    movl $0, ST_WRITE_POSITION(%ebp)

loop_begin:
    pushl ST_IN_OUT_DESCRIPTOR(%ebp)
    pushl $record_buffer
    call read_record
    addl $8, %esp

    #Returns the number of bytes read.
    #If it isn't the same number we
    #requested, then it's either an
    #end-of-file, or an error, so we're
    #quitting
    cmpl $RECORD_SIZE, %eax
    jne loop_end 

    #increment the age 
    incl record_buffer + RECORD_AGE

    #lseek to write ST_WRITE_POSITION
    movl $SYS_LSEEK, %eax
    movl ST_IN_OUT_DESCRIPTOR(%ebp), %ebx
    movl ST_WRITE_POSITION(%ebp), %ecx
    #Uncomment below line to trigger an error
    #movl $-1, %ecx
    movl $SEEK_SET, %edx
    int $LINUX_SYSCALL

    cmpl $0, %eax
    jl error_handling

    #Write the record out
    pushl ST_IN_OUT_DESCRIPTOR(%ebp)
    pushl $record_buffer
    call write_record
    addl $8, %esp

    addl $RECORD_SIZE, ST_WRITE_POSITION(%ebp)

    #lseek to read position 
    movl $SYS_LSEEK, %eax
    movl ST_IN_OUT_DESCRIPTOR(%ebp), %ebx
    movl ST_WRITE_POSITION(%ebp), %ecx
    movl $SEEK_SET, %edx
    int $LINUX_SYSCALL

    cmpl $0, %eax
    jl error_handling

    jmp loop_begin

error_handling:
    #store errno
    pushl %eax

    pushl $lseek_error_msg
    pushl $STDERR
    call write_message
    addl $8, %esp

    popl %eax
    negl %eax
    movl %eax, %ebx
    movl $SYS_EXIT, %eax
    int $LINUX_SYSCALL

loop_end:
    movl $SYS_EXIT, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL
