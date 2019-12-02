`timescale 1ns / 1ns

module sblk_ctrl(/*AUTOARG*/
   // Outputs
   act_in_req, w_rd_addr, act_rd_addr_hbit, act_wr_addr_hbit,
   act_wr_en, psum_wr_addr, psum_wr_en, psum_rd_addr, status_sblk,
   // Inputs
   clk_l, rst_n, inst_data, inst_en, act_in_vld
   );

   parameter N_TILE = 4;
   parameter WID_N_TILE = $clog2(N_TILE);
   parameter WID_WADDR = 10;
   parameter WID_ACTADDR = 6;
   parameter WID_PSUMADDR = 9;

   parameter WID_INST_TN=3;
   parameter WID_INST_TM=3;
   parameter WID_INST_TP=2;
   // FIXME: arbitrary width
   parameter WID_INST_LN=3;
   parameter WID_INST_LP=3;

   parameter WID_INST = WID_INST_TN + WID_INST_TM + WID_INST_TP + WID_INST_LN + WID_INST_LP;
   //FIXME: delay length between psum read and psum write back, calculated with N_TILE
   parameter WB_DELAY_CYCLE = 1 + 5 + N_TILE/2;

   int ii;

   input wire clk_l;
   input wire rst_n;

   // instruction input signal
   input wire [WID_INST-1:0] inst_data;
   input wire                inst_en;

   // request signal, one-cycle trigger for the batch act of al N_TILE stiles in one trip count
   output reg                act_in_req;
   input wire                act_in_vld;
   // input wire [2*WID_ACT-1:0] act_in;


   output reg [WID_WADDR-1:0] w_rd_addr;

   output reg [WID_ACTADDR-2:0] act_rd_addr_hbit;
   output reg [WID_ACTADDR-2:0] act_wr_addr_hbit;
   output reg [N_TILE-1:0]      act_wr_en;

   output wire [WID_PSUMADDR-1:0] psum_wr_addr;
   output wire psum_wr_en;
   output reg [WID_PSUMADDR-1:0]  psum_rd_addr;
   output reg status_sblk;


   reg [WID_INST-1:0]             inst_reg;
   reg                            inst_en_d;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_inst_reg
      if(~rst_n) begin
         inst_reg <= 0;
         inst_en_d <= 0;
      end else begin
         inst_en_d <= inst_en;
         if (inst_en) begin
            inst_reg <= inst_data;
         end
      end
   end

   // inst decoder: inst includes the `temporal partition` information
   wire [WID_INST_TN-1:0] n_tn;
   wire [WID_INST_TM-1:0] n_tm;
   wire [WID_INST_TP-1:0] n_tp;
   wire [WID_INST_LN-1:0] n_ln;
   wire [WID_INST_LP-1:0] n_lp;

   assign n_tn = inst_reg[0+:WID_INST_TN];
   assign n_tm = inst_reg[WID_INST_TN+:WID_INST_TM];
   assign n_tp = inst_reg[WID_INST_TN+WID_INST_TM+:WID_INST_TP];
   assign n_ln = inst_reg[WID_INST_TN+WID_INST_TM+WID_INST_TP+:WID_INST_LN];
   assign n_lp = inst_reg[WID_INST_TN+WID_INST_TM+WID_INST_TP+WID_INST_LN+:WID_INST_LP];

   reg [WID_INST_TN-1:0]  cnt_tn;
   reg [WID_INST_TM-1:0]  cnt_tm;
   reg [WID_INST_TP-1:0]  cnt_tp;
   reg [WID_INST_LN-1:0]  cnt_ln;
   reg [WID_INST_LP-1:0]  cnt_lp;

   // toggle for input act & compute. Status: 0: sblk free / one inst-trip unfinished; 1: one inst-trip finished
   reg toggle_act_in;
   reg toggle_act_in_d;
   reg toggle_compute;
   reg toggle_compute_d;

   wire trip_start;
   wire trip_finish;
   wire inst_finish;

   wire comp_flag; 
   reg [WB_DELAY_CYCLE:0] comp_flag_d;
   reg [WB_DELAY_CYCLE:0] inst_finish_d;   
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_comp_flag_d
      if(~rst_n) begin
         comp_flag_d <= 0;
         inst_finish_d <= 0;
      end else begin
         comp_flag_d[0] <= comp_flag;
         inst_finish_d[0] <= inst_finish;
         for (ii=1; ii<WB_DELAY_CYCLE+1; ii=ii+1) begin
            comp_flag_d[ii] <= comp_flag_d[ii-1];
            inst_finish_d[ii] <= inst_finish_d[ii-1];
         end
      end
   end

   // PROCESS: computation
   // counters for computation
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_tp
      if(~rst_n) begin
         cnt_tp <= 0;
      end else begin
         cnt_tp <= comp_flag? ((cnt_tp==n_tp-N_TILE)? 0 : cnt_tp + N_TILE) : 0;
         // cnt_tp <= 0;
      end
   end   

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_tm
      if(~rst_n) begin
         cnt_tm <= 0;
      end else begin
         cnt_tm <= comp_flag? ((cnt_tp==n_tp-N_TILE)? ((cnt_tm==n_tm-1)? 0 : cnt_tm + 1) : cnt_tm) : 0;
         // cnt_tm <= comp_flag? ((cnt_tm==n_tm-1)? 0 : cnt_tm + 1) : 0;
      end
   end

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_tn
      if(~rst_n) begin
         cnt_tn <= 0;
      end else begin
         cnt_tn <= comp_flag? (((cnt_tp==n_tp-N_TILE) & (cnt_tm==n_tm-1))? ((cnt_tn==n_tn-1)? 0 : cnt_tn + 1) : cnt_tn) : 0;
         // cnt_tn <= comp_flag? ((cnt_tm==n_tm-1)? ((cnt_tn==n_tn-1)? 0 : cnt_tn + 1) : cnt_tn) : 0;
      end
   end

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_ln
      if(~rst_n) begin
         cnt_ln <= 0;
      end else begin
         cnt_ln <= inst_en_d? 0 : (trip_finish? ((cnt_ln==n_ln-1)? 0 : cnt_ln + 1) : cnt_ln);
      end
   end

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_lp
      if(~rst_n) begin
         cnt_lp <= 0;
      end else begin
         cnt_lp <= inst_en_d? 0 : (trip_finish? ((cnt_ln==n_ln-1)? ((cnt_lp==n_lp-1)? 0 : cnt_lp+1) : cnt_lp) : cnt_lp);
      end
   end

   assign trip_finish = (cnt_tp==n_tp-N_TILE & cnt_tm==n_tm-1 & cnt_tn==n_tn-1);
   assign trip_start = (cnt_tp==0 & cnt_tm==0 & cnt_tn==0);
   assign inst_finish = (cnt_lp==n_lp-1 & cnt_ln==n_ln-1 & trip_finish);

   // read address for computation generated with the counter values
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_act_rd_addr_hbit
      if(~rst_n) begin
         act_rd_addr_hbit <= 0;
      end else begin
         act_rd_addr_hbit <= (toggle_compute << (WID_ACTADDR-2)) + cnt_tn * n_tp + cnt_tp;
      end
   end

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_w_rd_addr
      if(~rst_n) begin
         w_rd_addr <= 0;
      end else begin
         w_rd_addr <= cnt_ln * n_tm * n_tp + cnt_tm * n_tp + cnt_tp;
      end
   end

   // psum_wr_addr is generated in concurrent with psum_rd_addr, with the same value. Delay for writing after DSP-chain propogation.
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_psum_rd_addr
      if(~rst_n) begin
         psum_rd_addr <= 0;
      end else begin
         psum_rd_addr <= cnt_lp * n_tn * n_tm + cnt_tn * n_tm + cnt_tm;
      end
   end


   // delay psum_wr_addr signal
   int jj;
   reg [WID_PSUMADDR-1:0] psum_wr_addr_d[WB_DELAY_CYCLE-2:0];
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_psum_wr_addr_d
      if(~rst_n) begin
         for (jj=0; jj<WB_DELAY_CYCLE; jj=jj+1) begin
            psum_wr_addr_d[jj] <= 0;
         end
      end else begin
         psum_wr_addr_d[0] <= psum_rd_addr;
         for (jj=1; jj<WB_DELAY_CYCLE; jj=jj+1) begin
            psum_wr_addr_d[jj] <= psum_wr_addr_d[jj-1];
         end
      end
   end

   // psum wr signal: from the dealy unit.
   assign psum_wr_addr = psum_wr_addr_d[WB_DELAY_CYCLE-2];
   assign psum_wr_en = comp_flag_d[WB_DELAY_CYCLE-1];

   // toggle of computation to indicate which half of act_buf should be process
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_toggle_compute
      if(~rst_n) begin
         toggle_compute <= 0;
         toggle_compute_d <= 0;         
      end else begin
         toggle_compute <= inst_en_d ? 0 : (trip_finish? ~toggle_compute : toggle_compute);
         toggle_compute_d <= toggle_compute;
      end
   end

   // PROCESS: act load
   // the act buffer acts in a half-half double-buffering manner
   reg [WID_N_TILE+WID_ACTADDR-2:0] n_act_in_trip;
   reg [WID_N_TILE+WID_ACTADDR-2:0] cnt_act_in_trip;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_n_act_in_trip
      if(~rst_n) begin
         n_act_in_trip <= 0;
      end else begin
         n_act_in_trip <= inst_en_d? 0 : n_tp * n_tn * N_TILE;
      end
   end

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_act_in_trip
      if(~rst_n) begin
         cnt_act_in_trip <= 0;
      end else begin
         cnt_act_in_trip <= (cnt_act_in_trip==n_act_in_trip-1)? 0 : (act_in_vld? cnt_act_in_trip + 1 : cnt_act_in_trip);
      end
   end

   // toggle of act input to indicate which half of act_buf should be written
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_toggle_act_in
      if(~rst_n) begin
         toggle_act_in <= 0;
         toggle_act_in_d <= 0;
      end else begin
         toggle_act_in <= inst_en_d? 0 : ((cnt_act_in_trip==n_act_in_trip-1)? ~toggle_act_in : toggle_act_in);
         toggle_act_in_d <= toggle_act_in;
      end
   end


   // synchronization between process computation & process act load
   // status of act_buf, 1 bit for each half. 0: to be written; 1: to be computed
   reg [1:0] status_act_buf;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_status_act_buf
      if(~rst_n) begin
         status_act_buf <= 0;
      end else begin
         status_act_buf[0] <= (toggle_compute & ~toggle_compute_d)? 0 : ((toggle_act_in & ~toggle_act_in_d)? 1 : status_act_buf[0]);
         status_act_buf[1] <= (~toggle_compute & toggle_compute_d)? 0 : ((~toggle_act_in & toggle_act_in_d)? 1 : status_act_buf[1]);
      end
   end

   // indicate the computation can be continued. criteria: any of status_act_buf is one.
   assign comp_flag = (~toggle_compute & status_act_buf[0]) | (toggle_compute & status_act_buf[1]);

   reg [WID_INST_LN+WID_INST_LP-1:0] cnt_act_in_batch;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_act_in_batch
      if(~rst_n) begin
         cnt_act_in_batch <= 0;
      end else begin
         cnt_act_in_batch <= inst_en? 0 : ((toggle_act_in ^ toggle_act_in_d)? ((cnt_act_in_batch==(n_ln*n_lp-1))? 0 : cnt_act_in_batch+1 ) : cnt_act_in_batch);
      end
   end

   // act data request send permission: only one request signal is needed for one input act data batch
   reg act_in_req_en;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_act_in_req_en
      if(~rst_n) begin
         act_in_req_en <= 0;
      end else begin
         act_in_req_en <= inst_en_d? 1 : (act_in_req? 0 : (((toggle_act_in ^ toggle_act_in_d) & (cnt_act_in_batch<(n_ln*n_lp-1)))? 1 : act_in_req_en));
      end
   end

   // act request
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_act_in_req
      if(~rst_n) begin
         act_in_req <= 0;
      end else begin
         // criteria: 1. any of status_act_buf is zero; 2. act_in_req_en is trigered; 3. ~act_in_req
         act_in_req <= (~status_act_buf[0] | ~status_act_buf[1]) &  act_in_req_en & ~act_in_req;
      end
   end

   // act buf wr address
   reg [WID_ACTADDR-3:0] cnt_act_in_tile_trip;
   reg [WID_N_TILE-1:0]  cnt_act_in_tile_idx; 

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt_act_in_tile_trip
      if(~rst_n) begin
         cnt_act_in_tile_trip <= 0;
         cnt_act_in_tile_idx <= 0;
      end else begin
         if (act_in_vld) begin
            cnt_act_in_tile_trip <= (cnt_act_in_tile_trip==(n_tn*n_tp-1))? 0 : cnt_act_in_tile_trip + 1;
            cnt_act_in_tile_idx <= (cnt_act_in_tile_trip==(n_tn*n_tp-1))? cnt_act_in_tile_idx + 1 : cnt_act_in_tile_idx;
         end
         act_wr_en <= act_in_vld? (1 << cnt_act_in_tile_idx) : 0;
      end
   end

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_act_wr_addr_hbit
      if(~rst_n) begin
         act_wr_addr_hbit <= 0;
      end else begin
         act_wr_addr_hbit <= {toggle_act_in, cnt_act_in_tile_trip};
      end
   end

   // status_sblk: 0: free, 1: busy
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_status_sblk
      if(~rst_n) begin
         status_sblk <= 0;
      end else begin
         // FIXME
         // status_sblk <= inst_en_d? 1 : ((inst_finish_d[WB_DELAY_CYCLE] & ~comp_flag_d[WB_DELAY_CYCLE-1])? 0 : status_sblk);
         status_sblk <= inst_en_d? 1 : (inst_finish_d[WB_DELAY_CYCLE-1]? 0 : status_sblk); // --rbshi: update for for `hw_refine`
      end
   end   

endmodule // sblk_ctrl
















































