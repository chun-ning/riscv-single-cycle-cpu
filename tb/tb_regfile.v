`timescale 1ns / 1ps

module tb_regfile;
    reg clk;
    reg w_en;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [4:0] rd;
    reg [31:0] w_data;

    wire [31:0] rv1;
    wire [31:0] rv2;

    integer errors;

    regfile dut(
        .clk(clk),
        .w_en(w_en),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .w_data(w_data),
        .rv1(rv1),
        .rv2(rv2)
    );

    // clk period: 10 ns
    always begin
        #5 clk = ~clk;
    end

    task check;
        input [127:0] test_name;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL: test=%s expected = %h, got = %h",
                         test_name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: test=%s got = %h",
                         test_name, actual);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/regfile.vcd");
        $dumpvars(0, tb_regfile);

        errors = 0;

        // Initial values
        clk = 0;
        w_en = 0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd0;
        w_data = 32'd0;

        $display("Starting regfile test...");
        
        // Test 1: read rv from rs = x0
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;

        check("rv1 = x0", rv1, 32'd0);
        check("rv2 = x0", rv2, 32'd0);

        // Test 2: write 100 to x3, then read x3
        rd = 5'd3;
        w_data = 32'd100;
        w_en = 1'b1;

        @(posedge clk);
        #1; 

        w_en = 1'b0;
        rs1 = 5'd3;
        #1;

        check("write, read x3", rv1, 32'd100);

        // Test 3: Read two reg at the same time, x3 = 100, x5 = 123
        rd = 5'd5;
        w_data = 32'd123;
        w_en = 1'b1;

        @(posedge clk);
        #1;
        
        w_en = 1'b0;
        rs1 = 5'd3;
        rs2 = 5'd5;
        #1;
        check("read x3", rv1, 32'd100);
        check("read x5", rv2, 32'd123);

        // Test 4: Try to write to x0 (should not change)
        rd = 5'd0;
        w_data = 32'd0;
        w_en = 1'b1;

        @(posedge clk);
        #1;

        w_en = 1'b0;
        rs1 = 5'd0;
        #1;
        check("write x0", rv1, 32'd0);

        // Test 5: Write when w_en = 0;
        rd = 5'd3;
        w_data = 32'd3;
        w_en = 1'b0;

        @(posedge clk);
        #1;

        rs1 = 5'd3;
        #1;
        check ("write w_en = 0", rv1, 32'd100);

        // FINAL
        if (errors == 0) begin
            $display("ALL REGFILE TESTS PASSED");
        end else begin
            $display("REGFILE TESTS FAILED: %d errors", errors);
        end

        $finish;

    end

endmodule