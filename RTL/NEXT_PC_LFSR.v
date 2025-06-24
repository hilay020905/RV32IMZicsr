//HILAY_PATEL
module NEXT_PC_LFSR

#(
     parameter DEPTH            = 32
    ,parameter ADDR_W           = 5
    ,parameter INITIAL_VALUE    = 16'h0001
    ,parameter TAP_VALUE        = 16'hB400
)

(
     input                clk_i
    ,input                rst_i
    ,input                hit_i
    ,input  [ADDR_W-1:0]  hit_entry_i
    ,input                alloc_i

    ,output [ADDR_W-1:0]  alloc_entry_o
);

reg [15:0] lfsr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    lfsr_q <= INITIAL_VALUE;
else if (alloc_i)
begin
    if (lfsr_q[0])
        lfsr_q <= {1'b0, lfsr_q[15:1]} ^ TAP_VALUE;
    else
        lfsr_q <= {1'b0, lfsr_q[15:1]};
end

assign alloc_entry_o = lfsr_q[ADDR_W-1:0];

endmodule
