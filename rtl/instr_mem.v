module instr_mem(
    input [31:0] pc,
    output [31:0] instr
);
    reg [31:0] mem [0:511]; // 2KB instruction space
    
    integer i;

    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            mem[i] = 32'h00000013; // nop: addi x0, x0, 0
        end

        $readmemh("tb/programs/cpu_test.hex", mem, 0, 75);
    end

    assign instr = mem[pc[10:2]]; // 9 bits of PC

endmodule
