#Common Linux Definitions

#System Call Numbers 
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ SYS_LSEEK, 19
.equ SYS_BRK, 45

#System Call Interrupt Number
.equ LINUX_SYSCALL, 0x80

#Standard File Descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

#Common Status Codes
.equ END_OF_FILE, 0

#Open file mode
.equ O_RDONLY,     0
.equ O_WRONLY,     1
.equ O_RDWR,       2
.equ O_CREAT,   0100
.equ O_TRUNC,  01000
.equ O_APPEND, 02000

#lseek whence
.equ SEEK_SET, 0 
.equ SEEK_CUR, 1
.equ SEEK_END, 2
