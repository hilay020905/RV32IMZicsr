// Testbench for EXECUTE module
`timescale 1ns / 1ps

module EXECUTE_tb;

// Inputs
reg clk_i;
reg rst_i;
reg opcode_valid_i;
reg [31:0] opcode_opcode_i;
reg [31:0] opcode_pc_i;
reg opcode_invalid_i;
reg [4:0] opcode_rd_idx_i;
reg [4:0] opcode_ra_idx_i;
reg [4:0] opcode_rb_idx_i;
reg [31:0] opcode_ra_operand_i;
reg [31:0] opcode_rb_operand_i;
reg hold_i;

// Outputs
wire branch_request_o;
wire branch_is_taken_o;
wire branch_is_not_taken_o;
wire [31:0] branch_source_o;
wire branch_is_call_o;
wire branch_is_ret_o;
wire branch_is_jmp_o;
wire [31:0] branch_pc_o;
wire branch_d_request_o;
wire [31:0] branch_d_pc_o;
wire [1:0] branch_d_priv_o;
wire [31:0] writeback_value_o;

// Instantiate the EXECUTE module
EXECUTE uut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .opcode_valid_i(opcode_valid_i),
    .opcode_opcode_i(opcode_opcode_i),
    .opcode_pc_i(opcode_pc_i),
    .opcode_invalid_i(opcode_invalid_i),
    .opcode_rd_idx_i(opcode_rd_idx_i),
    .opcode_ra_idx_i(opcode_ra_idx_i),
    .opcode_rb_idx_i(opcode_rb_idx_i),
    .opcode_ra_operand_i(opcode_ra_operand_i),
    .opcode_rb_operand_i(opcode_rb_operand_i),
    .hold_i(hold_i),
    .branch_request_o(branch_request_o),
    .branch_is_taken_o(branch_is_taken_o),
    .branch_is_not_taken_o(branch_is_not_taken_o),
    .branch_source_o(branch_source_o),
    .branch_is_call_o(branch_is_call_o),
    .branch_is_ret_o(branch_is_ret_o),
    .branch_is_jmp_o(branch_is_jmp_o),
    .branch_pc_o(branch_pc_o),
    .branch_d_request_o(branch_d_request_o),
    .branch_d_pc_o(branch_d_pc_o),
    .branch_d_priv_o(branch_d_priv_o),
    .writeback_value_o(writeback_value_o)
);

// Clock generation
initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // 100MHz clock
end

// Test stimulus
initial begin
    // Initialize VCD dump
    $dumpfile("execute_wave.vcd");
    $dumpvars(0, EXECUTE_tb);

    // Initialize inputs
    rst_i = 1;
    opcode_valid_i = 0;
    opcode_opcode_i = 0;
    opcode_pc_i = 0;
    opcode_invalid_i = 0;
    opcode_rd_idx_i = 0;
    opcode_ra_idx_i = 0;
    opcode_rb_idx_i = 0;
    opcode_ra_operand_i = 0;
    opcode_rb_operand_i = 0;
    hold_i = 0;

    // Reset pulse
    #20;
    rst_i = 0;
    #10;

    // Test 1: ADD (rd = ra + rb)
    opcode_valid_i = 1;
    opcode_opcode_i = 32'h00000033; // ADD: funct7=0000000 rs2 rs1 funct3=000 rd opcode=0110011
    opcode_rd_idx_i = 5'd1;
    opcode_ra_idx_i = 5'd2;
    opcode_rb_idx_i = 5'd3;
    opcode_ra_operand_i = 32'h00000005;
    opcode_rb_operand_i = 32'h00000003;
    #20;

    // Test 2: SUB (rd = ra - rb)
    opcode_opcode_i = 32'h40000033; // SUB: funct7=0100000 rs2 rs1 funct3=000 rd opcode=0110011
    opcode_ra_operand_i = 32'h00000008;
    opcode_rb_operand_i = 32'h00000003;
    #20;

    // Test 3: AND (rd = ra & rb)
    opcode_opcode_i = 32'h00007033; // AND: funct7=0000000 rs2 rs1 funct3=111 rd opcode=0110011
    opcode_ra_operand_i = 32'h0000000F;
    opcode_rb_operand_i = 32'h00000005;
    #20;

    // Test 4: OR (rd = ra | rb)
    opcode_opcode_i = 32'h00006033; // OR: funct7=0000000 rs2 rs1 funct3=110 rd opcode=0110011
    opcode_ra_operand_i = 32'h0000000F;
    opcode_rb_operand_i = 32'h00000005;
    #20;

    // Test 5: XOR (rd = ra ^ rb)
    opcode_opcode_i = 32'h00004033; // XOR: funct7=0000000 rs2 rs1 funct3=100 rd opcode=0110011
    opcode_ra_operand_i = 32'h0000000F;
    opcode_rb_operand_i = 32'h00000005;
    #20;

    // Test 6: SLL (rd = ra << rb)
    opcode_opcode_i = 32'h00001033; // SLL: funct7=0000000 rs2 rs1 funct3=001 rd opcode=0110011
    opcode_ra_operand_i = 32'h00000001;
    opcode_rb_operand_i = 32'h00000002;
    #20;

    // Test 7: SRL (rd = ra >> rb)
    opcode_opcode_i = 32'h00005033; // SRL: funct7=0000000 rs2 rs1 funct3=101 rd opcode=0110011
    opcode_ra_operand_i = 32'h00000008;
    opcode_rb_operand_i = 32'h00000002;
    #20;

    // Test 8: SRA (rd = ra >>> rb)
    opcode_opcode_i = 32'h40005033; // SRA: funct7=0100000 rs2 rs1 funct3=101 rd opcode=0110011
    opcode_ra_operand_i = 32'h80000008;
    opcode_rb_operand_i = 32'h00000002;
    #20;

    // Test 9: SLT (rd = (ra < rb) ? 1 : 0, signed)
    opcode_opcode_i = 32'h00002033; // SLT: funct7=0000000 rs2 rs1 funct3=010 rd opcode=0110011
    opcode_ra_operand_i = 32'hFFFFFFF0; // -16
    opcode_rb_operand_i = 32'h00000010; // 16
    #20;

    // Test 10: SLTU (rd = (ra < rb) ? 1 : 0, unsigned)
    opcode_opcode_i = 32'h00003033; // SLTU: funct7=0000000 rs2 rs1 funct3=011 rd opcode=0110011
    opcode_ra_operand_i = 32'hFFFFFFF0;
    opcode_rb_operand_i = 32'h00000010;
    #20;

    // Test 11: ADDI (rd = ra + imm)
    opcode_opcode_i = 32'h00500013; // ADDI: imm=5 rs1 funct3=000 rd opcode=0010011
    opcode_ra_operand_i = 32'h00000003;
    #20;

    // Test 12: ANDI (rd = ra & imm)
    opcode_opcode_i = 32'h00507013; // ANDI: imm=5 rs1 funct3=111 rd opcode=0010011
    opcode_ra_operand_i = 32'h0000000F;
    #20;

    // Test 13: ORI (rd = ra | imm)
    opcode_opcode_i = 32'h00506013; // ORI: imm=5 rs1 funct3=110 rd opcode=0010011
    opcode_ra_operand_i = 32'h0000000F;
    #20;

    // Test 14: XORI (rd = ra ^ imm)
    opcode_opcode_i = 32'h00504013; // XORI: imm=5 rs1 funct3=100 rd opcode=0010011
    opcode_ra_operand_i = 32'h0000000F;
    #20;

    // Test 15: SLLI (rd = ra << shamt)
    opcode_opcode_i = 32'h00002013; // SLLI: funct7=0000000 shamt=2 rs1 funct3=001 rd opcode=0010011
    opcode_ra_operand_i = 32'h00000001;
    #20;

    // Test 16: SRLI (rd = ra >> shamt)
    opcode_opcode_i = 32'h00005013; // SRLI: funct7=0000000 shamt=2 rs1 funct3=101 rd opcode=0010011
    opcode_ra_operand_i = 32'h00000008;
    #20;

    // Test 17: SRAI (rd = ra >>> shamt)
    opcode_opcode_i = 32'h40005013; // SRAI: funct7=0100000 shamt=2 rs1 funct3=101 rd opcode=0010011
    opcode_ra_operand_i = 32'h80000008;
    #20;

    // Test 18: SLTI (rd = (ra < imm) ? 1 : 0, signed)
    opcode_opcode_i = 32'h00502013; // SLTI: imm=5 rs1 funct3=010 rd opcode=0010011
    opcode_ra_operand_i = 32'hFFFFFFF0; // -16
    #20;

    // Test 19: SLTIU (rd = (ra < imm) ? 1 : 0, unsigned)
    opcode_opcode_i = 32'h00503013; // SLTIU: imm=5 rs1 funct3=011 rd opcode=0010011
    opcode_ra_operand_i = 32'hFFFFFFF0;
    #20;

    // Test 20: LUI (rd = imm20 << 12)
    opcode_opcode_i = 32'h00001037; // LUI: imm20=0x1 rd opcode=0110111
    #20;

    // Test 21: AUIPC (rd = pc + imm20 << 12)
    opcode_opcode_i = 32'h00001017; // AUIPC: imm20=0x1 rd opcode=0010111
    opcode_pc_i = 32'h00001000;
    #20;

    // Test 22: JAL (branch and link)
    opcode_opcode_i = 32'h0040006F; // JAL: imm=0x4 rd opcode=1101111
    opcode_pc_i = 32'h00001000;
    opcode_rd_idx_i = 5'd1; // RA
    #20;

    // Test 23: JALR (jump and link register)
    opcode_opcode_i = 32'h00008067; // JALR: imm=0 rs1 funct3=000 rd opcode=1100111
    opcode_ra_operand_i = 32'h00002000;
    opcode_rd_idx_i = 5'd1; // RA
    #20;

    // Test 24: BEQ (branch if equal)
    opcode_opcode_i = 32'h00008063; // BEQ: imm=0x8 rs1 rs2 funct3=000 opcode=1100011
    opcode_ra_operand_i = 32'h00000005;
    opcode_rb_operand_i = 32'h00000005;
    opcode_pc_i = 32'h00001000;
    #20;

    // Test 25: BNE (branch if not equal)
    opcode_opcode_i = 32'h00009063; // BNE: imm=0x8 rs1 rs2 funct3=001 opcode=1100011
    opcode_ra_operand_i = 32'h00000005;
    opcode_rb_operand_i = 32'h00000006;
    #20;

    // Test 26: BLT (branch if less than, signed)
    opcode_opcode_i = 32'h0000C063; // BLT: imm=0x8 rs1 rs2 funct3=100 opcode=1100011
    opcode_ra_operand_i = 32'hFFFFFFF0; // -16
    opcode_rb_operand_i = 32'h00000010; // 16
    #20;

    // Test 27: BGE (branch if greater or equal, signed)
    opcode_opcode_i = 32'h0000D063; // BGE: imm=0x8 rs1 rs2 funct3=101 opcode=1100011
    opcode_ra_operand_i = 32'h00000010;
    opcode_rb_operand_i = 32'h00000010;
    #20;

    // Test 28: BLTU (branch if less than, unsigned)
    opcode_opcode_i = 32'h0000E063; // BLTU: imm=0x8 rs1 rs2 funct3=110 opcode=1100011
    opcode_ra_operand_i = 32'hFFFFFFF0;
    opcode_rb_operand_i = 32'h00000010;
    #20;

    // Test 29: BGEU (branch if greater or equal, unsigned)
    opcode_opcode_i = 32'h0000F063; // BGEU: imm=0x8 rs1 rs2 funct3=111 opcode=1100011
    opcode_ra_operand_i = 32'h00000010;
    opcode_rb_operand_i = 32'h00000010;
    #20;

    // End simulation
    #20;
    $finish;
end

endmodule