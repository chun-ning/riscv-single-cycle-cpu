module data_mem(
    input clk,
    input reset,
    input mem_read,
    input mem_write,
    input [31:0] addr,
    input [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:511];

    assign read_data = mem_read ? mem[addr[10:2]] : 32'b0;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 512; i = i + 1) begin
                mem[i] <= 32'd0;
            end
        end else if (mem_write) begin
            mem[addr[10:2]] <= write_data;
        end
    end
endmodule
