`timescale 1ns / 1ps

module tb_cpu;
    reg clk = 1'b0;
    reg reset;

    integer errors;

    cpu dut (
        .clk(clk),
        .reset(reset)
    );

    always begin
        #5 clk = ~clk;
    end

    task check;
        input [255:0] test_name;
        input [31:0] actual;
        input [31:0] expected;
        begin
            #1;
            if (actual !== expected) begin
                $display("FAIL: mem/reg=%s expected = %h, got = %h",
                         test_name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: mem/reg=%s got = %h",
                         test_name, actual);
            end
        end
    endtask
    
    wire [31:0] x23_debug;
    assign x23_debug = dut.rf.regs[23];

    initial begin
        $dumpfile("waves/cpu.vcd");
        $dumpvars(0, tb_cpu);

        errors = 0;
        clk = 0;
        reset = 1'b1;

        $display("Starting CPU test...");

        @(posedge clk)
        #1;
        reset = 0;

        // Test 1: instructions 1-4
        /*
         * addi x1, x0, 5
         * addi x2, x0, 4
         * add  x3, x1, x2
         * sw   x3, 0(x0)
        */
        repeat(4) begin
            @(posedge clk);
        end
        #1;

        check("x1", dut.rf.regs[1], 32'd5);
        check("x2", dut.rf.regs[2], 32'd4);
        check("x3", dut.rf.regs[3], 32'd9);
        check("mem[0]", dut.dmem.mem[0], 32'd9);

        // Test 2: instructions 5-8
        /*
         * addi x1, x1, -3
         * lw   x2, 0(x0)
         * sub  x3, x2, x1
         * sw   x3, 4(x0)
        */
        repeat(4) begin
            @(posedge clk);
        end
        #1;

        check("x1", dut.rf.regs[1], 32'd2);
        check("x2", dut.rf.regs[2], 32'd9);
        check("x3", dut.rf.regs[3], 32'd7);
        check("mem[1]", dut.dmem.mem[1], 32'd7);

        // Test 3: instructions 9-16
        /*
         * addi x4, x0, 15
         * addi x5, x0, 10
         * and  x6, x4, x5
         * or   x7, x4, x5
         * xor  x8, x4, x5
         * sw   x6, 8(x0)
         * sw   x7, 12(x0)
         * sw   x8, 16(x0)
        */
        repeat(8) begin
            @(posedge clk);
        end
        #1;

        check("x4", dut.rf.regs[4], 32'd15);
        check("x5", dut.rf.regs[5], 32'd10);
        check("x6", dut.rf.regs[6], 32'd10);
        check("x7", dut.rf.regs[7], 32'd15);
        check("x8", dut.rf.regs[8], 32'd5);
        check("mem[2]", dut.dmem.mem[2], 32'd10);
        check("mem[3]", dut.dmem.mem[3], 32'd15);
        check("mem[4]", dut.dmem.mem[4], 32'd5);
        
        // Test 4: instructions 17-24
        /*
         * addi  x9,  x0, 1
         * addi  x10, x0, 3
         * sll   x11, x9, x10
         * slli  x12, x9, 4
         * slt   x13, x1, x2
         * sltu  x14, x1, x2
         * slti  x15, x2, 10
         * sltiu x16, x2, 10
        */
        repeat(8) begin
            @(posedge clk);
        end
        #1;

        check("x9", dut.rf.regs[9], 32'd1);
        check("x10", dut.rf.regs[10], 32'd3);
        check("x11 sll", dut.rf.regs[11], 32'd8);
        check("x12 slli", dut.rf.regs[12], 32'd16);
        check("x13 slt", dut.rf.regs[13], 32'd1);
        check("x14 sltu", dut.rf.regs[14], 32'd1);
        check("x15 slti", dut.rf.regs[15], 32'd1);
        check("x16 sltiu", dut.rf.regs[16], 32'd1);

        // Test 5: instructions 25-30
        /*
         * addi x17, x0, -16
         * addi x18, x0, 2
         * srl  x19, x17, x18
         * sra  x20, x17, x18
         * srli x21, x17, 3
         * srai x22, x17, 3
        */
        repeat(6) begin
            @(posedge clk);
        end
        #1;

        check("x17", dut.rf.regs[17], 32'hffff_fff0);
        check("x18", dut.rf.regs[18], 32'd2);
        check("x19 srl", dut.rf.regs[19], 32'h3fff_fffc);
        check("x20 sra", dut.rf.regs[20], 32'hffff_fffc);
        check("x21 srli", dut.rf.regs[21], 32'h1fff_fffe);
        check("x22 srai", dut.rf.regs[22], 32'hffff_fffe);

        // Test 6: instructions 31-34
        /*
         * addi x23, x0, 15
         * xori x24, x23, 10
         * ori  x25, x23, 48
         * andi x26, x25, 15
        */
        repeat(4) begin
            @(posedge clk);
        end
        #1;

        check("x23", dut.rf.regs[23], 32'd15);
        check("x24 xori", dut.rf.regs[24], 32'd5);
        check("x25 ori", dut.rf.regs[25], 32'd63);
        check("x26 andi", dut.rf.regs[26], 32'd15);

        // Test 7: instructions 35-38
        /*
         * beq  x23, x23, 8
         * addi x23, x0,  1
         * beq  x23, x24, 8
         * addi x23, x0,  1
        */

        repeat(2) begin
            @(posedge clk);
        end
        #1;
        check("x23 beq(taken)", dut.rf.regs[23], 32'd15);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x23 beq(not taken)", dut.rf.regs[23], 32'd1);

        // Test 8: instructions 39-42
        /*
         * bne  x23, x24, 8
         * addi x27, x0,  2
         * bne  x23, x23, 8
         * addi x27, x0,  1
        */
        repeat(2) begin
            @(posedge clk);
        end
        #1;
        check("x27 bne(taken)", dut.rf.regs[27], 32'd0);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x27 bne(not taken)", dut.rf.regs[27], 32'd1);

        // Test 9: instructions 43-46
        /*
         * blt  x17, x18, 8
         * addi x28, x0,  2
         * bltu x17, x18, 8
         * addi x28, x0,  1
        */
        repeat(2) begin
            @(posedge clk);
        end
        #1;
        check("x28 blt(taken)", dut.rf.regs[28], 32'd0);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x28 bltu(not taken)", dut.rf.regs[28], 32'd1);

        // Test 10: instructions 47-51
        /*
         * bge  x18, x17, 8
         * addi x29, x0,  99
         * bgeu x17, x18, 8
         * addi x29, x0,  99
         * addi x29, x0,  10
        */
        repeat(2) begin
            @(posedge clk);
        end
        #1;
        check("x29 bge/bgeu(taken)", dut.rf.regs[29], 32'd0);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x29 bge/bgeu target", dut.rf.regs[29], 32'd10);

        // Test 11: instruction 52
        /*
         * lui x30, 0x12345
        */
        repeat(1) begin
            @(posedge clk);
        end
        #1;

        check("x30 lui", dut.rf.regs[30], 32'h1234_5000);

        // Test 12: instructions 53-55
        /*
         * jal  x31, 8
         * addi x30, x0, 99
         * addi x5,  x0, 12
        */
        repeat(1) begin
            @(posedge clk);
        end
        #1;

        check("x31 jal link", dut.rf.regs[31], 32'h0000_00d4);
        check("x30 jal skip", dut.rf.regs[30], 32'h1234_5000);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x5 jal target", dut.rf.regs[5], 32'd12);

        // Test 13: instructions 56-59
        /*
         * addi x6, x0, 232
         * jalr x7, 0(x6)
         * addi x5, x0, 99
         * addi x5, x0, 13
        */
        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x6 jalr base", dut.rf.regs[6], 32'd232);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x7 jalr link", dut.rf.regs[7], 32'h0000_00e4);
        check("x5 jalr skip", dut.rf.regs[5], 32'd12);

        repeat(1) begin
            @(posedge clk);
        end
        #1;
        check("x5 jalr target", dut.rf.regs[5], 32'd13);

        // Test 14: instructions 60-74
        /*
         * addi x9,  x0,  -1
         * addi x10, x0,   1
         * slt  x11, x9,  x10
         * sltu x12, x9,  x10
         * addi x13, x0,  -1
         * addi x13, x13,  1
         * blt  x13, x10, -4
         * jal  x0,  12
         * addi x15, x0,  14
         * jal  x0,   8
         * jal  x14, -8
         * addi x16, x0,  288
         * jalr x17, 4(x16)
         * addi x18, x0,  99
         * addi x18, x0,  14
        */
        repeat(4) begin
            @(posedge clk);
        end
        #1;

        check("x9 signed edge", dut.rf.regs[9], 32'hffff_ffff);
        check("x10 signed edge", dut.rf.regs[10], 32'd1);
        check("x11 slt edge", dut.rf.regs[11], 32'd1);
        check("x12 sltu edge", dut.rf.regs[12], 32'd0);

        repeat(5) begin
            @(posedge clk);
        end
        #1;

        check("x13 negative branch", dut.rf.regs[13], 32'd1);

        repeat(4) begin
            @(posedge clk);
        end
        #1;

        check("x14 negative jal link", dut.rf.regs[14], 32'h0000_0118);
        check("x15 negative jal target", dut.rf.regs[15], 32'd14);

        repeat(3) begin
            @(posedge clk);
        end
        #1;

        check("x16 jalr nonzero base", dut.rf.regs[16], 32'd288);
        check("x17 jalr nonzero link", dut.rf.regs[17], 32'h0000_0120);
        check("x18 jalr nonzero target", dut.rf.regs[18], 32'd14);

        // Test 15: instructions 75-76
        /*
         * addi x0,  x0, 5
         * addi x19, x0, 15
        */
        repeat(2) begin
            @(posedge clk);
        end
        #1;

        check("x0 cannot overwrite", dut.rf.regs[0], 32'd0);
        check("x19 after x0 test", dut.rf.regs[19], 32'd15);

        // Test 16: reset in the middle of execution
        /*
         * reset = 1
        */
        reset = 1'b1;
        @(posedge clk);
        #1;

        check("pc reset middle", dut.pc_curr, 32'd0);
        check("x19 reset middle", dut.rf.regs[19], 32'd0);
        check("x30 reset middle", dut.rf.regs[30], 32'd0);
        check("mem[4] reset middle", dut.dmem.mem[4], 32'd0);

        // Test 17: unknown/invalid instruction
        /*
         * invalid instruction
         * addi x20, x0, 17
        */
        dut.imem.mem[0] = 32'hffff_ffff;
        dut.imem.mem[1] = 32'h01100a13;

        reset = 1'b0;

        repeat(1) begin
            @(posedge clk);
        end
        #1;

        check("x20 invalid skip", dut.rf.regs[20], 32'd0);
        check("pc after invalid", dut.pc_curr, 32'd4);

        repeat(1) begin
            @(posedge clk);
        end
        #1;

        check("x20 after invalid", dut.rf.regs[20], 32'd17);

        // NOPs to check if padding is harmless
        dut.imem.mem[2] = 32'h00000013;
        dut.imem.mem[3] = 32'h00000013;
        dut.imem.mem[4] = 32'h00000013;
        dut.imem.mem[5] = 32'h00000013;
        
        repeat(4) begin
            @(posedge clk);
        end
        #1;

        check("x1 final", dut.rf.regs[1], 32'd0);
        check("x20 final", dut.rf.regs[20], 32'd17);
        check("x30 final", dut.rf.regs[30], 32'd0);
        check("mem[4] final", dut.dmem.mem[4], 32'd0);

        // FINAL
        if (errors == 0) begin
            $display("ALL CPU TESTS PASSED");
        end else begin
            $display("CPU TESTS FAILED: %d errors", errors);
        end

        $finish;
    end

endmodule
