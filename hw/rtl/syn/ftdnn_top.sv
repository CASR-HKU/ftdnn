`timescale 1ns / 1ns
`include "ftdnn_conf.vh"

module ftdnn_top (
    // Outputs
    actbuf_wr_req, pbuf_rd_data, sblk_status,
    // Inputs
    clk_h, clk_l, rst_n, actbuf_wr_data, actbuf_wr_vld, sblk_param, sblk_param_en
);

input wire                                     clk_h;
input wire                                     clk_l;
input wire                                     rst_n;

output wire    [`HW_D3-1:0]                    sblk_status;
input wire     [`HW_XLT_LEN-1:0]               sblk_param;
input wire                                     sblk_param_en;

input wire     [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data;
output wire                                    actbuf_wr_req;
input wire                                     actbuf_wr_vld;

output wire    [`PBUF_DATA_LEN*`HW_D2-1:0]     pbuf_rd_data[`HW_D3-1:0];

wire           [`HW_D3-1:0]                    actbuf_wr_req_d3;
assign actbuf_wr_req = actbuf_wr_req_d3=={{`HW_D3}{1'b1}}?1:0;

generate
    for (genvar hw_d3 = 0; hw_d3 < `HW_D3; hw_d3=hw_d3+1) begin: sblk_row
        sblk_row #(
            .POS_D3(hw_d3)
            )
        sblk_row_inst(
            .clk_h(clk_h),
            .clk_l(clk_l),
            .rst_n(rst_n),
            .sblk_status(sblk_status[hw_d3]),
            .sblk_param(sblk_param),
            .sblk_param_en(sblk_param_en),
            .actbuf_wr_data(actbuf_wr_data),
            .actbuf_wr_req(actbuf_wr_req_d3[hw_d3]),
            .actbuf_wr_vld(actbuf_wr_vld),
            .pbuf_rd_data(pbuf_rd_data[hw_d3])
        );
    end
endgenerate

endmodule