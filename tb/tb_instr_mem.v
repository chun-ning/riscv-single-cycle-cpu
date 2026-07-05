`timescale 1ns / 1ps

module tb_instr_mem;
    reg [31:0] pc;
    wire [31:0] instr;

    integer errors;

    instr_mem dut(
        .pc(pc),
        .instr(instr)
    );

    task check;
        input [255:0] test_name;
        input [31:0] exp_instr;
        begin
            #1;
            if (instr !== exp_instr) begin
                $display("FAIL: test=%s expected = %h, got = %h",
                         test_name, exp_instr, instr);
                errors = errors + 1;
            end else begin
                $display("PASS: test=%s got = %h",
                         test_name, instr);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/instr_mem.vcd");
        $dumpvars(0, tb_instr_mem);

        errors = 0;
        pc = 32'd0;

        $display("Starting instr_mem test...");

        // Test 1: pc = 0 reads mem[0]
        pc = 32'd0;
        check("pc 0 reads mem[0]", 32'h0000_0093);

        // Test 2: pc = 4 reads mem[1]
        pc = 32'd4;
        check("pc 4 reads mem[1]", 32'h0010_0113);

        // Test 3: pc = 8 reads mem[2]
        pc = 32'd8;
        check("pc 8 reads mem[2]", 32'h0020_81b3);

        // Test 4: read changes immediately when pc changes
        pc = 32'd12;
        check("pc change reads mem[3]", 32'h0031_8233);

        pc = 32'd8;
        check("pc change back reads mem[2]", 32'h0020_81b3);

        // Test 5: address aliasing inside one 32-bit instruction word
        pc = 32'd9;
        check("pc 9 aliases mem[2]", 32'h0020_81b3);

        pc = 32'd10;
        check("pc 10 aliases mem[2]", 32'h0020_81b3);

        pc = 32'd11;
        check("pc 11 aliases mem[2]", 32'h0020_81b3);

        // Test 6: highest valid address for mem[0:511]
        pc = 32'd2044; // 511 * 4
        check("pc 2044 reads mem[511]", 32'hffff_ffff);

        // FINAL
        if (errors == 0) begin
            $display("ALL INSTR_MEM TESTS PASSED");
        end else begin
            $display("INSTR_MEM TESTS FAILED: %d errors", errors);
        end

        $finish;
    end

endmodule
