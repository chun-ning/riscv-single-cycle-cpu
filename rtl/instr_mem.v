module instr_mem(
    input [31:0] pc,
    output [31:0] instr
);
    reg [31:0] mem [0:511]; // 2KB instruction space
    
    initial begin
        // $readmemh("tb/programs/add_test.hex", mem);
        $readmemh("tb/programs/cpu_test.hex", mem);
    end

    assign instr = mem[pc[10:2]]; // 9 bits of PC

endmodule