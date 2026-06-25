`timescale 1ns / 1ps  // Unit: 1 nanosecond, Precision: 1 picosecond

module tb_alu;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] out;
    wire        zero;
    wire        carry;
    wire        overflow;
    wire        negative;

    localparam ADD  = 4'h0;
    localparam SUB  = 4'h1;
    localparam AND  = 4'h2;
    localparam OR   = 4'h3;
    localparam XOR  = 4'h4;
    localparam SLL  = 4'h5;
    localparam SRL  = 4'h6;
    localparam SRA  = 4'h7;
    localparam SLT  = 4'h8;
    localparam SLTU = 4'h9;

    integer errors;

    alu dut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .out(out),
        .zero(zero),
        .carry(carry),
        .overflow(overflow),
        .negative(negative)
    );

    // PASS/FAIL message
    task check;
        input [31:0] expected;
        input        expected_zero;
        input        expected_carry;
        input        expected_overflow;
        input        expected_negative;
        begin 
            #1;
            if ((out !== expected) ||
                (zero !== expected_zero) ||
                (carry !== expected_carry) ||
                (overflow !== expected_overflow) ||
                (negative !== expected_negative)) begin
                errors = errors + 1;
                $display("FAIL: a=%h b=%h alu_ctrl=%b expected out=%h zero=%b carry=%b overflow=%b negative=%b got out=%h zero=%b carry=%b overflow=%b negative=%b",
                a, b, alu_ctrl, expected, expected_zero, expected_carry, expected_overflow, expected_negative,
                out, zero, carry, overflow, negative);
            end else begin
                $display("PASS: a=%h b=%h alu_ctrl=%b out=%h zero=%b carry=%b overflow=%b negative=%b",
                a, b, alu_ctrl, out, zero, carry, overflow, negative);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/alu.vcd");
        $dumpvars(0, tb_alu);

        errors = 0;

        // ADD: 5 + 3 = 8
        a = 32'd5;
        b = 32'd3;
        alu_ctrl = ADD;
        check(32'd8, 1'b0, 1'b0, 1'b0, 1'b0);

        // ADD: carry out
        a = 32'hffff_ffff;
        b = 32'd1;
        alu_ctrl = ADD;
        check(32'd0, 1'b1, 1'b1, 1'b0, 1'b0);

        // ADD: signed overflow
        a = 32'h7fff_ffff;
        b = 32'd1;
        alu_ctrl = ADD;
        check(32'h8000_0000, 1'b0, 1'b0, 1'b1, 1'b1);

        // SUB: 5 - 3 = 2
        a = 32'd5;
        b = 32'd3;
        alu_ctrl = SUB;
        check(32'd2, 1'b0, 1'b1, 1'b0, 1'b0);

        // SUB: borrow and negative result
        a = 32'd3;
        b = 32'd5;
        alu_ctrl = SUB;
        check(32'hffff_fffe, 1'b0, 1'b0, 1'b0, 1'b1);

        // SUB: signed overflow
        a = 32'h8000_0000;
        b = 32'd1;
        alu_ctrl = SUB;
        check(32'h7fff_ffff, 1'b0, 1'b1, 1'b1, 1'b0);

        // AND
        a = 32'ha5a5_5a5a;
        b = 32'hff00_0ff0;
        alu_ctrl = AND;
        check(32'ha500_0a50, 1'b0, 1'b0, 1'b0, 1'b1);

        // OR
        a = 32'ha5a5_5a5a;
        b = 32'hff00_0ff0;
        alu_ctrl = OR;
        check(32'hffa5_5ffa, 1'b0, 1'b0, 1'b0, 1'b1);

        // XOR
        a = 32'ha5a5_5a5a;
        b = 32'hff00_0ff0;
        alu_ctrl = XOR;
        check(32'h5aa5_55aa, 1'b0, 1'b0, 1'b0, 1'b0);

        // SLL
        a = 32'h0000_0001;
        b = 32'd4;
        alu_ctrl = SLL;
        check(32'h0000_0010, 1'b0, 1'b0, 1'b0, 1'b0);

        // SRL
        a = 32'h8000_0000;
        b = 32'd4;
        alu_ctrl = SRL;
        check(32'h0800_0000, 1'b0, 1'b0, 1'b0, 1'b0);

        // SRA
        a = 32'h8000_0000;
        b = 32'd4;
        alu_ctrl = SRA;
        check(32'hf800_0000, 1'b0, 1'b0, 1'b0, 1'b1);

        // SLT: signed
        a = 32'hffff_ffff;
        b = 32'd1;
        alu_ctrl = SLT;
        check(32'd1, 1'b0, 1'b0, 1'b0, 1'b0);

        // SLTU: unsigned
        a = 32'hffff_ffff;
        b = 32'd1;
        alu_ctrl = SLTU;
        check(32'd0, 1'b1, 1'b0, 1'b0, 1'b0);

        // Default case
        a = 32'h1234_5678;
        b = 32'h8765_4321;
        alu_ctrl = 4'ha;
        check(32'd0, 1'b1, 1'b0, 1'b0, 1'b0);

        if (errors == 0) begin
            $display("All ALU tests passed.");
        end else begin
            $display("ALU tests failed with %0d error(s).", errors);
        end

        $finish;

    end

endmodule
