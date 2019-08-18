// unit test for sblk control

`timescale 1 ns / 1 ns

module tb_sblk_ctrl;

   parameter CLK_PERIOD = 10;

   parameter N_TILE = 4;
   parameter WID_N_TILE = $clog2(N_TILE);
   parameter WID_W = 16;
   parameter WID_WADDR = 10;
   parameter WID_ACT = 16;
   parameter WID_ACTADDR = 6;
   parameter WID_PSUM = 36;
   parameter WID_PSUMADDR = 9;
   parameter PSUM_SPLIT_START_POS = 12;

   parameter WID_INST_TN=4;
   parameter WID_INST_TM=9;
   parameter WID_INST_TP=5;
   // FIXME: arbitrary width
   parameter WID_INST_LN=5;
   parameter WID_INST_LP=5;

   parameter WID_INST = WID_INST_TN + WID_INST_TM + WID_INST_TP + WID_INST_LN + WID_INST_LP;
   parameter WB_DELAY_CYCLE = N_TILE + 8;

   // variables
   int ii, jj;

   reg clk_l;
   reg rst_n;

   // instruction input signal
   reg [WID_INST-1:0] inst_data;
   reg                inst_en;
   // instruction partition
   reg [WID_INST_TN-1:0] n_tn;
   reg [WID_INST_TM-1:0] n_tm;
   reg [WID_INST_TP-1:0] n_tp;
   reg [WID_INST_LN-1:0] n_ln;
   reg [WID_INST_LP-1:0] n_lp;

   reg                   act_data_in_vld;
   reg [2*WID_ACT-1:0]   act_data_in;

   // output wires of the module
   wire                  act_data_in_req;
   wire [WID_WADDR-1:0]  w_rd_addr;
   wire [WID_ACTADDR-2:0] act_rd_addr_hbit;
   wire [WID_ACTADDR-2:0] act_wr_addr_hbit;
   wire [N_TILE-1:0]      act_wr_en;

   wire [WID_PSUMADDR-1:0] psum_wr_addr;
   wire [WID_PSUMADDR-1:0] psum_wr_en;
   wire [WID_PSUMADDR-1:0] psum_rd_addr;


   initial begin
      clk_l = 1'b1;
      forever #(CLK_PERIOD/2) clk_l = ~clk_l;
   end

   initial begin
      rst_n = 1'b1;
      repeat(2) @(negedge clk_l);
      rst_n = 1'b0;
      repeat(2) @(negedge clk_l);
      rst_n = 1'b1;
   end

   // set instruction
   initial begin
      n_tn = 2; n_tm = 4; n_tp = 1; n_ln = 3; n_lp = 2;
      inst_data = {n_lp, n_ln, n_tp, n_tm, n_tn};
      inst_en = 0;
      repeat(10) @(negedge clk_l);
      inst_en = 1;
      repeat(1) @(negedge clk_l);
      inst_en = 0;
   end

   // act data request response
   initial begin
      act_data_in_vld = 0;
      forever begin
         if (act_data_in_req) begin
            for (ii=0; ii<2*n_tn*n_tp*N_TILE; ii=ii+2) begin
               @(negedge clk_l);
               act_data_in_vld = 1;
               //FIXME: couple two act data to a wider one
               act_data_in[0+:WID_ACT] = ii;
               act_data_in[WID_ACT+:WID_ACT] = ii+1;
            end
         end else begin
            @(negedge clk_l);
            act_data_in_vld = 0;
         end
      end
   end

   initial begin
      repeat(20000) @(posedge clk_l);
      $finish;
   end

   sblk_ctrl #(
               .N_TILE(N_TILE),
               .WID_N_TILE(WID_N_TILE)
               )
   sblk_ctrl_inst(
                  .clk_l(clk_l),
                  .rst_n(rst_n),
                  .inst_data(inst_data),
                  .inst_en(inst_en),
                  .act_in_vld(act_data_in_vld),
                  .act_in(act_data_in),
                  .act_in_req(act_data_in_req),
                  .w_rd_addr(w_rd_addr),
                  .act_rd_addr_hbit(act_rd_addr_hbit),
                  .act_wr_addr_hbit(act_wr_addr_hbit),
                  .act_wr_en(act_wr_en),
                  .psum_wr_addr(psum_wr_addr),
                  .psum_wr_en(psum_wr_en),
                  .psum_rd_addr(psum_rd_addr)
                  );

endmodule
