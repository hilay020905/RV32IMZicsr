     module fetch_tb;

         // Parameters
         parameter SUPPORT_MMU = 1; // Test both MMU and non-MMU configurations
         parameter CLK_PERIOD = 10; // Clock period in ns

         // Inputs
         reg           clk_i;
         reg           rst_i;
         reg           fetch_accept_i;
         reg           icache_accept_i;
         reg           icache_valid_i;
         reg           icache_error_i;
         reg  [63:0]   icache_inst_i;
         reg           icache_page_fault_i;
         reg           fetch_invalidate_i;
         reg           branch_request_i;
         reg  [31:0]   branch_pc_i;
         reg  [1:0]    branch_priv_i;
         reg  [31:0]   next_pc_f_i;
         reg  [1:0]    next_taken_f_i;

         // Outputs
         wire          fetch_valid_o;
         wire [63:0]   fetch_instr_o;
         wire [1:0]    fetch_pred_branch_o;
         wire          fetch_fault_fetch_o;
         wire          fetch_fault_page_o;
         wire [31:0]   fetch_pc_o;
         wire          icache_rd_o;
         wire          icache_flush_o;
         wire          icache_invalidate_o;
         wire [31:0]   icache_pc_o;
         wire [1:0]    icache_priv_o;
         wire [31:0]   pc_f_o;
         wire          pc_accept_o;

         // Instantiate the FETCH module
         FETCH #(
             .SUPPORT_MMU(SUPPORT_MMU)
         ) dut (
             .clk_i(clk_i),
             .rst_i(rst_i),
             .fetch_accept_i(fetch_accept_i),
             .icache_accept_i(icache_accept_i),
             .icache_valid_i(icache_valid_i),
             .icache_error_i(icache_error_i),
             .icache_inst_i(icache_inst_i),
             .icache_page_fault_i(icache_page_fault_i),
             .fetch_invalidate_i(fetch_invalidate_i),
             .branch_request_i(branch_request_i),
             .branch_pc_i(branch_pc_i),
             .branch_priv_i(branch_priv_i),
             .next_pc_f_i(next_pc_f_i),
             .next_taken_f_i(next_taken_f_i),
             .fetch_valid_o(fetch_valid_o),
             .fetch_instr_o(fetch_instr_o),
             .fetch_pred_branch_o(fetch_pred_branch_o),
             .fetch_fault_fetch_o(fetch_fault_fetch_o),
             .fetch_fault_page_o(fetch_fault_page_o),
             .fetch_pc_o(fetch_pc_o),
             .icache_rd_o(icache_rd_o),
             .icache_flush_o(icache_flush_o),
             .icache_invalidate_o(icache_invalidate_o),
             .icache_pc_o(icache_pc_o),
             .icache_priv_o(icache_priv_o),
             .pc_f_o(pc_f_o),
             .pc_accept_o(pc_accept_o)
         );

         // VCD generation for GTKWave
         initial begin
             $dumpfile("fetch_tb.vcd");
             $dumpvars(0, fetch_tb);
         end

         // Clock generation
         initial begin
             clk_i = 0;
             forever #(CLK_PERIOD/2) clk_i = ~clk_i;
         end

         // Test stimulus
         initial begin
             // Initialize inputs
             rst_i = 1;
             fetch_accept_i = 0;
             icache_accept_i = 0;
             icache_valid_i = 0;
             icache_error_i = 0;
             icache_inst_i = 64'h0;
             icache_page_fault_i = 0;
             fetch_invalidate_i = 0;
             branch_request_i = 0;
             branch_pc_i = 32'h0;
             branch_priv_i = 2'b11; // PRIV_MACHINE
             next_pc_f_i = 32'h0;
             next_taken_f_i = 2'b0;

             // Reset sequence
             #20 rst_i = 0;

             // Test case 1: Normal fetch without branch
             $display("Test Case 1: Normal Fetch");
             fetch_accept_i = 1;
             icache_accept_i = 1;
             next_pc_f_i = 32'h1000;
             next_taken_f_i = 2'b01;
             #10;
             icache_valid_i = 1;
             icache_inst_i = 64'hDEADBEEF00000000;
             #10;
             icache_valid_i = 0;
             #10;
             if (fetch_valid_o && fetch_pc_o == 32'h1000 && fetch_instr_o == 64'hDEADBEEF00000000)
                 $display("Test Case 1 Passed");
             else
                 $display("Test Case 1 Failed");

             // Test case 2: Branch request
             $display("Test Case 2: Branch Request");
             branch_request_i = 1;
             branch_pc_i = 32'h2000;
             branch_priv_i = 2'b01; // User mode
             #10;
             branch_request_i = 0;
             #10;
             icache_valid_i = 1;
             icache_inst_i = 64'hCAFEBABE00000000;
             #10;
             icache_valid_i = 0;
             #10;
             if (fetch_valid_o && fetch_pc_o == 32'h2000 && (SUPPORT_MMU ? icache_priv_o == 2'b01 : 1))
                 $display("Test Case 2 Passed");
             else
                 $display("Test Case 2 Failed");

             // Test case 3: Instruction cache stall
             $display("Test Case 3: ICache Stall");
             fetch_accept_i = 1;
             icache_accept_i = 0; // Simulate cache stall
             next_pc_f_i = 32'h3000;
             #20;
             icache_accept_i = 1;
             icache_valid_i = 1;
             icache_inst_i = 64'h1234567800000000;
             #10;
             icache_valid_i = 0;
             #10;
             if (fetch_valid_o && fetch_pc_o == 32'h3000)
                 $display("Test Case 3 Passed");
             else
                 $display("Test Case 3 Failed");

             // Test case 4: Fetch invalidate
             $display("Test Case 4: Fetch Invalidate");
             fetch_invalidate_i = 1;
             #10;
             fetch_invalidate_i = 0;
             #10;
             if (icache_flush_o)
                 $display("Test Case 4 Passed");
             else
                 $display("Test Case 4 Failed");

             // Test case 5: Skid buffer test (backpressure)
             $display("Test Case 5: Skid Buffer");
             fetch_accept_i = 0; // Simulate backpressure
             icache_valid_i = 1;
             icache_inst_i = 64'hAABBCCDD00000000;
             next_pc_f_i = 32'h4000;
             #10;
             icache_valid_i = 0;
             #10;
             fetch_accept_i = 1;
             #10;
             if (fetch_valid_o && fetch_instr_o == 64'hAABBCCDD00000000 && fetch_pc_o == 32'h4000)
                 $display("Test Case 5 Passed");
             else
                 $display("Test Case 5 Failed");

             // Test case 6: Fault handling
             $display("Test Case 6: Fault Handling");
             icache_valid_i = 1;
             icache_error_i = 1;
             icache_page_fault_i = 1;
             next_pc_f_i = 32'h5000;
             #10;
             icache_valid_i = 0;
             #10;
             if (fetch_fault_fetch_o && fetch_fault_page_o)
                 $display("Test Case 6 Passed");
             else
                 $display("Test Case 6 Failed");

             // End simulation
             #100;
             $finish;
         end

         // Monitor signals
         initial begin
             $monitor("Time=%0t rst_i=%b fetch_valid_o=%b fetch_pc_o=%h fetch_instr_o=%h icache_rd_o=%b icache_pc_o=%h",
                      $time, rst_i, fetch_valid_o, fetch_pc_o, fetch_instr_o, icache_rd_o, icache_pc_o);
         end

     endmodule