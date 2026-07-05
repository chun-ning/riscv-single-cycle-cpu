`timescale 1ns / 1ps

module tb_data_mem;

    reg clk;
    reg mem_write;
    reg [31:0] addr;
    reg [31:0] write_data;
    wire [31:0] read_data;

    integer errors;

    data_mem dut(
        .clk(clk),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    always begin
        #5 clk = ~clk;
    end

    task check;
        input [255:0] test_name;
        input [31:0] exp_read;
        begin
            #1;
            if (read_data !== exp_read) begin
                $display("FAIL: test=%s expected = %h, got = %h",
                         test_name, exp_read, read_data);
                errors = errors + 1;
            end else begin
                $display("PASS: test=%s got = %h",
                         test_name, read_data);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/data_mem.vcd");
        $dumpvars(0, tb_data_mem);

        errors = 0;
        // Initial values
        clk = 0;
        mem_write = 1'b0;
        addr = 32'd8;
        write_data = 32'd2;

        $display("Starting data_mem test...");

        // Test 1: writing 2 to mem[2]
        mem_write = 1'b1;
        addr = 32'd8; // mem[2]
        write_data = 32'd2;

        @(posedge clk);
        check("mem[2] = 2", 32'd2);

        // Test 2: writing 3 to mem[2], mem_write = 1'b0 (read only)
        mem_write = 1'b0;
        addr = 32'd8; // mem[2]
        write_data = 32'd3;

        @(posedge clk);
        check("read mem[2]", 32'd2);

        // Test 3: writing a bigger data pattern to a different address, mem[3]
        mem_write = 1'b1;
        addr = 32'd12; // mem[3]
        write_data = 32'ha5a5_5a5a;

        @(posedge clk);
        check("mem[3] = a5a5_5a5a", 32'ha5a5_5a5a);

        // Test 4: original mem[2] is still unchanged
        mem_write = 1'b0;
        addr = 32'd8; // mem[2]
        write_data = 32'hffff_ffff;

        @(posedge clk);
        check("mem[2] const after mem[3] write", 32'd2);

        // Test 5: overwrite existing mem[2] when mem_write = 1
        mem_write = 1'b1;
        addr = 32'd8; // mem[2]
        write_data = 32'h1234_5678;

        @(posedge clk);
        check("overwrite mem[2]", 32'h1234_5678);

        // Test 6: read_data changes immediately when addr changes
        mem_write = 1'b0;
        addr = 32'd12; // mem[3]
        check("read changes to mem[3]", 32'ha5a5_5a5a);

        addr = 32'd8; // mem[2]
        check("read changes back to mem[2]", 32'h1234_5678);

        // Test 7: address aliasing within one 32-bit word
        addr = 32'd9; // still mem[2]
        check("addr 9 aliases mem[2]", 32'h1234_5678);

        addr = 32'd10; // still mem[2]
        check("addr 10 aliases mem[2]", 32'h1234_5678);

        addr = 32'd11; // still mem[2]
        check("addr 11 aliases mem[2]", 32'h1234_5678);

        // Test 8: memory does not change between clock edges
        mem_write = 1'b1;
        addr = 32'd8; // mem[2]
        write_data = 32'hdead_beef;
        #2;
        check("no write before clock edge", 32'h1234_5678);

        @(posedge clk);
        check("write happens at clock edge", 32'hdead_beef);
        
        // FINAL
        if (errors == 0) begin
            $display("ALL DATA_MEM TESTS PASSED");
        end else begin
            $display("DATA_MEM TESTS FAILED: %d errors", errors);
        end

        $finish;

    end

endmodule
