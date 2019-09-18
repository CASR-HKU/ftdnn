// SuperBlock
`timescale 1ns / 1ns

module sblk_row(/*AUTOARG*/
   // Outputs
   act_data_in_req, psum_rd_data, status_sblk,
   // Inputs
   clk_h, clk_l, rst_n, act_data_in, act_data_in_vld, inst_data,
   inst_en
   );

   // number of supertile inside the superblock
   parameter N_ROW = 3;
   parameter N_COLUMN = 12;
   parameter N_TILE = 40;
   parameter WID_N_TILE = $clog2(N_TILE);
   parameter WID_W = 16;
   parameter WID_WADDR = 10;
   parameter WID_ACT = 16;
   parameter WID_ACTADDR = 6;
   parameter WID_PSUM = 32;
   parameter WID_PSUMADDR = 9;
   // strip the tail 0-btis in the 48-bits psum from dsp   
   parameter PSUM_SPLIT_START_POS = 0;

   // parameter WID_INST_TN=4;
   // parameter WID_INST_TM=9;
   // parameter WID_INST_TP=5;
   // // FIXME: arbitrary width
   // parameter WID_INST_LN=5;
   // parameter WID_INST_LP=5;
   parameter WID_INST_TN=3;
   parameter WID_INST_TM=3;
   parameter WID_INST_TP=2;
   // FIXME: arbitrary width
   parameter WID_INST_LN=3;
   parameter WID_INST_LP=3;   
   parameter WID_INST = WID_INST_TN + WID_INST_TM + WID_INST_TP + WID_INST_LN + WID_INST_LP;

   
   input wire clk_h, clk_l;
   input wire rst_n;
   
   // signals from controller, NOTE: may change for MV / CONV, etc. 
   // activation buffer wr signal
   input wire [2*WID_ACT*N_ROW-1:0] act_data_in;
   input wire [N_ROW-1:0]           act_data_in_vld;
   output wire [N_ROW-1:0]          act_data_in_req;
   output wire [2*WID_PSUM*N_COLUMN*N_ROW-1:0] psum_rd_data;

   // instruction input signal
   input wire [WID_INST*N_ROW-1:0]             inst_data;
   input wire [N_ROW-1:0]                      inst_en;

   output wire [N_ROW-1:0]                     status_sblk;


   genvar                                      ii;
   generate   
      for (ii=0; ii<N_ROW; ii=ii+1) begin: u_sblk
         sblk #(
                .N_TILE(N_TILE),
                .N_COLUMN(N_COLUMN),
                .WID_N_TILE(WID_N_TILE),
                .WID_W(WID_W),
                .WID_WADDR(WID_WADDR),
                .WID_ACT(WID_ACT),
                .WID_ACTADDR(WID_ACTADDR),
                .WID_PSUM(WID_PSUM),
                .WID_PSUMADDR(WID_PSUMADDR),
                .PSUM_SPLIT_START_POS(PSUM_SPLIT_START_POS),
                .WID_INST_TN(WID_INST_TN),
                .WID_INST_TM(WID_INST_TM),
                .WID_INST_TP(WID_INST_TP),
                .WID_INST_LP(WID_INST_LP),
                .WID_INST_LN(WID_INST_LN)               
                )
         u_sblk(
                .clk_l(clk_l),
                .clk_h(clk_h),
                .rst_n(rst_n),
                .act_data_in(act_data_in[ii*2*WID_ACT+:(2*WID_ACT)]),
                .act_data_in_vld(act_data_in_vld[ii]),
                .act_data_in_req(act_data_in_req[ii]),
                .psum_rd_data(psum_rd_data[ii*2*WID_PSUM*N_COLUMN+:(2*WID_PSUM*N_COLUMN)]),
                .status_sblk(status_sblk[ii]),
                .inst_data(inst_data[ii*WID_INST+:WID_INST]),
                .inst_en(inst_en[ii])
                );
      end // u_sblk
   endgenerate

endmodule // sblk_row
