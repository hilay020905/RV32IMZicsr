//HILAY_PATEL

`define PRIV_MACHINE 2'b11
module FETCH

#(
     parameter SUPPORT_MMU = 1
)

(
     input           clk_i
    ,input           rst_i
    ,input           fetch_accept_i
    ,input           icache_accept_i
    ,input           icache_valid_i
    ,input           icache_error_i
    ,input  [ 63:0]  icache_inst_i
    ,input           icache_page_fault_i
    ,input           fetch_invalidate_i
    ,input           branch_request_i
    ,input  [ 31:0]  branch_pc_i
    ,input  [  1:0]  branch_priv_i
    ,input  [ 31:0]  next_pc_f_i
    ,input  [  1:0]  next_taken_f_i

    ,output          fetch_valid_o
    ,output [ 63:0]  fetch_instr_o
    ,output [  1:0]  fetch_pred_branch_o
    ,output          fetch_fault_fetch_o
    ,output          fetch_fault_page_o
    ,output [ 31:0]  fetch_pc_o
    ,output          icache_rd_o
    ,output          icache_flush_o
    ,output          icache_invalidate_o
    ,output [ 31:0]  icache_pc_o
    ,output [  1:0]  icache_priv_o
    ,output [ 31:0]  pc_f_o
    ,output          pc_accept_o
);

reg         active_q;
reg         branch_q;
reg [31:0]  branch_pc_q;
reg [1:0]   branch_priv_q;

wire        icache_busy_w;
wire        stall_w = !fetch_accept_i || icache_busy_w || !icache_accept_i;
wire        branch_w;
wire [31:0] branch_pc_w;
wire [1:0]  branch_priv_w;

generate
if (SUPPORT_MMU) // Case 1: MMU is supported
begin
    // Assign internal branch signals to output wires
    assign branch_w      = branch_q;
    assign branch_pc_w   = branch_pc_q;
    assign branch_priv_w = branch_priv_q;
    
    // Sequential logic: update branch signals on clock or reset
    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        // On reset, clear branch request and PC, set privilege level to machine mode
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
        branch_priv_q  <= `PRIV_MACHINE;
    end
    else if (branch_request_i)
    begin
        // On branch request: store the branch PC and privilege level
        branch_q       <= 1'b1;
        branch_pc_q    <= branch_pc_i;
        branch_priv_q  <= branch_priv_i;
    end
    else if (icache_rd_o && icache_accept_i)
    begin
        // Once instruction cache accepts the read, clear the branch
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
end
else // Case 2: MMU is NOT supported
begin
    // Output branch is active if either current branch is active or a new request came
    assign branch_w      = branch_q || branch_request_i;

    // Select PC: retain old one if already branching, otherwise take the new request
    assign branch_pc_w   = (branch_q & !branch_request_i) ? branch_pc_q : branch_pc_i;

    // Privilege level is not used, hardcoded to MACHINE mode
    assign branch_priv_w = `PRIV_MACHINE;

    // Sequential logic
    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
    begin
        // Clear everything on reset
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
    else if (branch_request_i && (icache_busy_w || !active_q))
    begin
        // If branch request arrives but I-cache is busy or core is inactive: hold the request
        branch_q       <= branch_w;
        branch_pc_q    <= branch_pc_w;
    end
    else if (~icache_busy_w)
    begin
        // When I-cache becomes free, clear the branch request
        branch_q       <= 1'b0;
        branch_pc_q    <= 32'b0;
    end
end
endgenerate

//Active flags
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    active_q    <= 1'b0;
else if (SUPPORT_MMU && branch_w && ~stall_w)
    active_q    <= 1'b1;
else if (!SUPPORT_MMU && branch_w)
    active_q    <= 1'b1;

//Stall flags
reg stall_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    stall_q    <= 1'b0;
else
    stall_q    <= stall_w;

//request tracking
reg icache_fetch_q;
reg icache_invalidate_q;

// ICACHE fetch tracking
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_fetch_q <= 1'b0;
else if (icache_rd_o && icache_accept_i)
    icache_fetch_q <= 1'b1;
else if (icache_valid_i)
    icache_fetch_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    icache_invalidate_q <= 1'b0;
else if (icache_invalidate_o && !icache_accept_i)
    icache_invalidate_q <= 1'b1;
else
    icache_invalidate_q <= 1'b0;

//pc
reg [31:0]  pc_f_q;
reg [31:0]  pc_d_q;
reg [1:0]   pred_d_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_f_q  <= 32'b0;
// Branch request
else if (SUPPORT_MMU && branch_w && ~stall_w)
    pc_f_q  <= branch_pc_w;
else if (!SUPPORT_MMU && (stall_w || !active_q || stall_q) && branch_w)
    pc_f_q  <= branch_pc_w;
// NPC
else if (!stall_w)
    pc_f_q  <= next_pc_f_i;

wire [31:0] icache_pc_w;
wire [1:0]  icache_priv_w;
wire        fetch_resp_drop_w;

generate
if (SUPPORT_MMU)
begin
    reg [1:0] priv_f_q;
    reg       branch_d_q;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        priv_f_q  <= `PRIV_MACHINE;
    // Branch request
    else if (branch_w && ~stall_w)
        priv_f_q  <= branch_priv_w;

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        branch_d_q  <= 1'b0;
    // Branch request
    else if (branch_w && ~stall_w)
        branch_d_q  <= 1'b1;
    // NPC
    else if (!stall_w)
        branch_d_q  <= 1'b0;

    assign icache_pc_w       = pc_f_q;
    assign icache_priv_w     = priv_f_q;
    assign fetch_resp_drop_w = branch_w | branch_d_q;
end
else
begin
    assign icache_pc_w       = (branch_w & ~stall_q) ? branch_pc_w : pc_f_q;
    assign icache_priv_w     = `PRIV_MACHINE; // Don't care
    assign fetch_resp_drop_w = branch_w;
end
endgenerate

// Last fetch address
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pc_d_q <= 32'b0;
else if (icache_rd_o && icache_accept_i)
    pc_d_q <= icache_pc_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    pred_d_q <= 2'b0;
else if (icache_rd_o && icache_accept_i)
    pred_d_q <= next_taken_f_i;
else if (icache_valid_i)
    pred_d_q <= 2'b0;


// Outputs
assign icache_rd_o         = active_q & fetch_accept_i & !icache_busy_w;
assign icache_pc_o         = {icache_pc_w[31:3],3'b0};
assign icache_priv_o       = icache_priv_w;
assign icache_flush_o      = fetch_invalidate_i | icache_invalidate_q;
assign icache_invalidate_o = 1'b0;

assign icache_busy_w       =  icache_fetch_q && !icache_valid_i;

// Response Buffer
reg [99:0]  skid_buffer_q;
reg         skid_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    skid_buffer_q  <= 100'b0;
    skid_valid_q   <= 1'b0;
end 
// Instruction output back-pressured - hold in skid buffer
else if (fetch_valid_o && !fetch_accept_i)
begin
    skid_valid_q  <= 1'b1;
    skid_buffer_q <= {fetch_fault_page_o, fetch_fault_fetch_o, fetch_pred_branch_o, fetch_pc_o, fetch_instr_o};
end
else
begin
    skid_valid_q  <= 1'b0;
    skid_buffer_q <= 100'b0;
end

assign fetch_valid_o       = (icache_valid_i || skid_valid_q) & !fetch_resp_drop_w;
assign fetch_pc_o          = skid_valid_q ? skid_buffer_q[95:64] : {pc_d_q[31:3],3'b0};
assign fetch_instr_o       = skid_valid_q ? skid_buffer_q[63:0]  : icache_inst_i;
assign fetch_pred_branch_o = skid_valid_q ? skid_buffer_q[97:96] : pred_d_q;

// Faults
assign fetch_fault_fetch_o = skid_valid_q ? skid_buffer_q[98] : icache_error_i;
assign fetch_fault_page_o  = skid_valid_q ? skid_buffer_q[99] : icache_page_fault_i;

assign pc_f_o              = icache_pc_w;
assign pc_accept_o         = ~stall_w;


endmodule