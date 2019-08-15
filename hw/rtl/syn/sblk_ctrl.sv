module sblk_ctrl(/*AUTOARG*/
   // Outputs
   act_data_in_req, w_rd_addr, act_rd_addr_hbit, act_wr_addr_hbit,
   act_wr_en, psum_rd_addr, psum_wr_addr_delay, psum_wr_en,
   // Inputs
   inst_data, inst_en, act_data_in_vld
   );

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

   //FIXME: delay length between psum read and psum write back, calculated with N_TILE
   parameter WB_DELAY_CYCLE = N_TILE + 8; 

   // instruction input signal
   input wire [WID_INST-1:0] inst_data;
   input wire                inst_en;

   // request signal, one-cycle trigger for the batch act of al N_TILE stiles in one trip count
   output reg                act_data_in_req;
   input wire                act_data_in_vld;

   output reg [WID_WADDR-1:0] w_rd_addr;

   output reg [WID_ACTADDR-2:0] act_rd_addr_hbit;
   output wire [WID_ACTADDR-2:0] act_wr_addr_hbit;
   output wire [N_TILE-1:0]      act_wr_en;

   output wire [WID_PSUMADDR-1:0] psum_wr_addr_delay;
   output wire [WID_PSUMADDR-1:0] psum_wr_en;
   output reg [WID_PSUMADDR-1:0] psum_rd_addr;
   reg [WID_PSUMADDR-1:0]        psum_wr_addr;   


   reg [WID_INST-1:0]             inst_reg;
   always_ff @(posedge clk or negedge rst_n) begin : proc_inst_reg
      if(~rst_n) begin
         inst_reg <= 0;
         inst_en_d <= 0;
      end else begin
         if (inst_en) begin
           inst_reg <= inst_data;
         end
         inst_en_d <= inst_en;
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

   // status: 0: free, 1: busy
   // reg [2-1:0]            status_sblk;

   always_ff @(posedge clk or negedge rst_n) begin : proc_cnt_tp
      if(~rst_n) begin
         cnt_tp <= 0;
      end else begin
         cnt_tp <= inst_en? 0 : (comp_flag? ((cnt_tp==n_tp-1)? 0 : cnt_tp + 1) : cnt_tp);
      end
   end   

   always_ff @(posedge clk or negedge rst_n) begin : proc_cnt_tm
      if(~rst_n) begin
         cnt_tm <= 0;
      end else begin
         cnt_tm <= inst_en? 0 : (comp_flag? ((cnt_tp==n_tp-1)? ((cnt_tm==n_tm-1)? 0 : cnt_tm + 1) : cnt_tm) : cnt_tm);
      end
   end

   always_ff @(posedge clk or negedge rst_n) begin : proc_cnt_tn
      if(~rst_n) begin
         cnt_tn <= 0;
      end else begin
         cnt_tn <= inst_en? 0 : (comp_flag? (((cnt_tp==n_tp) & (cnt_tm==n_tm))? ((cnt_tn==n_tn)? 0 : cnt_tn + 1) : cnt_tn) : cnt_tn);
      end
   end

   always_ff @(posedge clk or negedge rst_n) begin : proc_cnt_ln
      if(~rst_n) begin
         cnt_ln <= 0;
      end else begin
         cnt_ln <= inst_en? 0 : (toggle_compute ^ ~toggle_compute_d)? ((cnt_ln==n_ln-1)? 0 : cnt_ln + 1) : cnt_ln;
      end
   end

   always_ff @(posedge clk or negedge rst_n) begin : proc_cnt_lp
      if(~rst_n) begin
         cnt_lp <= 0;
      end else begin
         cnt_lp <= inst_en? 0 : (toggle_compute ^ ~toggle_compute_d)? ((cnt_ln==n_ln-1)? ((cnt_lp==n_lp-1)? 0 : cnt_lp+1) : cnt_lp);
      end
   end

   always_ff @(posedge clk or negedge rst_n) begin : proc_act_rd_addr_hbit
      if(~rst_n) begin
         act_rd_addr_hbit <= 0;
      end else begin
         act_rd_addr_hbit <= (toggle_compute << (WID_ACTADDR-1)) + cnt_tp + cnt_tn * n_tp;
      end
   end

   always_ff @(posedge clk or negedge rst_n) begin : proc_w_rd_addr
      if(~rst_n) begin
         w_rd_addr <= 0;
      end else begin
         w_rd_addr <= cnt_tn + cnt_tm * n_tn + cnt_ln * n_tn * n_tm;
      end
   end

   // psum_wr_addr is generated in concurrent with psum_rd_addr, with the same value. Delay for writing after DSP-chain propogation.
   always_ff @(posedge clk or negedge rst_n) begin : proc_psum_rd_addr
      if(~rst_n) begin
         psum_rd_addr <= 0;
         psum_wr_addr <= 0;         
      end else begin
         psum_rd_addr <= cnt_tm + cnt_tp * n_tm + cnt_lp * n_tp * n_tm;
         psum_wr_addr <= cnt_tm + cnt_tp * n_tm + cnt_lp * n_tp * n_tm;
      end
   end


   // delay psum_wr_addr signal
   int jj;
   reg [WID_ACTADDR-2:0] psum_wr_addr_d[WB_DELAY_CYCLE-1:0];   
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_psum_wr_addr_d
      if(~rst_n) begin
         for (jj=0; jj<WB_DELAY_CYCLE; jj=jj+1) begin
            psum_wr_addr_d[jj] <= 0;
         end
      end else begin
         psum_wr_addr_d[0] <= psum_wr_addr;
         for (jj=1; jj<WB_DELAY_CYCLE; jj=jj+1) begin
            psum_wr_addr_d[jj] <= psum_wr_addr_d[jj-1];
         end
      end
   end

   // delay the status_sblk
   // reg [2-1:0]  status_sblk_d[WB_DELAY_CYCLE-1:0];   
   // always_ff @(posedge clk_l or negedge rst_n) begin : proc_status_sblk_d
   //    if(~rst_n) begin
   //       for (jj=0; jj<WB_DELAY_CYCLE; jj=jj+1) begin
   //          status_sblk_d[jj] <= 0;
   //       end
   //    end else begin
   //       status_sblk_d[0] <= status_sblk;
   //       for (jj=1; jj<WB_DELAY_CYCLE; jj=jj+1) begin
   //          status_sblk_d[jj] <= status_sblk_d[jj-1];
   //       end
   //    end
   // end

   // psum wr signal: from the dealy unit.
   assign psum_wr_addr_delay = psum_wr_addr_d[WB_DELAY_CYCLE-1];
   assign psum_wr_en = comp_flag_d[WB_DELAY_CYCLE-1][0];


   // the act buffer acts in a half-half double-buffering manner
   reg [WID_N_TILE+WID_ACTADDR-2:0] n_act_in_trip;
   reg [WID_N_TILE+WID_ACTADDR-2:0] cnt_act_in_trip;
   always_ff @(posedge clk or negedge rst_n) begin : proc_n_act_in_trip
      if(~rst_n) begin
         n_act_in_trip <= 0;
      end else begin
         n_act_in_trip <= inst_en_d? 0 : n_tp * n_tn * N_TILE;
      end
   end

   always_ff @(posedge clk or negedge rst_n) begin : proc_cnt_act_in_trip
      if(~rst_n) begin
         cnt_act_in_trip <= 0;
      end else begin
         cnt_act_in_trip <= (cnt_act_in_trip==n_act_in_trip)? 0 : (act_data_in_vld? cnt_act_in_trip + 1 : cnt_act_in_trip);
      end
   end

   // toggle for input act & compute. Status: 0: sblk free / one inst-trip unfinished; 1: one inst-trip finished
   reg toggle_act_in;
   reg toggle_act_in_d;
   reg toggle_compute;
   reg toggle_compute_d;

   // toggle of act input to indicate which half of act_buf should be written
   always_ff @(posedge clk or negedge rst_n) begin : proc_toggle_act_in
      if(~rst_n) begin
         toggle_act_in <= 0;
      end else begin
         toggle_act_in <= inst_en_d? 0 : ((cnt_act_in_trip==n_act_in_trip)? ~toggle_act_in : toggle_act_in);
         toggle_act_in_d <= toggle_act_in;
      end
   end

   // toggle of computation to indicate which half of act_buf should be process
   always_ff @(posedge clk or negedge rst_n) begin : proc_toggle_compute
      if(~rst_n) begin
         toggle_compute <= 0;
      end else begin
         toggle_compute <= inst_en_d? 0 : ((cnt_tp==n_tp & cnt_tm==n_tm & cnt_tn==n_tn)? ~toggle_compute : toggle_compute);
         toggle_compute_d <= toggle_compute;
      end
   end

   // status of act_buf, 1 bit for each half. 0: to be written; 1: to be computed
   reg [1:0] status_act_buf;
   always_ff @(posedge clk or negedge rst_n) begin : proc_status_act_buf
      if(~rst_n) begin
         status_act_buf <= 0;
      end else begin
         status_act_buf[0] <= (toggle_compute & ~toggle_compute_d)? 0 : ((toggle_act_in & ~toggle_act_in_d)? 1 : status_act_buf[0]);
         status_act_buf[1] <= (~toggle_compute & toggle_compute_d)? 0 : ((~toggle_act_in & toggle_act_in_d)? 1 : status_act_buf[1]);
      end
   end

   // act data request send permission: only one request signal is needed for one input act data batch
   reg act_data_in_req_en;
   always_ff @(posedge clk or negedge rst_n) begin : proc_act_data_in_req_en
      if(~rst_n) begin
         act_data_in_req_en <= 0;
      end else begin
         act_data_in_req_en <= act_data_in_req? 0 : ((toggle_act_in ^ toggle_act_in_d)? 1 : act_data_in_req);
      end
   end

   // act request
   reg act_data_in_req_d;
   always_ff @(posedge clk or negedge rst_n) begin : proc_act_data_in_req
      if(~rst_n) begin
         act_data_in_req <= 0;
         act_data_in_req_d <= 0;
      end else begin
         // criteria: 1. any of status_act_buf is zero; 2. act_data_in_req_en is trigered; 3. ~act_data_in_req_d
         act_data_in_req <= ~status_act_buf[0] | ~status_act_buf[1] &  act_data_in_req_en & ~act_data_in_req_d;
      end
   end

   wire comp_flag; 
   // indicate the computation can be continued. criteria: any of status_act_buf is one.
   assign comp_flag = status_act_buf[0] | status_act_buf[1];

   reg [WB_DELAY_CYCLE-1:0] comp_flag_d;
   always_ff @(posedge clk or negedge rst_n) begin : proc_comp_flag_d
      if(~rst_n) begin
         comp_flag_d <= 0;
      end else begin
         comp_flag_d[0] <= comp_flag;
         for (jj=1; jj<WB_DELAY_CYCLE; jj=jj+1) begin
            comp_flag_d[ii] <= comp_flag_d[ii-1];
         end
      end
   end

   // act buf wr address
   reg [WID_ACTADDR-2:0] cnt_act_in_tile_trip;
   reg [WID_N_TILE-1:0]  cnt_act_in_tile_idx; 

   assign act_wr_addr_hbit <= {toggle_act_in, cnt_act_in_tile_trip};
   always_ff @(posedge clk or negedge rst_n) begin : proc_act_wr_addr_hbit
      if(~rst_n) begin
         act_wr_addr_hbit <= 0;
         cnt_act_in_tile_trip <= 0;
         cnt_act_in_tile_idx <= 0;
      end else begin
         if (act_data_in_vld) begin
            cnt_act_in_tile_trip <= (cnt_act_in_tile_trip==(n_tn*n_tp-1))? 0 : cnt_act_in_tile_trip + 1;
            cnt_act_in_tile_idx <= (cnt_act_in_tile_trip==(n_tn*n_tp-1))? cnt_act_in_tile_idx + 1 : cnt_act_in_tile_idx;
         end
         act_wr_en <= act_data_in_vld? (1 << cnt_act_in_tile_idx) : 0;
      end
   end   
end

endmodule // sblk_ctrl
















































