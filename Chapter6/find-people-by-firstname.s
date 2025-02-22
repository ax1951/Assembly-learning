.include "linux.s"
.include "record-def.s"

.section .data
#Constant data of the records we want to write
#Each text data item is padded to the proper
#length with null (i.e. 0) bytes.

#.rept is used to pad each item. .rept tells
#the assembler to repeat the section between
#.rept and .endr the number of times specified.
#This is used in this program to add extra null
#characters at the end of each field to fill
#it up

record1:
    .ascii "Fredrick\0"
    .rept 31 #Padding to 40 bytes
    .byte 0
    .endr

    .ascii "Bartlett\0"
    .rept 31 #Padding to 40 bytes
    .byte 0
    .endr

    .ascii "4242 S Prairie\nTulsa, OK 55555\0"
    .rept 209 #Padding to 240 bytes
    .byte 0
    .endr

    .long 45

    .ascii "Scrum master\0"
    .rept 27
    .byte 0
    .endr

record2:
    .ascii "Marilyn\0"
    .rept 32 #Padding to 40 bytes
    .byte 0
    .endr

    .ascii "Taylor\0"
    .rept 33 #Padding to 40 bytes
    .byte 0
    .endr

    .ascii "2224 S Johannan St\nChicago, IL 12345\0"
    .rept 203 #Padding to 240 bytes
    .byte 0
    .endr

    .long 29

    .ascii "Principal software engineer\0"
    .rept 12
    .byte 0
    .endr

record3:
    .ascii "Derrick\0"
    .rept 32 #Padding to 40 bytes
    .byte 0
    .endr

    .ascii "McIntire\0"
    .rept 31 #Padding to 40 bytes
    .byte 0
    .endr

    .ascii "500 W Oakland\nSan Diego, CA 54321\0"
    .rept 206 #Padding to 240 bytes
    .byte 0
    .endr

    .long 36

    .ascii "Senior software engineer\0"
    .rept  15
    .byte 0
    .endr

.section .bss
.equ BUFFER_SIZE, 6
.lcomm STRING_BUFFER, BUFFER_SIZE
.lcomm RECORD_ADDRESSES_IN, 12
.lcomm MATCHED_RECORD_ADDRESSES, 12

.section .text
.equ ST_FD, -4
.globl _start
_start:
    #Copy the stack pointer to %ebp
    movl %esp, %ebp
    subl $4, %esp

    movl $STDOUT, ST_FD(%ebp)

    #Initialize RECORD_ADDRESSES array
    movl $RECORD_ADDRESSES, %eax
    movl $record1, (%eax)
    movl $record2, 4(%eax)
    movl $record3, 8(%eax)

    #Read at most 5 chars from STDIN
    movl $SYS_READ, %eax
    movl $STDIN, %ebx
    movl $STRING_BUFFER, %ecx
    movl $BUFFER_SIZE, %edx
    int $LINUX_SYSCALL

    #Handle error
    cmpl $0, %eax
    jle error_handling

    #The last char is '\n',
    #remove it
    decl %eax


    #Write the first record
    pushl ST_FD(%ebp)
    pushl $record1
    call write_record
    addl $8, %esp

error_handling:
    # return errno as program exit code
    negl %eax
    movl %eax, %ebx
    movl $SYS_EXIT, %eax
    int $LINUX_SYSCALL

finish:
    #Exit the program
    movl $SYS_EXIT, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL

#Compare given string against
#all first names of all records, return the
#addresses of matched records

#INPUT:  1. an array of record addresses
#        2. record size
#        3. given string address
#        4. given string address
#        4. an array of record addresses to be written
#OUTPUT: matched record addresses will be written to the
#        3rd argument
#

# stack content
# matched record count
# %ebp
# return address
# first record address(in)
# record size
# string address
# first record address(out)

.equ matched_record_count, -4
.equ record_addr_in, 8
.equ record_size, 12
.equ string_addr, 16
.equ string_size, 20
.equ record_addr_out, 24

.type compare_strings, @function
compare_strings:
    pushl %ebp
    movl %esp, %ebp

    #Allocate space for matched record count
    subl $4, %esp

    movl $0, %edi
    movl $0, matched_record_count(%ebp)

compare_loop_begin:
    cmpl record_size(%ebp), %edi
    je compare_end

    #Push string size - 3rd argument
    pushl string_size(%ebp)

    #Push string address - 2nd argument
    movl string_addr(%ebp), %ebx
    pushl %ebx

    #Push record address - 1st argument
    movl record_addr_in(%ebp), %eax
    leal (%eax,%edi,4), %ecx
    pushl %ecx
    call compare_string 

    cmpl $1, %eax
    je match

    incl %edi
    jmp compare_loop_begin

match:
    #Get current matched record address
    movl record_addr_in(%ebp), %eax
    leal (%eax,%edi,4), %ecx

    #Get output address
    movl record_addr_out(%ebp), %ebx
    movl matched_record_count(%ebp), %eax
    leal (%ebx,%eax,4), %edx
    
    #Save record address
    movl (%ecx), (%edx)

    incl matched_record_count(%ebp)
    incl $edi

    jmp compare_loop_begin

compare_end:
    movl %ebp, %esp
    popl %ebp
    ret

#Compare 2 strings, return 1
#if the 2nd string is a prefix
#of the 1st string.
#return value is stored in %eax

#stack content
# %ebp
# return address
# record address
# string address
# string size
.equ record_addr, 8
.equ str_addr, 12
.equ str_size, 16

.type compare_string, @function
compare_string:
    pushl %ebp
    movl %esp, %ebp

    movl $0, %edi
    movl record_addr(%ebp), %ebx
    movl str_addr(%ebp), %ecx
    movl str_size(%ebp), %edx

cmp_loop_begin:
    cmpl %edx, %edi
    je match

    movb (%ebx,%edi,1), %al
    movb (%ecx,%edi,1), %ah
    cmpb %al, %ah
    jne not_match

    incl %edi
    jmp cmp_loop_begin

not_match:
    movl $0, %eax
    jmp finished

match:
    movl $1, %eax

finished:
    movl %ebp, %esp
    popl %ebp
    ret