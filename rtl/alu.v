module alu(input [31:0]a, input [31:0]b, input [3:0]alu_ctrl, output reg [31:0]out, output reg zero, output reg carry, output reg overflow, output reg negative);
    
    reg [32:0]temp;

    always @(*) begin
        // default
        out = 32'b0;
        zero = 1'b0;
        carry = 1'b0; 
        overflow = 1'b0;
        negative = 1'b0;
        temp = 33'b0;

        case(alu_ctrl)
            4'h0: begin                                             // add
                temp = {1'b0, a} + {1'b0, b};
                out = temp[31:0];
                carry = temp[32];

                // signed overflow for addition
                overflow = (a[31] == b[31]) && (out[31] != a[31]);
            end
            4'h1: begin                                             // sub
                out = temp[31:0];

                // carry = 1 when no borrow
                carry = (a >= b);

                // signed overflow for subtraction
                overflow = (a[31] != b[31]) && (out[31] != a[31]);
            end
            4'h2: out = a & b;                                      // and
            4'h3: out = a | b;                                      // or
            4'h4: out = a ^ b;                                      // xor
            4'h5: out = a << b[4:0];                                // sll
            4'h6: out = a >> b[4:0];                                // srl
            4'h7: out = $signed(a) >>> b[4:0];                      // sra
            4'h8: out = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;  // slt
            4'h9: out = (a < b) ? 32'h1 : 32'h0;                    // sltu
            default: out = 32'b0;
        endcase

        // set zero & negative
        zero = (out == 32'b0);
        negative = out[31];
    end
endmodule