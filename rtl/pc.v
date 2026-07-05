module pc(
    input clk,
    input reset,
    input branch,
    input jump,
    input [31:0] imm,
    output reg [31:0] pc
);

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'h0;
        end else if (jump || branch) begin
            pc <= pc + imm;
        end else begin
            pc <= pc + 32'd4;
        end
    end

endmodule