// Testbench for BiRISC-V Issue Module
`timescale 1ns / 1ps

`include "DEFINITIONS.v"

// Minimal macro definitions (assuming missing DEFINITIONS.v content)
`ifndef DEFINITIONS_V
`define EXCEPTION_W 6
`define EXCEPTION_FAULT_FETCH 6'h01
`define EXCEPTION_PAGE_FAULT_INST 6'h02
`define EXCEPTION_INTERRUPT 6'h03
`define EXCEPTION_MISALIGNED_FETCH 6'h04
`define EXCEPTION_MISALIGNED_LOAD 6'h05
`define EXCEPTION_FAULT_LOAD 6'h06
`define EXCEPTION_MISALIGNED_STORE 6'h07
`define EXCEPTION_FAULT_STORE 6'h08
`define EXCEPTION_PAGE_FAULT_LOAD 6'h09
`define EXCEPTION_PAGE_FAULT_STORE 6'h0A
`define PRIV_MACHINE 2'b11
`define INST_ADDI 32'h00100013 // Example: addi x0, x0, 1
`define INST_ADDI_MASK 32'h0000007F
`define INST_LUI 32'h00000037
`define INST_LUI_MASK 32'h0000007F
`define INST_JAL 32'h0000006F
`define INST_JAL_MASK 32'h0000007F
`define INST_BEQ 32'h00000063
`define INST_BEQ_MASK 32'h0000007F
`define INST_LW 32'h00000003
`define INST_LW_MASK 32'h0000007F
`define INST_SW 32'h00000023
`define INST_SW_MASK 32'h0000007F
`endif

module testbench;

    // Clock and reset
    reg clk_i;
    reg rst_i;

    // Fetch0 inputs
    reg fetch0_valid_i;
    reg [31:0] fetch0_instr_i;
    reg [31:0] fetch0_pc_i;
    reg fetch0_fault_fetch_i;
    reg fetch0_fault_page_i;
    reg fetch0_instr_exec_i;
    reg fetch0_instr_lsu_i;
    reg fetch0_instr_branch_i;
    reg fetch0_instr_mul_i;
    reg fetch0_instr_div_i;
    reg fetch0_instr_csr_i;
    reg fetch0_instr_rd_valid_i;
    reg fetch0_instr_invalid_i;

    // Fetch1 inputs
    reg fetch1_valid_i;
    reg [31:0] fetch1_instr_i;
    reg [31:0] fetch1_pc_i;
    reg fetch1_fault_fetch_i;
    reg fetch1_fault_page_i;
    reg fetch1_instr_exec_i;
    reg fetch1_instr_lsu_i;
    reg fetch1_instr_branch_i;
    reg fetch1_instr_mul_i;
    reg fetch1_instr_div_i;
    reg fetch1_instr_csr_i;
    reg fetch1_instr_rd_valid_i;
    reg fetch1_instr_invalid_i;

    // Branch inputs
    reg branch_exec0_request_i;
    reg branch_exec0_is_taken_i;
    reg branch_exec0_is_not_taken_i;
    reg [31:0] branch_exec0_source_i;
    reg branch_exec0_is_call_i;
    reg branch_exec0_is_ret_i;
    reg branch_exec0_is_jmp_i;
    reg [31:0] branch_exec0_pc_i;
    reg branch_d_exec0_request_i;
    reg [31:0] branch_d_exec0_pc_i;
    reg [1:0] branch_d_exec0_priv_i;
    reg branch_exec1_request_i;
    reg branch_exec1_is_taken_i;
    reg branch_exec1_is_not_taken_i;
    reg [31:0] branch_exec1_source_i;
    reg branch_exec1_is_call_i;
    reg branch_exec1_is_ret_i;
    reg branch_exec1_is_jmp_i;
    reg [31:0] branch_exec1_pc_i;
    reg branch_d_exec1_request_i;
    reg [31:0] branch_d_exec1_pc_i;
    reg [1:0] branch_d_exec1_priv_i;
    reg branch_csr_request_i;
    reg [31:0] branch_csr_pc_i;
    reg [1:0] branch_csr_priv_i;

    // Writeback inputs
    reg [31:0] writeback_exec0_value_i;
    reg [31:0] writeback_exec1_value_i;
    reg writeback_mem_valid_i;
    reg [31:0] writeback_mem_value_i;
    reg [5:0] writeback_mem_exception_i;
    reg [31:0] writeback_mul_value_i;
    reg writeback_div_valid_i;
    reg [31:0] writeback_div_value_i;
    reg [31:0] csr_result_e1_value_i;
    reg csr_result_e1_write_i;
    reg [31:0] csr_result_e1_wdata_i;
    reg [5:0] csr_result_e1_exception_i;
    reg lsu_stall_i;
    reg take_interrupt_i;

    // Outputs
    wire fetch0_accept_o;
    wire fetch1_accept_o;
    wire branch_request_o;
    wire [31:0] branch_pc_o;
    wire [1:0] branch_priv_o;
    wire branch_info_request_o;
    wire branch_info_is_taken_o;
    wire branch_info_is_not_taken_o;
    wire [31:0] branch_info_source_o;
    wire branch_info_is_call_o;
    wire branch_info_is_ret_o;
    wire branch_info_is_jmp_o;
    wire [31:0] branch_info_pc_o;
    wire exec0_opcode_valid_o;
    wire exec1_opcode_valid_o;
    wire lsu_opcode_valid_o;
    wire csr_opcode_valid_o;
    wire mul_opcode_valid_o;
    wire div_opcode_valid_o;
    wire [31:0] opcode0_opcode_o;
    wire [31:0] opcode0_pc_o;
    wire opcode0_invalid_o;
    wire [4:0] opcode0_rd_idx_o;
    wire [4:0] opcode0_ra_idx_o;
    wire [4:0] opcode0_rb_idx_o;
    wire [31:0] opcode0_ra_operand_o;
    wire [31:0] opcode0_rb_operand_o;
    wire [31:0] opcode1_opcode_o;
    wire [31:0] opcode1_pc_o;
    wire opcode1_invalid_o;
    wire [4:0] opcode1_rd_idx_o;
    wire [4:0] opcode1_ra_idx_o;
    wire [4:0] opcode1_rb_idx_o;
    wire [31:0] opcode1_ra_operand_o;
    wire [31:0] opcode1_rb_operand_o;
    wire [31:0] lsu_opcode_opcode_o;
    wire [31:0] lsu_opcode_pc_o;
    wire lsu_opcode_invalid_o;
    wire [4:0] lsu_opcode_rd_idx_o;
    wire [4:0] lsu_opcode_ra_idx_o;
    wire [4:0] lsu_opcode_rb_idx_o;
    wire [31:0] lsu_opcode_ra_operand_o;
    wire [31:0] lsu_opcode_rb_operand_o;
    wire [31:0] mul_opcode_opcode_o;
    wire [31:0] mul_opcode_pc_o;
    wire mul_opcode_invalid_o;
    wire [4:0] mul_opcode_rd_idx_o;
    wire [4:0] mul_opcode_ra_idx_o;
    wire  [4:0] mul_opcode_rb_idx_o;
    wire [31:0] mul_opcode_ra_operand_o;
    wire [31:0] mul_opcode_rb_operand_o;
    wire [31:0] csr_opcode_opcode_o;
    wire [31:0] csr_opcode_pc_o;
    wire csr_opcode_invalid_o;
    wire [4:0] csr_opcode_rd_idx_o;
    wire [4:0] csr_opcode_ra_idx_o;
    wire [4:0] csr_opcode_rb_idx_o;
    wire [31:0] csr_opcode_ra_operand_o;
    wire [31:0] csr_opcode_rb_operand_o;
    wire csr_writeback_write_o;
    wire [11:0] csr_writeback_waddr_o;
    wire [31:0] csr_writeback_wdata_o;
    wire [5:0] csr_writeback_exception_o;
    wire [31:0] csr_writeback_exception_pc_o;
    wire [31:0] csr_writeback_exception_addr_o;
    wire exec0_hold_o;
    wire exec1_hold_o;
    wire mul_hold_o;
    wire interrupt_inhibit_o;

    // Instantiate the DUT (Device Under Test)
    biriscv_issue #(
        .SUPPORT_MULDIV(1),
        .SUPPORT_DUAL_ISSUE(1),
        .SUPPORT_LOAD_BYPASS(1),
        .SUPPORT_MUL_BYPASS(1),
        .SUPPORT_REGFILE_XILINX(0)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .fetch0_valid_i(fetch0_valid_i),
        .fetch0_instr_i(fetch0_instr_i),
        .fetch0_pc_i(fetch0_pc_i),
        .fetch0_fault_fetch_i(fetch0_fault_fetch_i),
        .fetch0_fault_page_i(fetch0_fault_page_i),
        .fetch0_instr_exec_i(fetch0_instr_exec_i),
        .fetch0_instr_lsu_i(fetch0_instr_lsu_i),
        .fetch0_instr_branch_i(fetch0_instr_branch_i),
        .fetch0_instr_mul_i(fetch0_instr_mul_i),
        .fetch0_instr_div_i(fetch0_instr_div_i),
        .fetch0_instr_csr_i(fetch0_instr_csr_i),
        .fetch0_instr_rd_valid_i(fetch0_instr_rd_valid_i),
        .fetch0_instr_invalid_i(fetch0_instr_invalid_i),
        .fetch1_valid_i(fetch1_valid_i),
        .fetch1_instr_i(fetch1_instr_i),
        .fetch1_pc_i(fetch1_pc_i),
        .fetch1_fault_fetch_i(fetch1_fault_fetch_i),
        .fetch1_fault_page_i(fetch1_fault_page_i),
        .fetch1_instr_exec_i(fetch1_instr_exec_i),
        .fetch1_instr_lsu_i(fetch1_instr_lsu_i),
        .fetch1_instr_branch_i(fetch1_instr_branch_i),
        .fetch1_instr_mul_i(fetch1_instr_mul_i),
        .fetch1_instr_div_i(fetch1_instr_div_i),
        .fetch1_instr_csr_i(fetch1_instr_csr_i),
        .fetch1_instr_rd_valid_i(fetch1_instr_rd_valid_i),
        .fetch1_instr_invalid_i(fetch1_instr_invalid_i),
        .branch_exec0_request_i(branch_exec0_request_i),
        .branch_exec0_is_taken_i(branch_exec0_is_taken_i),
        .branch_exec0_is_not_taken_i(branch_exec0_is_not_taken_i),
        .branch_exec0_source_i(branch_exec0_source_i),
        .branch_exec0_is_call_i(branch_exec0_is_call_i),
        .branch_exec0_is_ret_i(branch_exec0_is_ret_i),
        .branch_exec0_is_jmp_i(branch_exec0_is_jmp_i),
        .branch_exec0_pc_i(branch_exec0_pc_i),
        .branch_d_exec0_request_i(branch_d_exec0_request_i),
        .branch_d_exec0_pc_i(branch_d_exec0_pc_i),
        .branch_d_exec0_priv_i(branch_d_exec0_priv_i),
        .branch_exec1_request_i(branch_exec1_request_i),
        .branch_exec1_is_taken_i(branch_exec1_is_taken_i),
        .branch_exec1_is_not_taken_i(branch_exec1_is_not_taken_i),
        .branch_exec1_source_i(branch_exec1_source_i),
        .branch_exec1_is_call_i(branch_exec1_is_call_i),
        .branch_exec1_is_ret_i(branch_exec1_is_ret_i),
        .branch_exec1_is_jmp_i(branch_exec1_is_jmp_i),
        .branch_exec1_pc_i(branch_exec1_pc_i),
        .branch_d_exec1_request_i(branch_d_exec1_request_i),
        .branch_d_exec1_pc_i(branch_d_exec1_pc_i),
        .branch_d_exec1_priv_i(branch_d_exec1_priv_i),
        .branch_csr_request_i(branch_csr_request_i),
        .branch_csr_pc_i(branch_csr_pc_i),
        .branch_csr_priv_i(branch_csr_priv_i),
        .writeback_exec0_value_i(writeback_exec0_value_i),
        .writeback_exec1_value_i(writeback_exec1_value_i),
        .writeback_mem_valid_i(writeback_mem_valid_i),
        .writeback_mem_value_i(writeback_mem_value_i),
        .writeback_mem_exception_i(writeback_mem_exception_i),
        .writeback_mul_value_i(writeback_mul_value_i),
        .writeback_div_valid_i(writeback_div_valid_i),
        .writeback_div_value_i(writeback_div_value_i),
        .csr_result_e1_value_i(csr_result_e1_value_i),
        .csr_result_e1_write_i(csr_result_e1_write_i),
        .csr_result_e1_wdata_i(csr_result_e1_wdata_i),
        .csr_result_e1_exception_i(csr_result_e1_exception_i),
        .lsu_stall_i(lsu_stall_i),
        .take_interrupt_i(take_interrupt_i),
        .fetch0_accept_o(fetch0_accept_o),
        .fetch1_accept_o(fetch1_accept_o),
        .branch_request_o(branch_request_o),
        .branch_pc_o(branch_pc_o),
        .branch_priv_o(branch_priv_o),
        .branch_info_request_o(branch_info_request_o),
        .branch_info_is_taken_o(branch_info_is_taken_o),
        .branch_info_is_not_taken_o(branch_info_is_not_taken_o),
        .branch_info_source_o(branch_info_source_o),
        .branch_info_is_call_o(branch_info_is_call_o),
        .branch_info_is_ret_o(branch_info_is_ret_o),
        .branch_info_is_jmp_o(branch_info_is_jmp_o),
        .branch_info_pc_o(branch_info_pc_o),
        .exec0_opcode_valid_o(exec0_opcode_valid_o),
        .exec1_opcode_valid_o(exec1_opcode_valid_o),
        .lsu_opcode_valid_o(lsu_opcode_valid_o),
        .csr_opcode_valid_o(csr_opcode_valid_o),
        .mul_opcode_valid_o(mul_opcode_valid_o),
        .div_opcode_valid_o(div_opcode_valid_o),
        .opcode0_opcode_o(opcode0_opcode_o),
        .opcode0_pc_o(opcode0_pc_o),
        .opcode0_invalid_o(opcode0_invalid_o),
        .opcode0_rd_idx_o(opcode0_rd_idx_o),
        .opcode0_ra_idx_o(opcode0_ra_idx_o),
        .opcode0_rb_idx_o(opcode0_rb_idx_o),
        .opcode0_ra_operand_o(opcode0_ra_operand_o),
        .opcode0_rb_operand_o(opcode0_rb_operand_o),
        .opcode1_opcode_o(opcode1_opcode_o),
        .opcode1_pc_o(opcode1_pc_o),
        .opcode1_invalid_o(opcode1_invalid_o),
        .opcode1_rd_idx_o(opcode1_rd_idx_o),
        .opcode1_ra_idx_o(opcode1_ra_idx_o),
        .opcode1_rb_idx_o(opcode1_rb_idx_o),
        .opcode1_ra_operand_o(opcode1_ra_operand_o),
        .opcode1_rb_operand_o(opcode1_rb_operand_o),
        .lsu_opcode_opcode_o(lsu_opcode_opcode_o),
        .lsu_opcode_pc_o(lsu_opcode_pc_o),
        .lsu_opcode_invalid_o(lsu_opcode_invalid_o),
        .lsu_opcode_rd_idx_o(lsu_opcode_rd_idx_o),
        .lsu_opcode_ra_idx_o(lsu_opcode_ra_idx_o),
        .lsu_opcode_rb_idx_o(lsu_opcode_rb_idx_o),
        .lsu_opcode_ra_operand_o(lsu_opcode_ra_operand_o),
        .lsu_opcode_rb_operand_o(lsu_opcode_rb_operand_o),
        .mul_opcode_opcode_o(mul_opcode_opcode_o),
        .mul_opcode_pc_o(mul_opcode_pc_o),
        .mul_opcode_invalid_o(mul_opcode_invalid_o),
        .mul_opcode_rd_idx_o(mul_opcode_rd_idx_o),
        .mul_opcode_ra_idx_o(mul_opcode_ra_idx_o),
        .mul_opcode_rb_idx_o(mul_opcode_rb_idx_o),
        .mul_opcode_ra_operand_o(mul_opcode_ra_operand_o),
        .mul_opcode_rb_operand_o(mul_opcode_rb_operand_o),
        .csr_opcode_opcode_o(csr_opcode_opcode_o),
        .csr_opcode_pc_o(csr_opcode_pc_o),
        .csr_opcode_invalid_o(csr_opcode_invalid_o),
        .csr_opcode_rd_idx_o(csr_opcode_rd_idx_o),
        .csr_opcode_ra_idx_o(csr_opcode_ra_idx_o),
        .csr_opcode_rb_idx_o(csr_opcode_rb_idx_o),
        .csr_opcode_ra_operand_o(csr_opcode_ra_operand_o),
        .csr_opcode_rb_operand_o(csr_opcode_rb_operand_o),
        .csr_writeback_write_o(csr_writeback_write_o),
        .csr_writeback_waddr_o(csr_writeback_waddr_o),
        .csr_writeback_wdata_o(csr_writeback_wdata_o),
        .csr_writeback_exception_o(csr_writeback_exception_o),
        .csr_writeback_exception_pc_o(csr_writeback_exception_pc_o),
        .csr_writeback_exception_addr_o(csr_writeback_exception_addr_o),
        .exec0_hold_o(exec0_hold_o),
        .exec1_hold_o(exec1_hold_o),
        .mul_hold_o(mul_hold_o),
        .interrupt_inhibit_o(interrupt_inhibit_o)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100 MHz clock (10 ns period)
    end

    // Reset and stimulus
    initial begin
        // Initialize VCD dump
        $dumpfile("waveform.vcd");
        $dumpvars(0, testbench);

        // Initialize inputs
        rst_i = 1;
        fetch0_valid_i = 0;
        fetch0_instr_i = 0;
        fetch0_pc_i = 0;
        fetch0_fault_fetch_i = 0;
        fetch0_fault_page_i = 0;
        fetch0_instr_exec_i = 0;
        fetch0_instr_lsu_i = 0;
        fetch0_instr_branch_i = 0;
        fetch0_instr_mul_i = 0;
        fetch0_instr_div_i = 0;
        fetch0_instr_csr_i = 0;
        fetch0_instr_rd_valid_i = 0;
        fetch0_instr_invalid_i = 0;
        fetch1_valid_i = 0;
        fetch1_instr_i = 0;
        fetch1_pc_i = 0;
        fetch1_fault_fetch_i = 0;
        fetch1_fault_page_i = 0;
        fetch1_instr_exec_i = 0;
        fetch1_instr_lsu_i = 0;
        fetch1_instr_branch_i = 0;
        fetch1_instr_mul_i = 0;
        fetch1_instr_div_i = 0;
        fetch1_instr_csr_i = 0;
        fetch1_instr_rd_valid_i = 0;
        fetch1_instr_invalid_i = 0;
        branch_exec0_request_i = 0;
        branch_exec0_is_taken_i = 0;
        branch_exec0_is_not_taken_i = 0;
        branch_exec0_source_i = 0;
        branch_exec0_is_call_i = 0;
        branch_exec0_is_ret_i = 0;
        branch_exec0_is_jmp_i = 0;
        branch_exec0_pc_i = 0;
        branch_d_exec0_request_i = 0;
        branch_d_exec0_pc_i = 0;
        branch_d_exec0_priv_i = 0;
        branch_exec1_request_i = 0;
        branch_exec1_is_taken_i = 0;
        branch_exec1_is_not_taken_i = 0;
        branch_exec1_source_i = 0;
        branch_exec1_is_call_i = 0;
        branch_exec1_is_ret_i = 0;
        branch_exec1_is_jmp_i = 0;
        branch_exec1_pc_i = 0;
        branch_d_exec1_request_i = 0;
        branch_d_exec1_pc_i = 0;
        branch_d_exec1_priv_i = 0;
        branch_csr_request_i = 0;
        branch_csr_pc_i = 0;
        branch_csr_priv_i = 0;
        writeback_exec0_value_i = 0;
        writeback_exec1_value_i = 0;
        writeback_mem_valid_i = 0;
        writeback_mem_value_i = 0;
        writeback_mem_exception_i = 0;
        writeback_mul_value_i = 0;
        writeback_div_valid_i = 0;
        writeback_div_value_i = 0;
        csr_result_e1_value_i = 0;
        csr_result_e1_write_i = 0;
        csr_result_e1_wdata_i = 0;
        csr_result_e1_exception_i = 0;
        lsu_stall_i = 0;
        take_interrupt_i = 0;

        // Apply reset
        #20 rst_i = 0;

        // Test sequence
        // Test 1: Issue an ADDI instruction (addi x5, x0, 10)
        #10;
        fetch0_valid_i = 1;
        fetch0_pc_i = 32'h1000;
        fetch0_instr_i = 32'h00a00293; // addi x5, x0, 10
        fetch0_instr_exec_i = 1;
        fetch0_instr_rd_valid_i = 1;
        writeback_exec0_value_i = 32'h0000000A; // ALU result = 10
        #10;
        writeback_exec0_value_i = 0;
        fetch0_valid_i = 0;
        fetch0_instr_exec_i = 0;
        fetch0_instr_rd_valid_i = 0;

        // Test 2: Dual issue with ADDI and LUI (addi x6, x0, 20; lui x7, 0x1000)
        #10;
        fetch0_valid_i = 1;
        fetch0_pc_i = 32'h1004;
        fetch0_instr_i = 32'h01400313; // addi x6, x0, 20
        fetch0_instr_exec_i = 1;
        fetch0_instr_rd_valid_i = 1;
        fetch1_valid_i = 1;
        fetch1_pc_i = 32'h1008;
        fetch1_instr_i = 32'h010003b7; // lui x7, 0x1000
        fetch1_instr_exec_i = 1;
        fetch1_instr_rd_valid_i = 1;
        writeback_exec0_value_i = 32'h00000014; // ALU result = 20
        writeback_exec1_value_i = 32'h01000000; // ALU result = 0x1000 << 12
        #10;
        fetch0_valid_i = 0;
        fetch1_valid_i = 0;
        fetch0_instr_exec_i = 0;
        fetch0_instr_rd_valid_i = 0;
        fetch1_instr_exec_i = 0;
        fetch1_instr_rd_valid_i = 0;
        writeback_exec0_value_i = 0;
        writeback_exec1_value_i = 0;

        // Test 3: Load instruction (lw x8, 0(x5))
        #10;
        fetch0_valid_i = 1;
        fetch0_pc_i = 32'h100C;
        fetch0_instr_i = 32'h0002a403; // lw x8, 0(x5)
        fetch0_instr_lsu_i = 1;
        fetch0_instr_rd_valid_i = 1;
        #10;
        writeback_mem_valid_i = 1;
        writeback_mem_value_i = 32'hDEADBEEF; // Memory data
        #10;
        fetch0_valid_i = 0;
        fetch0_instr_lsu_i = 0;
        fetch0_instr_rd_valid_i = 0;
        writeback_mem_valid_i = 0;
        writeback_mem_value_i = 0;

        // Test 4: Store instruction (sw x6, 4(x5))
        #10;
        fetch0_valid_i = 1;
        fetch0_pc_i = 32'h1010;
        fetch0_instr_i = 32'h0062a223; // sw x6, 4(x5)
        fetch0_instr_lsu_i = 1;
        #10;
        writeback_mem_valid_i = 1;
        writeback_mem_value_i = 0; // Store doesn't return a value
        #10;
        fetch0_valid_i = 0;
        fetch0_instr_lsu_i = 0;
        writeback_mem_valid_i = 0;

        // Test 5: Branch instruction (beq x5, x6, 8)
        #10;
        fetch0_valid_i = 1;
        fetch0_pc_i = 32'h1014;
        fetch0_instr_i = 32'h00628663; // beq x5, x6, 8
        fetch0_instr_branch_i = 1;
        branch_exec0_request_i = 1;
        branch_exec0_is_taken_i = 1;
        branch_exec0_pc_i = 32'h101C; // Target PC
        branch_exec0_source_i = 32'h1014;
        #10;
        fetch0_valid_i = 0;
        fetch0_instr_branch_i = 0;
        branch_exec0_request_i = 0;
        branch_exec0_is_taken_i = 0;

        // Test 6: Simulate a stall
        #10;
        fetch0_valid_i = 1;
        fetch0_pc_i = 32'h101C;
        fetch0_instr_i = 32'h00a00293; // addi x5, x0, 10
        fetch0_instr_exec_i = 1;
        fetch0_instr_rd_valid_i = 1;
        lsu_stall_i = 1; // Simulate LSU stall
        #20;
        lsu_stall_i = 0;
        writeback_exec0_value_i = 32'h0000000A;
        #10;
        fetch0_valid_i = 0;
        fetch0_instr_exec_i = 0;
        fetch0_instr_rd_valid_i = 0;
        writeback_exec0_value_i = 0;

        // Test 7: Interrupt
        #10;
        take_interrupt_i = 1;
        branch_csr_request_i = 1;
        branch_csr_pc_i = 32'h2000;
        branch_csr_priv_i = `PRIV_MACHINE;
        #10;
        take_interrupt_i = 0;
        branch_csr_request_i = 0;

        // End simulation
        #100;
        $finish;
    end

endmodule