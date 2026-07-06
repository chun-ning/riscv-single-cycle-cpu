module cpu(
    input clk,
    input reset
);

    // pc
    wire [31:0] pc_curr;
    wire [31:0] instr;
    wire [31:0] pc_plus_4;

    assign pc_plus_4 = pc_curr + 32'd4;

    // Instruction
    wire [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;

    assign opcode = instr[6:0];
    assign func3 = instr[14:12];
    assign func7 = instr[31:25];
    assign rd = instr[11:7];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];

    // Control
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire branch;
    wire jump;
    wire [3:0] alu_ctrl;
    wire [1:0] result_src;

    // Regfile
    wire [31:0] rv1;
    wire [31:0] rv2;
    wire [31:0] w_data;

    // imm_gen
    wire [31:0] imm;

    // ALU
    wire [31:0] a;
    wire [31:0] b;
    wire [31:0] out;
    wire zero;
    wire carry;
    wire overflow;
    wire negative;

    assign a = rv1;
    assign b = alu_src ? imm : rv2;

    // data_mem
    wire [31:0] addr;
    wire [31:0] write_data;
    wire [31:0] read_data;

    assign addr = out;
    assign write_data = rv2;

    // Branch condition true or not
    reg branch_taken;
    always @(*) begin;
        case (func3)
            3'b000: branch_taken = branch && (rs1 == rs2); // beq
            3'b001: branch_taken = branch && (rs1 != rs2); // bne
            3'b100: branch_taken = branch && ($signed(rs1) < $signed(rs2)); // blt
            3'b101: branch_taken = branch && ($signed(rs1) >= $signed(rs2)); // bge
            default: branch_taken = 1'b0;
        endcase
    end
    
    // pc
    pc pc_instr (
        .clk(clk),
        .reset(reset),
        .branch(branch_taken),
        .jump(jump),
        .imm(imm),
        .pc(pc_curr)
    );

    // instr_mem
    instr_mem instr_mem (
        .pc(pc_curr),
        .instr(instr)
    );

    // regfile
    regfile regfile (
        .clk(clk),
        .w_en(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .w_data(w_data),
        .rv1(rv1),
        .rv2(rv2)
    );

    // control
    control control (
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_ctrl(alu_ctrl),
        .result_src(result_src)
    );

    // imm_gen
    imm_gen imm_gen (
        .instr(instr),
        .imm(imm)
    );

    // ALU
    alu alu (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .out(out),
        .zero(zero),
        .carry(carry),
        .overflow(overflow),
        .negative(negative)
    );

    // data_mem
    data_mem data_mem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );
    
    // write back in regfile
    assign w_data = 
        (result_src == 2'b00) ? out :
        (result_src == 2'b01) ? read_data :
        (result_src == 2'b10) ? pc_plus_4 :
        (result_src == 2'b11) ? imm :
        32'd0;

endmodule
