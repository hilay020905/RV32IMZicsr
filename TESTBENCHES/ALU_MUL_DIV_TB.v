`timescale 1ns / 1ps

`include "DEFINITIONS.v"

module testbench;

    // ALU signals
    reg  [3:0]   alu_op_i;
    reg  [31:0]  alu_a_i;
    reg  [31:0]  alu_b_i;
    wire [31:0]  alu_p_o;

    // DIVIDER signals
    reg          clk_i;
    reg          rst_i;
    reg          opcode_valid_i_div;
    reg  [31:0]  opcode_opcode_i_div;
    reg  [31:0]  opcode_pc_i_div;
    reg          opcode_invalid_i_div;
    reg  [4:0]   opcode_rd_idx_i_div;
    reg  [4:0]   opcode_ra_idx_i_div;
    reg  [4:0]   opcode_rb_idx_i_div;
    reg  [31:0]  opcode_ra_operand_i_div;
    reg  [31:0]  opcode_rb_operand_i_div;
    wire         writeback_valid_o_div;
    wire [31:0]  writeback_value_o_div;

    // MULTIPLIER signals
    reg          opcode_valid_i_mul;
    reg  [31:0]  opcode_opcode_i_mul;
    reg  [31:0]  opcode_pc_i_mul;
    reg          opcode_invalid_i_mul;
    reg  [4:0]   opcode_rd_idx_i_mul;
    reg  [4:0]   opcode_ra_idx_i_mul;
    reg  [4:0]   opcode_rb_idx_i_mul;
    reg  [31:0]  opcode_ra_operand_i_mul;
    reg  [31:0]  opcode_rb_operand_i_mul;
    reg          hold_i;
    wire [31:0]  writeback_value_o_mul;

    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100 MHz clock
    end

    // Instantiate modules
    ALU alu (
        .alu_op_i(alu_op_i),
        .alu_a_i(alu_a_i),
        .alu_b_i(alu_b_i),
        .alu_p_o(alu_p_o)
    );

    DIVIDER divider (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .opcode_valid_i(opcode_valid_i_div),
        .opcode_opcode_i(opcode_opcode_i_div),
        .opcode_pc_i(opcode_pc_i_div),
        .opcode_invalid_i(opcode_invalid_i_div),
        .opcode_rd_idx_i(opcode_rd_idx_i_div),
        .opcode_ra_idx_i(opcode_ra_idx_i_div),
        .opcode_rb_idx_i(opcode_rb_idx_i_div),
        .opcode_ra_operand_i(opcode_ra_operand_i_div),
        .opcode_rb_operand_i(opcode_rb_operand_i_div),
        .writeback_valid_o(writeback_valid_o_div),
        .writeback_value_o(writeback_value_o_div)
    );

    MULTIPLIER multiplier (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .opcode_valid_i(opcode_valid_i_mul),
        .opcode_opcode_i(opcode_opcode_i_mul),
        .opcode_pc_i(opcode_pc_i_mul),
        .opcode_invalid_i(opcode_invalid_i_mul),
        .opcode_rd_idx_i(opcode_rd_idx_i_mul),
        .opcode_ra_idx_i(opcode_ra_idx_i_mul),
        .opcode_rb_idx_i(opcode_rb_idx_i_mul),
        .opcode_ra_operand_i(opcode_ra_operand_i_mul),
        .opcode_rb_operand_i(opcode_rb_operand_i_mul),
        .hold_i(hold_i),
        .writeback_value_o(writeback_value_o_mul)
    );

    // VCD dump for GTKWave
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, testbench);
        // Dump internal DIVIDER signals for debugging
        $dumpvars(1, testbench.divider.div_busy_q);
        $dumpvars(1, testbench.divider.q_mask_q);
        $dumpvars(1, testbench.divider.div_complete_w);
        $dumpvars(1, testbench.divider.div_start_w);
        $dumpvars(1, testbench.divider.div_rem_inst_w);
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst_i = 1;
        alu_op_i = 4'b0;
        alu_a_i = 32'b0;
        alu_b_i = 32'b0;
        opcode_valid_i_div = 0;
        opcode_opcode_i_div = 32'b0;
        opcode_pc_i_div = 32'b0;
        opcode_invalid_i_div = 0;
        opcode_rd_idx_i_div = 5'b0;
        opcode_ra_idx_i_div = 5'b0;
        opcode_rb_idx_i_div = 5'b0;
        opcode_ra_operand_i_div = 32'b0;
        opcode_rb_operand_i_div = 32'b0;
        opcode_valid_i_mul = 0;
        opcode_opcode_i_mul = 32'b0;
        opcode_pc_i_mul = 32'b0;
        opcode_invalid_i_mul = 0;
        opcode_rd_idx_i_mul = 5'b0;
        opcode_ra_idx_i_mul = 5'b0;
        opcode_rb_idx_i_mul = 5'b0;
        opcode_ra_operand_i_mul = 32'b0;
        opcode_rb_operand_i_mul = 32'b0;
        hold_i = 0;

        // Reset
        #20 rst_i = 0;
        $display("Time: %0t, Reset deasserted", $time);

        // Test ALU operations
        #10;
        alu_op_i = `ALU_ADD;
        alu_a_i = 32'h0000000A;
        alu_b_i = 32'h00000005;
        $display("Time: %0t, ALU ADD: a=%h, b=%h, p=%h", $time, alu_a_i, alu_b_i, alu_p_o);
        #10; // Expected: alu_p_o = 0xF (15)

        alu_op_i = `ALU_SUB;
        alu_a_i = 32'h0000000A;
        alu_b_i = 32'h00000005;
        $display("Time: %0t, ALU SUB: a=%h, b=%h, p=%h", $time, alu_a_i, alu_b_i, alu_p_o);
        #10; // Expected: alu_p_o = 0x5

        alu_op_i = `ALU_SHIFTL;
        alu_a_i = 32'h00000001;
        alu_b_i = 32'h00000002;
        $display("Time: %0t, ALU SHIFTL: a=%h, b=%h, p=%h", $time, alu_a_i, alu_b_i, alu_p_o);
        #10; // Expected: alu_p_o = 0x4

        alu_op_i = `ALU_SHIFTR_ARITH;
        alu_a_i = 32'h80000000;
        alu_b_i = 32'h00000001;
        $display("Time: %0t, ALU SHIFTR_ARITH: a=%h, b=%h, p=%h", $time, alu_a_i, alu_b_i, alu_p_o);
        #10; // Expected: alu_p_o = 0xC0000000

        alu_op_i = `ALU_AND;
        alu_a_i = 32'h000000FF;
        alu_b_i = 32'h0000000F;
        $display("Time: %0t, ALU AND: a=%h, b=%h, p=%h", $time, alu_a_i, alu_b_i, alu_p_o);
        #10; // Expected: alu_p_o = 0xF

        alu_op_i = `ALU_LESS_THAN_SIGNED;
        alu_a_i = 32'hFFFFFFFE; // -2
        alu_b_i = 32'h00000001; // 1
        $display("Time: %0t, ALU LESS_THAN_SIGNED: a=%h, b=%h, p=%h", $time, alu_a_i, alu_b_i, alu_p_o);
        #10; // Expected: alu_p_o = 0x1

        // Test DIVIDER operations
        #10;
        opcode_valid_i_div = 1;
        opcode_opcode_i_div = `INST_DIV;
        opcode_ra_operand_i_div = 32'h00000014; // 20
        opcode_rb_operand_i_div = 32'h00000005; // 5
        $display("Time: %0t, DIV Start: opcode=%h, dividend=%h, divisor=%h", $time, opcode_opcode_i_div, opcode_ra_operand_i_div, opcode_rb_operand_i_div);
        #350; // Extended to 350ns to ensure completion
        opcode_valid_i_div = 0;
        $display("Time: %0t, DIV Result: valid=%b, result=%h", $time, writeback_valid_o_div, writeback_value_o_div);
        // Expected: writeback_value_o_div = 0x4, writeback_valid_o_div = 1

        #10;
        opcode_valid_i_div = 1;
        opcode_opcode_i_div = `INST_REM;
        opcode_ra_operand_i_div = 32'h00000014; // 20
        opcode_rb_operand_i_div = 32'h00000005; // 5
        $display("Time: %0t, REM Start: opcode=%h, dividend=%h, divisor=%h", $time, opcode_opcode_i_div, opcode_ra_operand_i_div, opcode_rb_operand_i_div);
        #350; // Extended to 350ns
        opcode_valid_i_div = 0;
        $display("Time: %0t, REM Result: valid=%b, result=%h", $time, writeback_valid_o_div, writeback_value_o_div);
        // Expected: writeback_value_o_div = 0x0, writeback_valid_o_div = 1

        // Test MULTIPLIER operations
        #10;
        opcode_valid_i_mul = 1;
        opcode_opcode_i_mul = `INST_MUL;
        opcode_ra_operand_i_mul = 32'h0000000A; // 10
        opcode_rb_operand_i_mul = 32'h00000003; // 3
        $display("Time: %0t, MUL Start: opcode=%h, a=%h, b=%h", $time, opcode_opcode_i_mul, opcode_ra_operand_i_mul, opcode_rb_operand_i_mul);
        #30; // Wait for 3 cycles
        opcode_valid_i_mul = 0;
        $display("Time: %0t, MUL Result: result=%h", $time, writeback_value_o_mul);
        // Expected: writeback_value_o_mul = 0x1E (30)

        #10;
        opcode_valid_i_mul = 1;
        opcode_opcode_i_mul = `INST_MULH;
        opcode_ra_operand_i_mul = 32'h80000000; // -2^31
        opcode_rb_operand_i_mul = 32'h00000002; // 2
        $display("Time: %0t, MULH Start: opcode=%h, a=%h, b=%h", $time, opcode_opcode_i_mul, opcode_ra_operand_i_mul, opcode_rb_operand_i_mul);
        #30; // Wait for 3 cycles
        opcode_valid_i_mul = 0;
        $display("Time: %0t, MULH Result: result=%h", $time, writeback_value_o_mul);
        // Expected: writeback_value_o_mul = 0xFFFFFFFF (-1)

        // Finish simulation
        #100;
        $finish;
    end

endmodule