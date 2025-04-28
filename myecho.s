.equ SYS_write, 1
.equ SYS_exit, 60
.equ STDOUT_FILENO, 1



.global _start
.type _start, @function
_start:
    /* Store argc */
    movq (%rsp), %r12      /* r12 = argc */
    cmp $1, %r12            /* Compare argc to 1 */
    jle done                /* if argc <= 1, exit */

    movq $1, %r13           /* r13 = 1, arg index */

main_loop: /* Main loop */
    /* Get next arg string */
    movq 8(%rsp, %r13, 8), %rsi /* rsi = argv[r13] */
    addq $1, %r13           /* r13++ */

    /* Check if rsi is null ptr */
    testq %rsi, %rsi        /* rsi & rsi */
    je done

    /* Get string length */
    xorq %rdx, %rdx
get_strlen:
    /* Check for null byte */
    cmpb $0, (%rsi, %rdx)
    je get_strlen_done

    /* Increment length count */
    addq $1, %rdx
    jmp get_strlen
    
get_strlen_done:
    /* Inits the register that will store the iterator over the string to 0,
       then calls the capitalize function, to capitalize the string. */
    movq $0, %r11
    call capitalize

    /* syscall: write(rdi, rsi, rdx)
       syscalls destroy rcx and r11
       rax used for return value */

    /* rdi is the file to write to
       rsi is the start address
       rdx is number of bytes to write */
    mov $STDOUT_FILENO, %rdi
    

    /* Neat trick—set the null byte to ' ' since we don't need it */
    /* Check if r13 == argc */
    test %r13, %r12         /* r13 & r12 */
    je write_loop

    movb $' ', (%rsi, %rdx) /* rsi[rdx] = ' ' */
    addq $1, %rdx           /* ++rdx */

    /* Sets the r11 reg to 0 which will be the counter to iterate 
       over the string */
 

write_loop:
    mov $SYS_write, %rax
    syscall

    test %rax, %rax
    jl error                /* rax < 0 -> error, exit */
    leaq (%rsi, %rax), %rsi /* rsi += rax */
    sub %rax, %rdx          /* rdx -= rax */
    jne write_loop          /* rdx != 0 */

jmp main_loop

done:
    /* Print out a single newline */
    mov $SYS_write, %rax
    leaq newline, %rsi
    movq $1, %rdx
    syscall
    test %rax, %rax
    jl error

    movq $SYS_exit, %rax
    xor %rdi, %rdi
    syscall

error:
    movq $SYS_exit, %rax
    movq $1, %rdi
    syscall

capitalize:
    /* Checks if the iterator over the string is less than or equal to
       the length. If so check if its a lowercase, else exit */
    cmpq %rdx, %r11
    jle check_char
    ret

check_char: 
    /* Moves the character in the string at index %r11 to the byte register
       %r9b. */
    movb (%rsi, %r11), %r9b
    
    /* If char - 'a' < 0, char is not a lowercase letter. */
    cmpb $'a', %r9b
    jl not_lowercase

    /* If char - 'z' > 0, char is not a lowercase letter. */
    cmpb $'z', %r9b
    jg not_lowercase

    /* The two checks above ensure that if you get to this point, your char
       was in fact a lowercase letter. So just subtracting 32 from it will
       result in the uppercase version of it. */
    subb $32, %r9b

    /* Finally move the changed character back into it's place in memeory */
    movb %r9b, (%rsi, %r11)

not_lowercase:

    /* Adds one to the string iterator and goes back to the top to check 
       next character */
    addq $1, %r11
    jmp capitalize

newline:
    .byte '\n'


