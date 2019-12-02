`timescale 1ns / 1ns

module pseudo_round (
    // input
    clk, rst_n, data_in,
    // output
    data_out
);
parameter WID_DATA_IN = 32;
parameter WID_DATA_OUT = 8;
parameter WID_SHIFT = WID_DATA_IN - WID_DATA_OUT;

input wire clk;
input wire rst_n;
input wire [WID_DATA_IN*2-1:0] data_in;

output reg [WID_DATA_OUT*2-1:0] data_out;

wire [WID_DATA_OUT-1:0] tmp_0;
wire [WID_DATA_OUT-1:0] tmp_1;

wire round_bit0, round_bit1;
wire [WID_DATA_OUT-1:0] base_0;
wire [WID_DATA_OUT-1:0] base_1;

assign round_bit0 = (data_in[WID_SHIFT/2+:WID_SHIFT/2]>data_in[0+:WID_SHIFT/2])?1:0;
assign round_bit1 = (data_in[(WID_DATA_IN+WID_SHIFT/2)+:WID_SHIFT/2]>data_in[WID_DATA_IN+:WID_SHIFT/2])?1:0;
assign base_0 = data_in[WID_SHIFT+:WID_DATA_OUT];
assign base_1 = data_in[(WID_DATA_IN+WID_SHIFT)+:(WID_DATA_IN+WID_DATA_OUT)];
assign tmp_0 = base_0+ round_bit0;
assign tmp_1 = base_1+ round_bit1;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_out <= 0;
    end
    else begin
        data_out <= {tmp_1,tmp_0};
    end
end

endmodule