`timescale 1ns / 1ps
`include "DEFINITIONS.v" // Include macro definitions

// Define INST_NOP if not present in DEFINITIONS.v
`ifndef INST_NOP
`define INST_NOP 32'h00000013 // RISC-V NOP: ADDI x0, x0, 0
`endif

module DECODE_tb;

    // Parameters
    parameter SUPPORT_MULDIV = 1;
    parameter EXTRA_DECODE_STAGE = 1; // Test with extra decode stage enabled
    parameter CLK_PERIOD = 10; // Clock period in ns (100 MHz)

    // Inputs
    reg clk_i;
    reg rst_i;
    reg fetch_in_valid_i;
    reg [63:0] fetch_in_instr_i;
    reg [1:0] fetch_in_pred_branch_i;
    reg fetch_in_fault_fetch_i;
    reg fetch_in_fault_page_i;
    reg [31:0] fetch_in_pc_i;
    reg fetch_out0_accept_i;
    reg fetch_out1_accept_i;
    reg branch_request_i;
    reg [31:0] branch_pc_i;
    reg [1:0] branch_priv_i;

    // Outputs
    wire fetch_in_accept_o;
    wire fetch_out0_valid_o;
    wire [31:0] fetch_out0_instr_o;
    wire [31:0] fetch_out0_pc_o;
    wire fetch_out0_fault_fetch_o;
    wire fetch_out0_fault_page_o;
    wire fetch_out0_instr_exec_o;
    wire fetch_out0_instr_lsu_o;
    wire fetch_out0_instr_branch_o;
    wire fetch_out0_instr_mul_o;
    wire fetch_out0_instr_div_o;
    wire fetch_out0_instr_csr_o;
    wire fetch_out0_instr_rd_valid_o;
    wire fetch_out0_instr_invalid_o;
    wire fetch_out1_valid_o;
    wire [31:0] fetch_out1_instr_o;
    wire [31:0] fetch_out1_pc_o;
    wire fetch_out1_fault_fetch_o;
    wire fetch_out1_fault_page_o;
    wire fetch_out1_instr_exec_o;
    wire fetch_out1_instr_lsu_o;
    wire fetch_out1_instr_branch_o;
    wire fetch_out1_instr_mul_o;
    wire fetch_out1_instr_div_o;
    wire fetch_out1_instr_csr_o;
    wire fetch_out1_instr_rd_valid_o;
    wire fetch_out1_instr_invalid_o;

    // Instantiate the DECODE module
    DECODE #(
        .SUPPORT_MULDIV(SUPPORT_MULDIV),
        .EXTRA_DECODE_STAGE(EXTRA_DECODE_STAGE)
    ) u_decode (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .fetch_in_valid_i(fetch_in_valid_i),
        .fetch_in_instr_i(fetch_in_instr_i),
        .fetch_in_pred_branch_i(fetch_in_pred_branch_i),
        .fetch_in_fault_fetch_i(fetch_in_fault_fetch_i),
        .fetch_in_fault_page_i(fetch_in_fault_page_i),
        .fetch_in_pc_i(fetch_in_pc_i),
        .fetch_out0_accept_i(fetch_out0_accept_i),
        .fetch_out1_accept_i(fetch_out1_accept_i),
        .branch_request_i(branch_request_i),
        .branch_pc_i(branch_pc_i),
        .branch_priv_i(branch_priv_i),
        .fetch_in_accept_o(fetch_in_accept_o),
        .fetch_out0_valid_o(fetch_out0_valid_o),
        .fetch_out0_instr_o(fetch_out0_instr_o),
        .fetch_out0_pc_o(fetch_out0_pc_o),
        .fetch_out0_fault_fetch_o(fetch_out0_fault_fetch_o),
        .fetch_out0_fault_page_o(fetch_out0_fault_page_o),
        .fetch_out0_instr_exec_o(fetch_out0_instr_exec_o),
        .fetch_out0_instr_lsu_o(fetch_out0_instr_lsu_o),
        .fetch_out0_instr_branch_o(fetch_out0_instr_branch_o),
        .fetch_out0_instr_mul_o(fetch_out0_instr_mul_o),
        .fetch_out0_instr_div_o(fetch_out0_instr_div_o),
        .fetch_out0_instr_csr_o(fetch_out0_instr_csr_o),
        .fetch_out0_instr_rd_valid_o(fetch_out0_instr_rd_valid_o),
        .fetch_out0_instr_invalid_o(fetch_out0_instr_invalid_o),
        .fetch_out1_valid_o(fetch_out1_valid_o),
        .fetch_out1_instr_o(fetch_out1_instr_o),
        .fetch_out1_pc_o(fetch_out1_pc_o),
        .fetch_out1_fault_fetch_o(fetch_out1_fault_fetch_o),
        .fetch_out1_fault_page_o(fetch_out1_fault_page_o),
        .fetch_out1_instr_exec_o(fetch_out1_instr_exec_o),
        .fetch_out1_instr_lsu_o(fetch_out1_instr_lsu_o),
        .fetch_out1_instr_branch_o(fetch_out1_instr_branch_o),
        .fetch_out1_instr_mul_o(fetch_out1_instr_mul_o),
        .fetch_out1_instr_div_o(fetch_out1_instr_div_o),
        .fetch_out1_instr_csr_o(fetch_out1_instr_csr_o),
        .fetch_out1_instr_rd_valid_o(fetch_out1_instr_rd_valid_o),
        .fetch_out1_instr_invalid_o(fetch_out1_instr_invalid_o)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    // VCD file generation for GTKWave
    initial begin
        $dumpfile("decode_tb.vcd");
        $dumpvars(0, DECODE_tb);
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        rst_i = 1;
        fetch_in_valid_i = 0;
        fetch_in_instr_i = 64'h0;
        fetch_in_pred_branch_i = 2'b00;
        fetch_in_fault_fetch_i = 0;
        fetch_in_fault_page_i = 0;
        fetch_in_pc_i = 32'h1000;
        fetch_out0_accept_i = 0;
        fetch_out1_accept_i = 0;
        branch_request_i = 0;
        branch_pc_i = 32'h0;
        branch_priv_i = 2'b00;

        // Reset pulse
        #20 rst_i = 0;

        // Test 1: Valid instructions (ADDI and LW)
        #20;
        fetch_in_valid_i = 1;
        fetch_in_instr_i = {`INST_LW, `INST_ADDI}; // 64-bit instruction pair: LW, ADDI
        fetch_in_pred_branch_i = 2'b00;
        fetch_in_pc_i = 32'h1000;
        #10;
        fetch_out0_accept_i = 1; // Accept instruction 0
        fetch_out1_accept_i = 1; // Accept instruction 1
        #10;
        fetch_out0_accept_i = 0;
        fetch_out1_accept_i = 0;
        fetch_in_valid_i = 0;

        // Test 2: Branch instruction (JAL)
        #20;
        fetch_in_valid_i = 1;
        fetch_in_instr_i = {`INST_JAL, `INST_NOP}; // JAL, NOP
        fetch_in_pred_branch_i = 2'b01; // Predicted branch
        fetch_in_pc_i = 32'h1008;
        #10;
        fetch_out0_accept_i = 1;
        #10;
        fetch_out0_accept_i = 0;
        fetch_in_valid_i = 0;

        // Test 3: MUL instruction with SUPPORT_MULDIV enabled
        #20;
        fetch_in_valid_i = 1;
        fetch_in_instr_i = {`INST_MUL, `INST_ADDI}; // MUL, ADDI
        fetch_in_pc_i = 32'h1010;
        #10;
        fetch_out0_accept_i = 1;
        fetch_out1_accept_i = 1;
        #10;
        fetch_out0_accept_i = 0;
        fetch_out1_accept_i = 0;
        fetch_in_valid_i = 0;

        // Test 4: Invalid instruction
        #20;
        fetch_in_valid_i = 1;
        fetch_in_instr_i = {32'hFFFFFFFF, `INST_ADDI}; // Invalid, ADDI
        fetch_in_pc_i = 32'h1018;
        #10;
        fetch_out0_accept_i = 1;
        fetch_out1_accept_i = 1;
        #10;
        fetch_out0_accept_i = 0;
        fetch_out1_accept_i = 0;
        fetch_in_valid_i = 0;

        // Test 5: Fetch fault
        #20;
        fetch_in_valid_i = 1;
        fetch_in_fault_fetch_i = 1;
        fetch_in_instr_i = {`INST_LW, `INST_ADDI}; // Instructions ignored due to fault
        fetch_in_pc_i = 32'h1020;
        #10;
        fetch_out0_accept_i = 1;
        fetch_out1_accept_i = 1;
        #10;
        fetch_out0_accept_i = 0;
        fetch_out1_accept_i = 0;
        fetch_in_valid_i = 0;
        fetch_in_fault_fetch_i = 0;

        // Test 6: Branch request
        #20;
        branch_request_i = 1;
        branch_pc_i = 32'h2000;
        branch_priv_i = `PRIV_MACHINE;
        #10;
        branch_request_i = 0;
        #10;
        fetch_in_valid_i = 1;
        fetch_in_instr_i = {`INST_CSRRW, `INST_BEQ}; // CSRRW, BEQ
        fetch_in_pc_i = 32'h2000;
        #10;
        fetch_out0_accept_i = 1;
        fetch_out1_accept_i = 1;
        #10;
        fetch_out0_accept_i = 0;
        fetch_out1_accept_i = 0;
        fetch_in_valid_i = 0;

        // End simulation
        #100;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%t, clk=%b, rst=%b, fetch_in_valid=%b, fetch_in_instr=%h, fetch_out0_valid=%b, fetch_out0_instr=%h, fetch_out0_exec=%b, fetch_out0_lsu=%b, fetch_out0_branch=%b, fetch_out0_mul=%b, fetch_out0_div=%b, fetch_out0_csr=%b, fetch_out0_rd_valid=%b, fetch_out0_invalid=%b",
                 $time, clk_i, rst_i, fetch_in_valid_i, fetch_in_instr_i,
                 fetch_out0_valid_o, fetch_out0_instr_o, fetch_out0_instr_exec_o,
                 fetch_out0_instr_lsu_o, fetch_out0_instr_branch_o, fetch_out0_instr_mul_o,
                 fetch_out0_instr_div_o, fetch_out0_instr_csr_o, fetch_out0_instr_rd_valid_o,
                 fetch_out0_instr_invalid_o);
    end

endmodule