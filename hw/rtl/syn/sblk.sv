// SuperBlock
`timescale 1ns / 1ns

module sblk(/*AUTOARG*/
            // Outputs
            act_data_in_req, status_sblk, psum_rd_data,
            // Inputs
            clk_h, clk_l, rst_n, act_data_in, act_data_in_vld, inst_data,
            inst_en
            );

   // number of supertile inside the superblock
   parameter N_COLUMN = 4;
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
   input wire [2*WID_ACT-1:0] act_data_in;
   input wire                 act_data_in_vld;
   output wire                act_data_in_req;

   // instruction input signal
   input wire [WID_INST-1:0]  inst_data;
   input wire                 inst_en;

   output wire                status_sblk;
   
   wire [N_TILE-1:0]          act_wr_en;
   wire [WID_ACTADDR-2:0]     act_wr_addr_hbit;
   // activation buffer rd signal
   wire [WID_ACTADDR-2:0]     act_rd_addr_hbit;
   // weight buffer rd signal
   wire [WID_WADDR-1:0]       w_rd_addr;
   // psum buffer wr signal
   wire [WID_PSUMADDR-1:0]    psum_wr_addr;
   wire                       psum_wr_en;
   // psum buffer rd signal
   wire [WID_PSUMADDR-1:0]    psum_rd_addr;
   // FIXME
   output wire [2*WID_PSUM*N_COLUMN-1:0] psum_rd_data;

   // instance 
   sblk_ctrl #(
               .N_TILE(N_TILE),
               .WID_N_TILE(WID_N_TILE),
               .WID_WADDR(WID_WADDR),
               .WID_ACTADDR(WID_ACTADDR),
               .WID_PSUMADDR(WID_PSUMADDR),
               .WID_INST_TN(WID_INST_TN),
               .WID_INST_TM(WID_INST_TM),
               .WID_INST_TP(WID_INST_TP),
               .WID_INST_LP(WID_INST_LP),
               .WID_INST_LN(WID_INST_LN)
               )
   u_sblk_ctrl(
               .clk_l(clk_l),
               .rst_n(rst_n),
               .inst_data(inst_data),
               .inst_en(inst_en),
               .act_in_vld(act_data_in_vld),
               .act_in_req(act_data_in_req),
               .w_rd_addr(w_rd_addr),
               .act_rd_addr_hbit(act_rd_addr_hbit),
               .act_wr_addr_hbit(act_wr_addr_hbit),
               .act_wr_en(act_wr_en),
               .psum_wr_addr(psum_wr_addr),
               .psum_wr_en(psum_wr_en),
               .psum_rd_addr(psum_rd_addr),
               .status_sblk(status_sblk)
               );


   genvar                                ii;
   generate
      for (ii=0; ii<N_COLUMN; ii=ii+1) begin: u_sblk_unit
         sblk_unit #(
                     .N_TILE(N_TILE),
                     .WID_N_TILE(WID_N_TILE),
                     .WID_W(WID_W),
                     .WID_WADDR(WID_WADDR),
                     .WID_ACT(WID_ACT),
                     .WID_ACTADDR(WID_ACTADDR),
                     .WID_PSUM(WID_PSUM),
                     .WID_PSUMADDR(WID_PSUMADDR),
                     .PSUM_SPLIT_START_POS(PSUM_SPLIT_START_POS)
                     )
         u_sblk_unit(
                     .clk_l(clk_l),
                     .clk_h(clk_h),
                     .rst_n(rst_n),
                     .act_data_in(act_data_in),
                     .act_wr_en(act_wr_en),
                     .act_wr_addr_hbit(act_wr_addr_hbit),
                     .act_rd_addr_hbit(act_rd_addr_hbit),
                     .w_rd_addr(w_rd_addr),
                     .psum_wr_addr(psum_wr_addr),
                     .psum_wr_en(psum_wr_en),
                     .psum_rd_addr(psum_rd_addr),
                     .psum_rd_data(psum_rd_data[2*WID_PSUM*ii+:(2*WID_PSUM)])
                     );
      end
   endgenerate


   
endmodule // sblk

