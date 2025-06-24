//HILAY_PATEL
module NEXT_PC_PREDICT
#(
     parameter SUPPORT_BRANCH_PREDICTION = 1, // To support branch prediction
     parameter NUM_BTB_ENTRIES  = 32,        // Number of branch target buffer entries
     parameter NUM_BTB_ENTRIES_W = 5,        // Number of bits required for BTB 
     parameter BHT_ENABLE       = 1,         // To enable branch history table
     parameter NUM_BHT_ENTRIES  = 512,       // Number of entries to BHT
     parameter NUM_BHT_ENTRIES_W = 9,        // Number of bits required for BHT
     parameter RAS_ENABLE       = 1,         // To enable return address stack
     parameter NUM_RAS_ENTRIES  = 8,         // Number of entries to RAS
     parameter NUM_RAS_ENTRIES_W = 3,        // Number of bits required for RAS
     parameter GSHARE_ENABLE    = 0          // To enable Gshare
)
(
    input           clk_i,               // clock
    input           rst_i,               // reset (active high)
    input           invalidate_i,        // Invalidate prediction logic (e.g., on pipeline flush)
    input           branch_request_i,    // Actual branch occurred (from execute stage)
    input           branch_is_taken_i,   // Branch was actually taken
    input           branch_is_not_taken_i, // Branch was actually not taken
    input  [31:0]   branch_source_i,     // PC of the instruction that caused the branch
    input           branch_is_call_i,    // Indicates if the branch is a CALL instruction
    input           branch_is_ret_i,     // Indicates if the branch is a RET instruction
    input           branch_is_jmp_i,     // Indicates if the branch is a JMP instruction
    input  [31:0]   branch_pc_i,         // Target address of the actual branch
    input  [31:0]   pc_f_i,              // Current PC in fetch stage (used for prediction)
    input           pc_accept_i,         // Fetch stage accepted the current PC (valid instruction fetch)
    output [31:0]   next_pc_f_o,         // Predicted next PC for the fetch stage
    output [1:0]    next_taken_f_o       // Prediction info: taken/not taken 
);

localparam RAS_INVALID = 32'h00000001;

// Declare intermediate wires used in generate block
wire btb_valid_w;
wire btb_is_call_w;
wire btb_is_ret_w;
wire pred_taken_w;
wire pred_ntaken_w;

// RAS (Actual)
// This tracks the real CALL/RETURN history committed in the pipeline
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_real_q; // RAS current index
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_real_r; // RAS next value

always @* 
begin
    ras_index_real_r = ras_index_real_q;
    if (branch_request_i & branch_is_call_i)
        ras_index_real_r = ras_index_real_q + 1; // CALL
    else if (branch_request_i & branch_is_ret_i)
        ras_index_real_r = ras_index_real_q - 1; // RETURN
end

always @(posedge clk_i or posedge rst_i)
    if (rst_i)
        ras_index_real_q <= {NUM_RAS_ENTRIES_W{1'b0}}; // Concatenation replication
    else
        ras_index_real_q <= ras_index_real_r;

// RAS (Speculative)
// This tracks speculative CALL/RETURN guesses during instruction fetch
reg [31:0] ras_stack_q[NUM_RAS_ENTRIES-1:0];     // RAS memory
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_q;         // speculative pointer
reg [NUM_RAS_ENTRIES_W-1:0] ras_index_r;         // next value

wire [31:0] ras_pc_pred_w = ras_stack_q[ras_index_q]; // Predicted return address = top of the speculative stack
wire ras_call_pred_w = RAS_ENABLE & (btb_valid_w & btb_is_call_w) & ~ras_pc_pred_w[0]; // Predict: is this a CALL instruction at fetch stage?
wire ras_ret_pred_w  = RAS_ENABLE & (btb_valid_w & btb_is_ret_w)  & ~ras_pc_pred_w[0];

always @* begin
    ras_index_r = ras_index_q;

    if (branch_request_i & branch_is_call_i)
        ras_index_r = ras_index_real_q + 1; // CALL
    else if (branch_request_i & branch_is_ret_i)
        ras_index_r = ras_index_real_q - 1; // RETURN
    else if (ras_call_pred_w & pc_accept_i)
        ras_index_r = ras_index_q + 1;
    else if (ras_ret_pred_w & pc_accept_i)
        ras_index_r = ras_index_q - 1;
end

integer i3;
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        for (i3 = 0; i3 < NUM_RAS_ENTRIES; i3 = i3 + 1)
            ras_stack_q[i3] <= RAS_INVALID;      // Initialize stack entries
        ras_index_q <= {NUM_RAS_ENTRIES_W{1'b0}}; // Reset stack pointer
    end
    // Real PUSH, CALL return address
    else if (branch_request_i & branch_is_call_i) begin
        ras_stack_q[ras_index_r] <= branch_source_i + 32'd4;
        ras_index_q              <= ras_index_r;
    end
    // Predicted CALL, Push predicted return address
    else if (ras_call_pred_w & pc_accept_i) begin
        ras_stack_q[ras_index_r] <= (btb_upper_r ? (pc_f_i | 32'd4) : pc_f_i) + 32'd4;
        ras_index_q              <= ras_index_r;
    end
    // RETURN (real or predicted), Pop
    else if ((ras_ret_pred_w & pc_accept_i) || (branch_request_i & branch_is_ret_i)) begin
        ras_index_q <= ras_index_r; // Just decrement index
    end
end

// BHT
// Global history register (actual history)
reg [NUM_BHT_ENTRIES_W-1:0] global_history_real_q;

// This register holds the actual (non-speculative) history of branch outcomes.
// On reset, clear the history.
// On any resolved branch (taken or not), shift in the latest outcome bit.
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    global_history_real_q <= {NUM_BHT_ENTRIES_W{1'b0}};
else if (branch_is_taken_i || branch_is_not_taken_i)
    global_history_real_q <= {global_history_real_q[NUM_BHT_ENTRIES_W-2:0], branch_is_taken_i};

// Global history register (speculative)
reg [NUM_BHT_ENTRIES_W-1:0] global_history_q;

// This register holds the speculative history, which assumes predictions are correct.
// It is updated on predictions and restored from real history on misprediction.
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    global_history_q <= {NUM_BHT_ENTRIES_W{1'b0}};
// On misprediction, copy real history and add the resolved result.
else if (branch_request_i)
    global_history_q <= {global_history_real_q[NUM_BHT_ENTRIES_W-2:0], branch_is_taken_i};
// On correct prediction, shift in the speculative result.
else if (pred_taken_w || pred_ntaken_w)
    global_history_q <= {global_history_q[NUM_BHT_ENTRIES_W-2:0], pred_taken_w};

// GShare indexing: Use XOR between history and PC bits
wire [NUM_BHT_ENTRIES_W-1:0] gshare_wr_entry_w = 
    (branch_request_i ? global_history_real_q : global_history_q) 
    ^ branch_source_i[2+NUM_BHT_ENTRIES_W-1:2];

wire [NUM_BHT_ENTRIES_W-1:0] gshare_rd_entry_w = 
    global_history_q ^ {pc_f_i[3+NUM_BHT_ENTRIES_W-2:3], btb_upper_r};

// Branch prediction table (BHT): 2-bit saturating counters
reg [1:0] bht_sat_q[NUM_BHT_ENTRIES-1:0];

// Choose read/write index: use GShare or direct indexing
wire [NUM_BHT_ENTRIES_W-1:0] bht_wr_entry_w = 
    GSHARE_ENABLE ? gshare_wr_entry_w : branch_source_i[2+NUM_BHT_ENTRIES_W-1:2];

wire [NUM_BHT_ENTRIES_W-1:0] bht_rd_entry_w = 
    GSHARE_ENABLE ? gshare_rd_entry_w : {pc_f_i[3+NUM_BHT_ENTRIES_W-2:3], btb_upper_r};

// Update BHT on resolved branch outcomes
integer i4;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    // On reset: initialize all BHT counters to 'strongly taken' (2'd3)
    for (i4 = 0; i4 < NUM_BHT_ENTRIES; i4 = i4 + 1)
        bht_sat_q[i4] <= 2'd3;
end
// If branch was taken, increase prediction confidence
else if (branch_is_taken_i && bht_sat_q[bht_wr_entry_w] < 2'd3)
    bht_sat_q[bht_wr_entry_w] <= bht_sat_q[bht_wr_entry_w] + 2'd1;
// If not taken, decrease prediction confidence
else if (branch_is_not_taken_i && bht_sat_q[bht_wr_entry_w] > 2'd0)
    bht_sat_q[bht_wr_entry_w] <= bht_sat_q[bht_wr_entry_w] - 2'd1;

// Final branch prediction result
// If BHT is enabled, predict taken if 2-bit counter is ≥ 2
wire bht_predict_taken_w = BHT_ENABLE && (bht_sat_q[bht_rd_entry_w] >= 2'd2);

// Branch target buffer arrays (each index = 1 BTB entry)
reg [31:0]  btb_pc_q[NUM_BTB_ENTRIES-1:0];      // Stores PC addresses of branches
reg [31:0]  btb_target_q[NUM_BTB_ENTRIES-1:0];  // Stores predicted target addresses
reg         btb_is_call_q[NUM_BTB_ENTRIES-1:0]; // Marks if entry is a CALL
reg         btb_is_ret_q[NUM_BTB_ENTRIES-1:0];  // Marks if entry is a RET
reg         btb_is_jmp_q[NUM_BTB_ENTRIES-1:0];  // Marks if entry is a JUMP

// Intermediate signals for current fetch PC lookup
reg         btb_valid_r;     // Match found
reg         btb_upper_r;     // Marks PC[2] (for compressed instruction handling)
reg         btb_is_call_r;   // Matched entry is a CALL
reg         btb_is_ret_r;    // Matched entry is a RET
reg [31:0]  btb_next_pc_r;   // Target predicted address
reg         btb_is_jmp_r;    // Matched entry is a JUMP
reg [NUM_BTB_ENTRIES_W-1:0] btb_entry_r; // Matched entry index

integer i0;  
always @ *
begin
    // Default: no match, default next PC is PC + 8
    btb_valid_r   = 1'b0;
    btb_upper_r   = 1'b0;
    btb_is_call_r = 1'b0;
    btb_is_ret_r  = 1'b0;
    btb_is_jmp_r  = 1'b0;
    btb_next_pc_r = {pc_f_i[31:3],3'b0} + 32'd8;
    btb_entry_r   = {NUM_BTB_ENTRIES_W{1'b0}};

    // First: try matching PC directly
    for (i0 = 0; i0 < NUM_BTB_ENTRIES; i0 = i0 + 1)
    begin
        if (btb_pc_q[i0] == pc_f_i)
        begin
            btb_valid_r   = 1'b1;
            btb_upper_r   = pc_f_i[2]; 
            btb_is_call_r = btb_is_call_q[i0];
            btb_is_ret_r  = btb_is_ret_q[i0];
            btb_is_jmp_r  = btb_is_jmp_q[i0];
            btb_next_pc_r = btb_target_q[i0];
            btb_entry_r   = i0; // Store match index
        end
    end

    // If not found, try match PC with LSB flipped (for compressed instr alignment)
    if (~btb_valid_r && ~pc_f_i[2])
    begin
        for (i0 = 0; i0 < NUM_BTB_ENTRIES; i0 = i0 + 1)
        begin
            if (btb_pc_q[i0] == (pc_f_i | 32'd4))
            begin
                btb_valid_r   = 1'b1;
                btb_upper_r   = 1'b1;
                btb_is_call_r = btb_is_call_q[i0];
                btb_is_ret_r  = btb_is_ret_q[i0];
                btb_is_jmp_r  = btb_is_jmp_q[i0];
                btb_next_pc_r = btb_target_q[i0];
                btb_entry_r   = i0;
            end
        end
    end
end

// BTB write logic — detect hit/miss on actual branch resolution
reg [NUM_BTB_ENTRIES_W-1:0]  btb_wr_entry_r;
wire [NUM_BTB_ENTRIES_W-1:0] btb_wr_alloc_w;

reg btb_hit_r;
reg btb_miss_r;
integer i1;

always @ *
begin
    btb_wr_entry_r = {NUM_BTB_ENTRIES_W{1'b0}};
    btb_hit_r      = 1'b0;
    btb_miss_r     = 1'b0;

    if (branch_request_i) // Update on real branch
    begin
        for (i1 = 0; i1 < NUM_BTB_ENTRIES; i1 = i1 + 1)
        begin
            if (btb_pc_q[i1] == branch_source_i)
            begin
                btb_hit_r      = 1'b1;
                btb_wr_entry_r = i1;
            end
        end
        btb_miss_r = ~btb_hit_r; // True if no entry matched
    end
end

// BTB update logic — update existing entry or allocate new one
integer i2;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    // On reset, clear all BTB entries
    for (i2 = 0; i2 < NUM_BTB_ENTRIES; i2 = i2 + 1)
    begin
        btb_pc_q[i2]     <= 32'b0;
        btb_target_q[i2] <= 32'b0;
        btb_is_call_q[i2]<= 1'b0;
        btb_is_ret_q[i2] <= 1'b0;
        btb_is_jmp_q[i2] <= 1'b0;
    end
end
// Hit, Update existing entry with new branch info
else if (btb_hit_r)
begin
    btb_pc_q[btb_wr_entry_r]     <= branch_source_i;
    if (branch_is_taken_i)
        btb_target_q[btb_wr_entry_r] <= branch_pc_i;
    btb_is_call_q[btb_wr_entry_r]<= branch_is_call_i;
    btb_is_ret_q[btb_wr_entry_r] <= branch_is_ret_i;
    btb_is_jmp_q[btb_wr_entry_r] <= branch_is_jmp_i;
end
// Miss, Allocate new entry using LFSR
else if (btb_miss_r)
begin
    btb_pc_q[btb_wr_alloc_w]     <= branch_source_i;
    btb_target_q[btb_wr_alloc_w] <= branch_pc_i;
    btb_is_call_q[btb_wr_alloc_w]<= branch_is_call_i;
    btb_is_ret_q[btb_wr_alloc_w] <= branch_is_ret_i;
    btb_is_jmp_q[btb_wr_alloc_w] <= branch_is_jmp_i;
end

// BTB Replacement Policy using LFSR (random entry allocation)
NEXT_PC_LFSR
#(
    .DEPTH(NUM_BTB_ENTRIES),
    .ADDR_W(NUM_BTB_ENTRIES_W)
)
u_lru
(
     .clk_i(clk_i),
     .rst_i(rst_i),
     .hit_i(btb_valid_r),           // If BTB hit this cycle
     .hit_entry_i(btb_entry_r),     // Entry that was a hit
     .alloc_i(btb_miss_r),          // If new entry needs allocation
     .alloc_entry_o(btb_wr_alloc_w) // Random entry index via LFSR
);

// Final output assignments
generate
    if (SUPPORT_BRANCH_PREDICTION == 1)
    begin : WITH_BRANCH_PREDICTION
        assign btb_valid_w   = btb_valid_r;
        assign btb_is_call_w = btb_is_call_r;
        assign btb_is_ret_w  = btb_is_ret_r;
        assign next_pc_f_o   = ras_ret_pred_w ? ras_pc_pred_w : 
                               (bht_predict_taken_w | btb_is_jmp_r) ? btb_next_pc_r :
                               {pc_f_i[31:3],3'b000} + 32'd8;
        assign next_taken_f_o = (btb_valid_w & (ras_ret_pred_w | bht_predict_taken_w | btb_is_jmp_r)) ? 
                               (pc_f_i[2] ? {btb_upper_r, 1'b0} : {btb_upper_r, ~btb_upper_r}) : 
                               2'b00;
        assign pred_taken_w   = (btb_valid_w & (ras_ret_pred_w | bht_predict_taken_w | btb_is_jmp_r)) & pc_accept_i;
        assign pred_ntaken_w  = btb_valid_w & ~pred_taken_w & pc_accept_i;
    end
    else
    begin : NO_BRANCH_PREDICTION
        assign btb_valid_w   = 1'b0;
        assign btb_is_call_w = 1'b0;
        assign btb_is_ret_w  = 1'b0;
        assign next_pc_f_o   = {pc_f_i[31:3],3'b000} + 32'd8;
        assign next_taken_f_o = 2'b00;
        assign pred_taken_w   = 1'b0;
        assign pred_ntaken_w  = 1'b0;
    end
endgenerate

endmodule