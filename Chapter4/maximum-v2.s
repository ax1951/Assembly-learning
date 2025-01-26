#PURPOSE: This program finds the maximum number of a set of data items.

#VARIABLES: The registers have the following uses:

# data_items - contains the item data. A 0 is used to terminate the data

.section .data

data_items1:
    .long 3,67,34,27,45,75,54,34,44,33,22,11,0

data_items2:
    .long 24,91,1,18,57,33,26,99,0

data_items3:
    .long 61,3,9,7,25,34,40,0

.section .text

.type findMaximum, @function
.globl _start
_start:
    movl $data_items1, %ecx
    call findMaximum

    movl $data_items2, %ecx
    call findMaximum

    movl $data_items3, %ecx
    call findMaximum

    movl $1, %eax        #1 is the exit() syscall
    int $0x80

# return maximum value in %ebx
# %eax stores the current value
# %ecx stores the current data address
findMaximum:
    pushl %ebp
    movl %esp, %ebp

    movl $0, %ebx
findLoop:
    movl (%ecx), %eax
    cmpl $0, %eax
    je endMaximum

    addl $4, %ecx
    cmpl %eax, %ebx
    jge findLoop

    movl %eax, %ebx
    jmp findLoop

endMaximum:
    movl %esp, %ebp
    popl %ebp
    ret
