.option norvc
.section .text
.globl _start

_start:
    addi x1, x0, 0
    addi x2, x0, 1
    add  x3, x1, x2
    add  x4, x3, x3

    # Pad the rest of the 512-word instruction memory with NOPs.
    .rept 508
    nop
    .endr
