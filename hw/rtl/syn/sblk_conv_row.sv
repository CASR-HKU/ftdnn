`timescale 1ns / 1ns
`include "ftdnn_conv_conf.vh"

module sblk_conv_row (
    // Outputs
    actbuf_wr_req, pbuf_rd_data, sblk_status,
    // Inputs
    clk_h, clk_l, rst_n, actbuf_wr_data, actbuf_wr_vld, temp_param, temp_param_en
);
parameter POS_D3=0;

input wire                                     clk_h;
input wire                                     clk_l;
input wire                                     rst_n;

output wire                                    sblk_status;
input wire     [`HW_TEMP_PARAM_LEN-1:0]        temp_param;
input wire                                     temp_param_en;

wire           [`WBUF_ADDR_LEN-1:0]            wbuf_rd_addr;

wire           [`HW_D1-1:0]                    actbuf_wr_en;
wire           [`ACTBUF_ADDRH_LEN-1:0]         actbuf_wr_addrh;
input wire     [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data;
output wire                                    actbuf_wr_req;
input wire                                     actbuf_wr_vld;

wire           [`ACTBUF_ADDR_LEN-1:0]          actbuf_rd_addr;
wire           [`ACTBUF_ADDR_LEN-1:0]          actbuf_rd_addr_increment;

wire                                           pbuf_wr_en;
wire           [`PBUF_ADDR_LEN-1:0]            pbuf_wr_addr;

wire           [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr;
output wire    [`PBUF_DATA_LEN*`HW_D2-1:0]     pbuf_rd_data;


sblk_conv_ctrl #(
    .POS_D3(POS_D3)
    )
sblk_conv_ctrl_inst(
    .clk_l(clk_l),
    .rst_n(rst_n),
    .sblk_status(sblk_status),
    .temp_param(temp_param),
    .temp_param_en(temp_param_en),
    .wbuf_rd_addr(wbuf_rd_addr),
    .actbuf_wr_en(actbuf_wr_en),
    .actbuf_wr_addrh(actbuf_wr_addrh),
    .actbuf_wr_req(actbuf_wr_req),
    .actbuf_wr_vld(actbuf_wr_vld),
    .actbuf_rd_addr(actbuf_rd_addr),
    .actbuf_rd_addr_increment(actbuf_rd_addr_increment),
    .pbuf_wr_en(pbuf_wr_en),
    .pbuf_wr_addr(pbuf_wr_addr),
    .pbuf_rd_addr(pbuf_rd_addr)
);


generate
    for (genvar hw_d2 = 0; hw_d2 < `HW_D2; hw_d2=hw_d2+1) begin: sblk_conv_col
        sblk_conv_unit #(
            .POS_D3(POS_D3),
            .POS_D2(hw_d2)
            )
        sblk_conv_unit_inst(
            .clk_h(clk_h),
            .clk_l(clk_l),
            .rst_n(rst_n),
            .wbuf_rd_addr(wbuf_rd_addr),
            .actbuf_wr_en(actbuf_wr_en),
            .actbuf_wr_addrh(actbuf_wr_addrh),
            .actbuf_wr_data(actbuf_wr_data),
            .actbuf_rd_addr(actbuf_rd_addr),
            .actbuf_rd_addr_increment(actbuf_rd_addr_increment),
            .pbuf_wr_en(pbuf_wr_en),
            .pbuf_wr_addr(pbuf_wr_addr),
            .pbuf_rd_addr(pbuf_rd_addr),
            .pbuf_rd_data(pbuf_rd_data[hw_d2*`PBUF_DATA_LEN+:`PBUF_DATA_LEN])
        );
    end
endgenerate

endmodule