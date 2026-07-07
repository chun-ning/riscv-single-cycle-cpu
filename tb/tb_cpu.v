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
        input [63:0] test_name;
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

        $display("Starting cpu test...");

        @(posedge clk)
        #1;
        reset = 0;

        // cpu_test with 4 instructions
        #1;
        repeat(6) begin
            @(posedge clk);
        end

        #1;
        check("mem[0]", dut.dmem.mem[0], 32'd9);
        check("x1", dut.rf.regs[1], 32'd5);
        check("x2", dut.rf.regs[2], 32'd4);
        check("x3", dut.rf.regs[3], 32'd9);

        // FINAL
        if (errors == 0) begin
            $display("ALL DATA_MEM TESTS PASSED");
        end else begin
            $display("DATA_MEM TESTS FAILED: %d errors", errors);
        end

        $finish;
    end

endmodule