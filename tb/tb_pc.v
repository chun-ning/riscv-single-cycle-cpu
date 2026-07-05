`timescale 1ns / 1ps
module tb_pc;

    reg clk;
    reg reset;
    reg branch;
    reg jump;
    reg [31:0] imm;
    wire [31:0] pc;

    integer errors;

    pc dut (
        .clk(clk),
        .reset(reset),
        .branch(branch),
        .jump(jump),
        .imm(imm),
        .pc(pc)
    );

    always begin
        #5 clk = ~clk;
    end

    task check;
        input [255:0] test_name;
        input [31:0] exp_pc;
        begin
            #1;
            if (exp_pc !== pc) begin
                $display("FAIL: test=%s expected=%h got=%h",
                            test_name, exp_pc, pc);
                errors = errors + 1;
            end else begin
                $display("PASS: test=%s got=%h",
                            test_name, pc);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/pc.vcd");
        $dumpvars(0, tb_pc);

        errors = 0;
        clk = 0;

        $display("Starting pc test...");
        
        // Test 0: reset
        reset = 1;
        branch = 0;
        jump = 0;
        imm = 32'd0;
        @(posedge clk);
        check("Reset", 32'd0);

        // Test 1: normal pc behavior
        reset = 0;
        branch = 0;
        jump = 0;
        imm = 32'd0;
        @(posedge clk);
        check("Normal", 32'd4);

        // Test 2: jump by 8
        reset = 0;
        branch = 0;
        jump = 1;
        imm = 32'd8;
        @(posedge clk);
        check("Jump (8)", 32'd12);

        // Test 3: branch by 12
        reset = 0;
        branch = 1;
        jump = 0;
        imm = 32'd12;
        @(posedge clk);
        check("Branch (12)", 32'd24);

        // Test 4: reset (highest priority)
        reset = 1;
        branch = 1;
        jump = 0;
        imm = 32'd4;
        @(posedge clk);
        check("Reset (highest priority)", 32'd0);

        // Test 5: behavior after reset is released
        reset = 0;
        branch = 0;
        jump = 0;
        imm = 32'd0;
        @(posedge clk);
        check("After reset release", 32'd4);

        // Test 6: branch with negative immediate, 4 + (-4) = 0
        reset = 0;
        branch = 1;
        jump = 0;
        imm = 32'hffff_fffc;
        @(posedge clk);
        check("Branch negative imm (-4)", 32'd0);

        // Test 7: jump with zero immediate keeps pc the same
        reset = 0;
        branch = 0;
        jump = 1;
        imm = 32'd0;
        @(posedge clk);
        check("Jump zero imm", 32'd0);

        // Test 8: larger immediate
        reset = 0;
        branch = 0;
        jump = 1;
        imm = 32'd1024;
        @(posedge clk);
        check("Jump larger imm (1024)", 32'd1024);

        // Test 9: pc does not change between clock edges
        reset = 0;
        branch = 0;
        jump = 0;
        imm = 32'd0;
        #2;
        check("Stable between clock edges", 32'd1024);

        @(posedge clk);
        check("Next normal after stable", 32'd1028);

        if (errors == 0) begin
            $display("All pc tests passed.");
        end else begin
            $display("pc tests failed with %0d error(s).", errors);
        end

        $finish;

    end

endmodule
