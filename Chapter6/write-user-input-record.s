.include "linux.s"
.include "record-def.s"

.section .data
#This is the name of the file we will write to
file_name:
    .ascii "test.dat\0"

.section .bss
.lcomm INPUT_BUFFER, RECORD_SIZE
.lcomm OUTPUT_BUFFER, RECORD_SIZE
.lcomm FIELD_SIZE, 16

.section .text
.equ ST_FILE_DESCRIPTOR, -4
.equ ST_FIELD_INDEX, -8
.equ ST_WRITE_POS, -12

.equ DEFAULT_AGE, 27

.globl _start
_start:
    #Copy the stack pointer to %ebp
    movl %esp, %ebp

    #Allocate space to hold
    #the file descriptor,
    #the record field index(0,1,2,3),
    #the write position
    subl $12, %esp

    #Open the file for writing
    movl $SYS_OPEN, %eax
    movl $file_name, %ebx
    movl $0101, %ecx #This says to create if it
                     #doesn't exist, and open for
                     #writing
    movl $0666, %edx
    int $LINUX_SYSCALL

    #Store the file descriptor away
    movl %eax, ST_FILE_DESCRIPTOR(%ebp)

    cmpl $0, %eax
    jle error_handling

    movl $FIELD_SIZE, %eax
    movl $40, (%eax)   #first name size
    movl $40, 4(%eax)  #last name size
    movl $240, 8(%eax) #address size
    movl $40, 12(%eax) #title size

    movl $0, ST_FIELD_INDEX(%ebp)
    movl $0, ST_WRITE_POS(%ebp)

read_loop_begin:
    cmpl $4, ST_FIELD_INDEX(%ebp)
    je read_done

    #Read user input
    movl $SYS_READ, %eax
    movl $STDIN, %ebx
    movl $INPUT_BUFFER, %ecx
    movl $RECORD_SIZE, %edx
    int $LINUX_SYSCALL

    #copy input buffer to output buffer
    pushl %eax                      #number of bytes 
    pushl $INPUT_BUFFER             #src buffer
    movl ST_WRITE_POS(%ebp), %edi
    leal OUTPUT_BUFFER(%edi), %edx  #dst buffer with write position
    pushl %edx
    call memcpy

    popl %edx
    addl $4, %esp
    popl %eax

    #Get current field size
    movl ST_FIELD_INDEX(%ebp), %ebx
    movl FIELD_SIZE(,%ebx,4), %ecx

    #no of zeroes = Field total size - field real size
    subl %eax, %ecx
    pushl %ecx                   #no of zeroes

    #We have written %eax chars
    #Update write position
    addl %eax, %edx
    pushl %edx                   #output buffer address
    call writeZeroesToBuffer
    addl $8, %esp

prepare_next_loop:
    movl ST_FIELD_INDEX(%ebp), %ebx
    movl FIELD_SIZE(,%ebx,4), %ecx
    addl %ecx, ST_WRITE_POS(%ebp)
    incl ST_FIELD_INDEX(%ebp)

    cmpl $3, ST_FIELD_INDEX(%ebp)
    je add_age
    jmp read_loop_begin

add_age:
    movl ST_WRITE_POS(%ebp), %edi
    leal OUTPUT_BUFFER(%edi), %edx
    movl $DEFAULT_AGE, (%edx)
    addl $4, ST_WRITE_POS(%ebp)
    jmp read_loop_begin

read_done:
    #Write the record
    movl ST_FILE_DESCRIPTOR(%ebp), %eax
    pushl %eax
    pushl $OUTPUT_BUFFER
    call write_record
    addl $8, %esp

    #Close the file descriptor
    movl $SYS_CLOSE, %eax
    movl ST_FILE_DESCRIPTOR(%ebp), %ebx
    int $LINUX_SYSCALL
    jmp normal_end

error_handling:
    # return errno as program exit code
    negl %eax
    movl %eax, %ebx
    movl $SYS_EXIT, %eax
    int $LINUX_SYSCALL

normal_end:
    #Exit the program
    movl $SYS_EXIT, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL


#Copy bytes from src buffer to dst buffer
#The first argument is the dst buffer address
#The second argument is the src buffer address
#The thrid argument is the number of bytes to be copied
.equ ST_DST_BUFFER, 8
.equ ST_SRC_BUFFER, 12
.equ ST_NO_OF_BYTES, 16
.type memcpy, @function
memcpy:
    pushl %ebp
    movl %esp, %ebp

    movl $0, %edi
    movl ST_DST_BUFFER(%ebp), %eax
    movl ST_SRC_BUFFER(%ebp), %ebx
    movl ST_NO_OF_BYTES(%ebp), %edx

copy_loop:
    cmpl %edi, %edx
    je copy_done

    movb (%ebx), %cl
    movb %cl, (%eax)
    incl %ebx
    incl %eax
    incl %edi
    jmp copy_loop

copy_done:
    popl %ebp
    ret


#Write designated number of zeros to a buffer
#The first argument is the buffer address,
#the second argument is number of zeroes
.equ ST_BUFFER_ADDR, 8
.equ ST_NO_ZEROES, 12

.type writeZeroesToBuffer, @function
writeZeroesToBuffer:
    pushl %ebp
    movl %esp, %ebp

    movl ST_BUFFER_ADDR(%ebp), %eax
    movl ST_NO_ZEROES(%ebp), %ebx
    movl $0, %edi

loop_begin:
    cmpl %edi, %ebx
    je loop_end

    movb $0, (%eax)
    incl %eax
    incl %edi
    jmp loop_begin

loop_end:
    popl %ebp
    ret

