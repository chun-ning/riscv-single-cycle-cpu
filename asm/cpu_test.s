.section .text
.globl _start

_start:
    # Test 1: instructions 1-4
    addi x1, x0, 6
    addi x2, x0, 4
    add  x3, x1, x2
    sw   x3, 0(x0)

    # Test 2: instructions 5-8
    addi x1, x1, -3
    lw   x2, 0(x0)
    sub  x3, x2, x1
    sw   x3, 4(x0)

    # Test 3: instructions 9-16
    addi x4, x0, 15
    addi x5, x0, 10
    and  x6, x4, x5
    or   x7, x4, x5
    xor  x8, x4, x5
    sw   x6, 8(x0)
    sw   x7, 12(x0)
    sw   x8, 16(x0)

    # Test 4: instructions 17-24
    addi  x9, x0, 1
    addi  x10, x0, 3
    sll   x11, x9, x10
    slli  x12, x9, 4
    slt   x13, x1, x2
    sltu  x14, x1, x2
    slti  x15, x2, 11
    sltiu x16, x2, 11

    # Test 5: instructions 25-30
    addi  x17, x0, -16
    addi  x18, x0, 2
    srl   x19, x17, x18
    sra   x20, x17, x18
    srli  x21, x17, 3
    srai  x22, x17, 3

    # Test 6: instructions 31-34
    addi x23, x0, 15
    xori x24, x23, 10
    ori  x25, x23, 48
    andi x26, x25, 15

    # Test 7: instructions 35-38
    beq  x23, x23, beq_taken
    addi x23, x0, 1
beq_taken:
    beq  x23, x24, after_beq_not_taken
    addi x23, x0, 1
after_beq_not_taken:
    # Test 8: instructions 39-42
    bne  x23, x24, bne_taken
    addi x27, x0, 2
bne_taken:
    bne  x23, x23, after_bne_not_taken
    addi x27, x0, 1
after_bne_not_taken:
    # Test 9: instructions 43-46
    blt  x17, x18, blt_taken
    addi x28, x0, 2
blt_taken:
    bltu x17, x18, after_bltu_not_taken
    addi x28, x0, 1
after_bltu_not_taken:
    # Test 10: instructions 47-51
    bge  x18, x17, bge_taken
    addi x29, x0, 99
bge_taken:
    bgeu x17, x18, bgeu_taken
    addi x29, x0, 99
bgeu_taken:
    addi x29, x0, 10

    # Test 11: instruction 52
    lui  x30, 0x12345

    # Test 12: instructions 53-55
    jal  x31, jal_target
    addi x30, x0, 99
jal_target:
    addi x5, x0, 12

    # Test 13: instructions 56-59
    addi x6, x0, 232
    jalr x7, 0(x6)
    addi x5, x0, 99
jalr_target:
    addi x5, x0, 13

    # Test 14: instructions 60-74
    addi x9, x0, -1
    addi x10, x0, 1
    slt  x11, x9, x10
    sltu x12, x9, x10
    addi x13, x0, -1
negative_branch_loop:
    addi x13, x13, 1
    blt  x13, x10, negative_branch_loop
    jal  x0, negative_jal
negative_jal_target:
    addi x15, x0, 14
    jal  x0, jalr_base_test
negative_jal:
    jal  x14, negative_jal_target
jalr_base_test:
    addi x16, x0, 288
    jalr x17, 4(x16)
    addi x18, x0, 99
jalr_nonzero_target:
    addi x18, x0, 14

    # Test 15: instructions 75-76
    addi x0, x0, 5
    addi x19, x0, 15

    # Test 16: reset in the middle of execution
    # (in tb_cpu.v)

    # Test 17: unknown/invalid instruction
    # (in tb_cpu.v)

    # NOPs to check if padding is harmless
    # (in tb_cpu.v)
