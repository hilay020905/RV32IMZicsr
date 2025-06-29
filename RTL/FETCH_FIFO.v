//HILAY_PATEL
module FETCH_FIFO
#(
    parameter WIDTH   = 64,
    parameter DEPTH   = 2,
    parameter ADDR_W  = 1,
    parameter OPC_INFO_W = 10
)
(
     input                  clk_i
    ,input                  rst_i
    ,input                  flush_i
    ,input                  push_i
    ,input  [31:0]          pc_in_i
    ,input  [1:0]           pred_in_i
    ,input  [WIDTH-1:0]     data_in_i
    ,input [OPC_INFO_W-1:0] info0_in_i
    ,input [OPC_INFO_W-1:0] info1_in_i
    ,input                  pop0_i
    ,input                  pop1_i

    ,output                 accept_o
    ,output                 valid0_o
    ,output  [31:0]         pc0_out_o
    ,output [(WIDTH/2)-1:0] data0_out_o
    ,output[OPC_INFO_W-1:0] info0_out_o
    ,output                 valid1_o
    ,output  [31:0]         pc1_out_o
    ,output [(WIDTH/2)-1:0] data1_out_o
    ,output[OPC_INFO_W-1:0] info1_out_o

);

localparam COUNT_W = ADDR_W + 1;

reg [31:0]           pc_q[DEPTH-1:0];
reg                  valid0_q[DEPTH-1:0];
reg                  valid1_q[DEPTH-1:0];
reg [OPC_INFO_W-1:0] info0_q[DEPTH-1:0];
reg [OPC_INFO_W-1:0] info1_q[DEPTH-1:0];
reg [WIDTH-1:0]      ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]     rd_ptr_q;
reg [ADDR_W-1:0]     wr_ptr_q;
reg [COUNT_W-1:0]    count_q;

wire push_w         = (push_i & accept_o);
wire pop1_w         = (pop0_i & valid0_o);
wire pop2_w         = (pop1_i & valid1_o);
wire pop_complete_w = ((pop1_w && ~valid1_o) || (pop2_w && ~valid0_o) || (pop1_w && pop2_w));

integer i;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};

    for (i = 0; i < DEPTH; i = i + 1) 
    begin
        ram_q[i]         <= {(WIDTH) {1'b0}};
        pc_q[i]          <= 32'b0;
        info0_q[i]       <= {(OPC_INFO_W) {1'b0}};
        info1_q[i]       <= {(OPC_INFO_W) {1'b0}};
        valid0_q[i]      <= 1'b0;
        valid1_q[i]      <= 1'b0;
    end
end
else if (flush_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};

    for (i = 0; i < DEPTH; i = i + 1) 
    begin
        info0_q[i]       <= {(OPC_INFO_W) {1'b0}};
        info1_q[i]       <= {(OPC_INFO_W) {1'b0}};
        //valid0_q[i]      <= 1'b0; // TODO:...
        //valid1_q[i]      <= 1'b0; // TODO:...
    end
end
else
begin
    // Push
    if (push_w)
    begin
        ram_q[wr_ptr_q]     <= data_in_i;
        pc_q[wr_ptr_q]      <= pc_in_i;
        info0_q[wr_ptr_q]   <= info0_in_i;
        info1_q[wr_ptr_q]   <= info1_in_i;
        valid0_q[wr_ptr_q]  <= 1'b1;
        valid1_q[wr_ptr_q]  <= ~pred_in_i[0];
        wr_ptr_q            <= wr_ptr_q + 1;
    end

    if (pop1_w)
        valid0_q[rd_ptr_q] <= 1'b0;
    if (pop2_w)
        valid1_q[rd_ptr_q] <= 1'b0;

    // Both instructions completed
    if (pop_complete_w)
        rd_ptr_q  <= rd_ptr_q + 1;

    if (push_w & ~pop_complete_w)
        count_q <= count_q + 1;
    else if (~push_w & pop_complete_w)
        count_q <= count_q - 1;
end

/* verilator lint_off WIDTH */
assign valid0_o      = (count_q != 0) & valid0_q[rd_ptr_q];
assign valid1_o      = (count_q != 0) & valid1_q[rd_ptr_q];
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign pc0_out_o     = {pc_q[rd_ptr_q][31:3],3'b000};
assign pc1_out_o     = {pc_q[rd_ptr_q][31:3],3'b100};
assign data0_out_o   = ram_q[rd_ptr_q][(WIDTH/2)-1:0];
assign data1_out_o   = ram_q[rd_ptr_q][WIDTH-1:(WIDTH/2)];

assign info0_out_o   = info0_q[rd_ptr_q];
assign info1_out_o   = info1_q[rd_ptr_q];

endmodule