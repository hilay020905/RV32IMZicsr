`include "DEFINITIONS.v"
module lsu_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz)
    parameter MEM_CACHE_ADDR_MIN = 32'h00000000;
    parameter MEM_CACHE_ADDR_MAX = 32'hffffffff;

    // Signals
    reg           clk_i;
    reg           rst_i;
    reg           opcode_valid_i;
    reg  [31:0]   opcode_opcode_i;
    reg  [31:0]   opcode_pc_i;
    reg           opcode_invalid_i;
    reg  [4:0]    opcode_rd_idx_i;
    reg  [4:0]    opcode_ra_idx_i;
    reg  [4:0]    opcode_rb_idx_i;
    reg  [31:0]   opcode_ra_operand_i;
    reg  [31:0]   opcode_rb_operand_i;
    reg  [31:0]   mem_data_rd_i;
    reg           mem_accept_i;
    reg           mem_ack_i;
    reg           mem_error_i;
    reg  [10:0]   mem_resp_tag_i;
    reg           mem_load_fault_i;
    reg           mem_store_fault_i;

    wire [31:0]   mem_addr_o;
    wire [31:0]   mem_data_wr_o;
    wire          mem_rd_o;
    wire [3:0]    mem_wr_o;
    wire          mem_cacheable_o;
    wire [10:0]   mem_req_tag_o;
    wire          mem_invalidate_o;
    wire          mem_writeback_o;
    wire          mem_flush_o;
    wire          writeback_valid_o;
    wire [31:0]   writeback_value_o;
    wire [5:0]    writeback_exception_o;
    wire          stall_o;

    // Instantiate the LSU module
    LSU #(
        .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN),
        .MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
    ) u_lsu (
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
        .mem_data_rd_i(mem_data_rd_i),
        .mem_accept_i(mem_accept_i),
        .mem_ack_i(mem_ack_i),
        .mem_error_i(mem_error_i),
        .mem_resp_tag_i(mem_resp_tag_i),
        .mem_load_fault_i(mem_load_fault_i),
        .mem_store_fault_i(mem_store_fault_i),
        .mem_addr_o(mem_addr_o),
        .mem_data_wr_o(mem_data_wr_o),
        .mem_rd_o(mem_rd_o),
        .mem_wr_o(mem_wr_o),
        .mem_cacheable_o(mem_cacheable_o),
        .mem_req_tag_o(mem_req_tag_o),
        .mem_invalidate_o(mem_invalidate_o),
        .mem_writeback_o(mem_writeback_o),
        .mem_flush_o(mem_flush_o),
        .writeback_valid_o(writeback_valid_o),
        .writeback_value_o(writeback_value_o),
        .writeback_exception_o(writeback_exception_o),
        .stall_o(stall_o)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // VCD dump for GTKWave
    initial begin
        $dumpfile("lsu_waveform.vcd");
        $dumpvars(0, lsu_tb);
    end

    // Test stimulus
    initial begin
        // Initialize signals
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
        mem_data_rd_i = 0;
        mem_accept_i = 1;
        mem_ack_i = 0;
        mem_error_i = 0;
        mem_resp_tag_i = 0;
        mem_load_fault_i = 0;
        mem_store_fault_i = 0;

        // Reset
        #20 rst_i = 0;
        $display("Reset complete");

        // Test 1: Load Byte (LB) - Aligned
        $display("Test 1: Load Byte (LB) - Aligned");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_LB; // LB instruction
        opcode_ra_operand_i = 32'h00001000; // Aligned address
        opcode_pc_i = 32'h1000;
        opcode_rd_idx_i = 5'd1;
        opcode_ra_idx_i = 5'd2;
        #10;
        mem_ack_i = 1;
        mem_data_rd_i = 32'hDEADBEEF;
        #10;
        mem_ack_i = 0;
        opcode_valid_i = 0;
        #10;
        $display("LB Result: writeback_valid_o=%b, writeback_value_o=%h, writeback_exception_o=%h",
                 writeback_valid_o, writeback_value_o, writeback_exception_o);

        // Test 2: Store Word (SW) - Aligned
        $display("Test 2: Store Word (SW) - Aligned");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_SW; // SW instruction
        opcode_ra_operand_i = 32'h00002000; // Aligned address
        opcode_rb_operand_i = 32'hCAFEBABE;
        opcode_pc_i = 32'h1004;
        opcode_rd_idx_i = 5'd0;
        opcode_ra_idx_i = 5'd3;
        opcode_rb_idx_i = 5'd4;
        #10;
        mem_ack_i = 1;
        #10;
        mem_ack_i = 0;
        opcode_valid_i = 0;
        #10;
        $display("SW Result: mem_addr_o=%h, mem_data_wr_o=%h, mem_wr_o=%b",
                 mem_addr_o, mem_data_wr_o, mem_wr_o);

        // Test 3: Load Halfword (LH) - Unaligned
        $display("Test 3: Load Halfword (LH) - Unaligned");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_LH; // LH instruction
        opcode_ra_operand_i = 32'h00003001; // Unaligned address
        opcode_pc_i = 32'h1008;
        opcode_rd_idx_i = 5'd5;
        opcode_ra_idx_i = 5'd6;
        #10;
        #10;
        opcode_valid_i = 0;
        #10;
        $display("LH Unaligned Result: writeback_valid_o=%b, writeback_exception_o=%h",
                 writeback_valid_o, writeback_exception_o);

        // Test 4: DCache Flush (CSRRW)
        $display("Test 4: DCache Flush");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_CSRRW | (`CSR_DFLUSH << 20); // CSRRW with DFLUSH
        opcode_ra_operand_i = 32'h00004000;
        opcode_pc_i = 32'h100c;
        opcode_rd_idx_i = 5'd0;
        opcode_ra_idx_i = 5'd7;
        #10;
        mem_ack_i = 1;
        #10;
        mem_ack_i = 0;
        opcode_valid_i = 0;
        #10;
        $display("DCache Flush Result: mem_flush_o=%b", mem_flush_o);

        // Test 5: Load Byte with Bus Error
        $display("Test 5: Load Byte with Bus Error");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_LB; // LB instruction
        opcode_ra_operand_i = 32'h00005000; // Aligned address
        opcode_pc_i = 32'h1010;
        opcode_rd_idx_i = 5'd8;
        opcode_ra_idx_i = 5'd9;
        #10;
        mem_ack_i = 1;
        mem_error_i = 1;
        mem_load_fault_i = 1;
        #10;
        mem_ack_i = 0;
        mem_error_i = 0;
        mem_load_fault_i = 0;
        opcode_valid_i = 0;
        #10;
        $display("LB Bus Error Result: writeback_valid_o=%b, writeback_exception_o=%h",
                 writeback_valid_o, writeback_exception_o);

        // Test 6: Store Halfword (SH) - Aligned
        $display("Test 6: Store Halfword (SH) - Aligned");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_SH; // SH instruction
        opcode_ra_operand_i = 32'h00006000; // Aligned address
        opcode_rb_operand_i = 32'h0000BEEF;
        opcode_pc_i = 32'h1014;
        opcode_rd_idx_i = 5'd0;
        opcode_ra_idx_i = 5'd10;
        opcode_rb_idx_i = 5'd11;
        #10;
        mem_ack_i = 1;
        #10;
        mem_ack_i = 0;
        opcode_valid_i = 0;
        #10;
        $display("SH Result: mem_addr_o=%h, mem_data_wr_o=%h, mem_wr_o=%b",
                 mem_addr_o, mem_data_wr_o, mem_wr_o);

        // Test 7: DCache Invalidate
        $display("Test 7: DCache Invalidate");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_CSRRW | (`CSR_DINVALIDATE << 20); // CSRRW with DINVALIDATE
        opcode_ra_operand_i = 32'h00007000;
        opcode_pc_i = 32'h1018;
        opcode_rd_idx_i = 5'd0;
        opcode_ra_idx_i = 5'd12;
        #10;
        mem_ack_i = 1;
        #10;
        mem_ack_i = 0;
        opcode_valid_i = 0;
        #10;
        $display("DCache Invalidate Result: mem_invalidate_o=%b", mem_invalidate_o);

        // Finish simulation
        #100;
        $display("Simulation completed");
        $finish;
    end

endmodule