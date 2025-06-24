`timescale 1ns / 1ps

module NEXT_PC_PREDICT_tb;

    // Testbench signals
    reg clk_i;
    reg rst_i;
    reg invalidate_i;
    reg branch_request_i;
    reg branch_is_taken_i;
    reg branch_is_not_taken_i;
    reg branch_is_call_i;
    reg branch_is_ret_i;
    reg branch_is_jmp_i;
    reg [31:0] branch_source_i;
    reg [31:0] branch_pc_i;
    reg [31:0] pc_f_i;
    reg pc_accept_i;
    wire [31:0] next_pc_f_o;
    wire [1:0] next_taken_f_o;

    // Instantiate the DUT (Device Under Test)
    NEXT_PC_PREDICT u_dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .invalidate_i(invalidate_i),
        .branch_request_i(branch_request_i),
        .branch_is_taken_i(branch_is_taken_i),
        .branch_is_not_taken_i(branch_is_not_taken_i),
        .branch_is_call_i(branch_is_call_i),
        .branch_is_ret_i(branch_is_ret_i),
        .branch_is_jmp_i(branch_is_jmp_i),
        .branch_source_i(branch_source_i),
        .branch_pc_i(branch_pc_i),
        .pc_f_i(pc_f_i),
        .pc_accept_i(pc_accept_i),
        .next_pc_f_o(next_pc_f_o),
        .next_taken_f_o(next_taken_f_o)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100 MHz clock
    end

    // Test stimulus
    initial begin
        // Initialize VCD dump for GTKWave
        $dumpfile("NEXT_PC_PREDICT_tb.vcd");
        $dumpvars(0, NEXT_PC_PREDICT_tb);

        // Initialize inputs
        rst_i = 1;
        invalidate_i = 0;
        branch_request_i = 0;
        branch_is_taken_i = 0;
        branch_is_not_taken_i = 0;
        branch_is_call_i = 0;
        branch_is_ret_i = 0;
        branch_is_jmp_i = 0;
        branch_source_i = 32'h0;
        branch_pc_i = 32'h0;
        pc_f_i = 32'h0;
        pc_accept_i = 0;

        // Reset the system
        #20;
        rst_i = 0;

        // Test Case 1: Normal instruction fetch (no branch)
        #10;
        pc_f_i = 32'h00001000;
        pc_accept_i = 1;
        #10;
        pc_accept_i = 0;

        // Test Case 2: Branch taken (BTB miss, allocate new entry)
        #10;
        branch_request_i = 1;
        branch_is_taken_i = 1;
        branch_source_i = 32'h00001008;
        branch_pc_i = 32'h00002000;
        #10;
        branch_request_i = 0;
        branch_is_taken_i = 0;

        // Test Case 3: Fetch same PC (BTB hit, predict taken)
        #10;
        pc_f_i = 32'h00001008;
        pc_accept_i = 1;
        #10;
        pc_accept_i = 0;

        // Test Case 4: CALL instruction (push to RAS)
        #10;
        branch_request_i = 1;
        branch_is_call_i = 1;
        branch_source_i = 32'h00001010;
        branch_pc_i = 32'h00003000;
        #10;
        branch_request_i = 0;
        branch_is_call_i = 0;

        // Test Case 5: RETURN instruction (pop from RAS)
        #10;
        branch_request_i = 1;
        branch_is_ret_i = 1;
        branch_source_i = 32'h00003004;
        branch_pc_i = 32'h00001014; // Should match RAS pop
        #10;
        branch_request_i = 0;
        branch_is_ret_i = 0;

        // Test Case 6: Branch not taken
        #10;
        branch_request_i = 1;
        branch_is_not_taken_i = 1;
        branch_source_i = 32'h00001020;
        branch_pc_i = 32'h00001028;
        #10;
        branch_request_i = 0;
        branch_is_not_taken_i = 0;

        // Test Case 7: JUMP instruction
        #10;
        branch_request_i = 1;
        branch_is_jmp_i = 1;
        branch_source_i = 32'h00001030;
        branch_pc_i = 32'h00004000;
        #10;
        branch_request_i = 0;
        branch_is_jmp_i = 0;

        // Test Case 8: Invalidate prediction
        #10;
        invalidate_i = 1;
        #10;
        invalidate_i = 0;

        // Test Case 9: Multiple branches to test BHT
        #10;
        branch_request_i = 1;
        branch_is_taken_i = 1;
        branch_source_i = 32'h00001040;
        branch_pc_i = 32'h00005000;
        #10;
        branch_request_i = 0;
        branch_is_taken_i = 0;

        #10;
        branch_request_i = 1;
        branch_is_not_taken_i = 1;
        branch_source_i = 32'h00001048;
        branch_pc_i = 32'h00001050;
        #10;
        branch_request_i = 0;
        branch_is_not_taken_i = 0;

        // Run simulation for additional time
        #100;

        // End simulation
        $finish;
    end

endmodule