`timescale 1ns / 1ns

module stochastic_round (
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

reg [WID_SHIFT*2-1:0] lfsr_out;

wire [WID_DATA_OUT-1:0] tmp_0;
wire [WID_DATA_OUT-1:0] tmp_1;

wire round_bit0, round_bit1;
wire [WID_DATA_OUT-1:0] base_0;
wire [WID_DATA_OUT-1:0] base_1;

wire [WID_SHIFT-1:0] rand_0;
wire [WID_SHIFT-1:0] rand_1;

assign rand_0 = lfsr_out[0+:WID_SHIFT];
assign rand_1 = lfsr_out[WID_SHIFT+:WID_SHIFT];
assign round_bit0 = (data_in[0+:WID_SHIFT]>rand_0)?1:0;
assign round_bit1 = (data_in[WID_DATA_IN+:WID_SHIFT]>rand_1)?1:0;
assign base_0 = data_in[WID_SHIFT+:WID_DATA_OUT];
assign base_1 = data_in[(WID_DATA_IN+WID_SHIFT)+:(WID_DATA_IN+WID_DATA_OUT)];
assign tmp_0 = base_0+ round_bit0;
assign tmp_1 = base_1+ round_bit1;

// LFSR
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        lfsr_out <= 0;
    end
    else begin
        lfsr_out[0] <=lfsr_out[WID_SHIFT*2-1];
        for (int i = 1; i < WID_SHIFT*2; i++) begin
            if(i==20||i==21||i==47) begin
                lfsr_out[i] <=lfsr_out[i-1]~^lfsr_out[WID_SHIFT*2-1];
            end
            else begin
                lfsr_out[i] <=lfsr_out[i-1];
            end
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_out <= 0;
    end
    else begin
        data_out <= {tmp_1,tmp_0};
    end
end

endmodule