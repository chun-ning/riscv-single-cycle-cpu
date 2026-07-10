`timescale 1ns / 1ps

module tb_cpu;
    reg clk;
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
        input [127:0] test_name;
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

        check("x4", dut.rf.regs[4], 32'd15);
        check("x5", dut.rf.regs[5], 32'd10);
        check("x6", dut.rf.regs[6], 32'd10);
        check("x7", dut.rf.regs[7], 32'd15);
        check("x8", dut.rf.regs[8], 32'd5);
        check("mem[2]", dut.dmem.mem[2], 32'd10);
        check("mem[3]", dut.dmem.mem[3], 32'd15);
        check("mem[4]", dut.dmem.mem[4], 32'd5);

        // NOPs to check if padding is harmless
        repeat(4) begin
            @(posedge clk);
        end

        check("x1 final", dut.rf.regs[1], 32'd2);
        check("x8 final", dut.rf.regs[8], 32'd5);
        check("mem[4] final", dut.dmem.mem[4], 32'd5);

        // FINAL
        if (errors == 0) begin
            $display("ALL CPU TESTS PASSED");
        end else begin
            $display("CPU TESTS FAILED: %d errors", errors);
        end

        $finish;
    end

endmodule
