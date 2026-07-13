`timescale 1ns / 1ps

module tb_imm_gen;
    reg  [31:0] instr;
    wire [31:0] imm;

    localparam LUI    = 7'b0110111;
    localparam OP_IMM = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;

    integer errors;

    imm_gen dut (
        .instr(instr),
        .imm(imm)
    );

    task check;
        input [255:0] test_name;
        input [31:0] expected;
        begin
            #1;
            if (imm !== expected) begin
                $display("FAIL: test=%s instr=%h expected=%h got=%h",
                         test_name, instr, expected, imm);
                errors = errors + 1;
            end else begin
                $display("PASS: test=%s instr=%h imm=%h",
                         test_name, instr, imm);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        errors = 0;

        $display("Starting imm_gen test...");

        // OP_IMM / I-type: addi x2, x1, 51
        instr = {12'h033, 5'd1, 3'b000, 5'd2, OP_IMM};
        check("OP_IMM positive imm=51", 32'd51);

        // OP_IMM / I-type: addi x2, x1, -1
        instr = {12'hfff, 5'd1, 3'b000, 5'd2, OP_IMM};
        check("OP_IMM negative imm=-1", 32'hffff_ffff);

        // LOAD / I-type: lw x3, 16(x4)
        instr = {12'h010, 5'd4, 3'b010, 5'd3, LOAD};
        check("LOAD positive imm=16", 32'd16);

        // LOAD / I-type: lw x3, -8(x4)
        instr = {12'hff8, 5'd4, 3'b010, 5'd3, LOAD};
        check("LOAD negative imm=-8", 32'hffff_fff8);

        // JALR / I-type: jalr x1, -4(x5)
        instr = {12'hffc, 5'd5, 3'b000, 5'd1, JALR};
        check("JALR negative imm=-4", 32'hffff_fffc);

        // STORE / S-type: sw x6, 20(x7)
        instr = {7'b0000000, 5'd6, 5'd7, 3'b010, 5'b10100, STORE};
        check("STORE positive imm=20", 32'd20);

        // STORE / S-type: sw x6, -16(x7)
        instr = {7'b1111111, 5'd6, 5'd7, 3'b010, 5'b10000, STORE};
        check("STORE negative imm=-16", 32'hffff_fff0);

        // BRANCH / B-type: beq x1, x2, 12
        instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0110, 1'b0, BRANCH};
        check("BRANCH positive imm=12", 32'd12);

        // BRANCH / B-type: beq x1, x2, -4
        instr = {1'b1, 6'b111111, 5'd2, 5'd1, 3'b000, 4'b1110, 1'b1, BRANCH};
        check("BRANCH negative imm=-4", 32'hffff_fffc);

        // JAL / J-type: jal x1, 2048
        instr = {1'b0, 10'b0000000000, 1'b1, 8'h00, 5'd1, JAL};
        check("JAL positive imm=2048", 32'd2048);

        // JAL / J-type: jal x1, -2048
        instr = {1'b1, 10'b0000000000, 1'b1, 8'hff, 5'd1, JAL};
        check("JAL negative imm=-2048", 32'hffff_f800);

        // LUI / U-type: immediate goes into bits [31:12].
        instr = {20'h12345, 5'd10, LUI};
        check("LUI imm[31:12]=0x12345", 32'h1234_5000);

        // LUI / U-type with bit 31 set.
        instr = {20'hf2345, 5'd10, LUI};
        check("LUI imm[31:12]=0xf2345", 32'hf234_5000);

        // Unsupported opcode
        instr = 32'h0000_0000;
        check("DEFAULT unsupported opcode", 32'd0);

        if (errors == 0) begin
            $display("All imm_gen tests passed.");
        end else begin
            $display("imm_gen tests failed with %0d error(s).", errors);
        end

        $finish;
    end
endmodule
