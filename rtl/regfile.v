module regfile(
    input clk, 
    input w_en,             // regfile allowed to write when w_en = 1
    input  [4:0]rs1,        // 32 registers --> 5 bits
    input  [4:0]rs2, 
    input  [4:0]rd, 
    input  [31:0]w_data,    // write data
    output [31:0]rv1,       // read value (of rs1)
    output [31:0]rv2        // read value (of rs2)
    );

    reg [31:0] regs [0:31]; // 32-bit registers * 32

    assign rv1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1]; // rv1 = 0 if rs1 = x0
    assign rv2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2]; // rv2 = 0 if rs2 = x0

    always @(posedge clk) begin
        if (w_en && rd != 5'd0) begin
            regs[rd] <= w_data;     // write w_data into regs[rd]
        end
    end
    
endmodule