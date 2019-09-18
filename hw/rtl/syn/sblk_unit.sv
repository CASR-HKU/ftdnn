// Behavior of SuperBlock Unit (units in horizontal compose the SuperBlock)
`timescale 1ns / 1ns

module sblk_unit(/*AUTOARG*/
                 // Outputs
                 psum_rd_data,
                 // Inputs
                 clk_h, clk_l, rst_n, act_data_in, act_wr_en, act_wr_addr_hbit,
                 act_rd_addr_hbit, w_rd_addr, psum_wr_addr, psum_wr_en,
                 psum_rd_addr
                 );

   parameter N_TILE = 40;
   parameter WID_N_TILE = $clog2(N_TILE);
   parameter WID_W = 16;
   parameter WID_WADDR = 10;
   parameter WID_ACT = 16;
   parameter WID_ACTADDR = 6;
   parameter WID_PSUM = 32;
   parameter WID_PSUMADDR = 9;
   parameter PSUM_SPLIT_START_POS = 0;

   localparam ACT_WR_DELAY_FACTOR = 8;

   input wire clk_h, clk_l;
   input wire rst_n;
   
   // signals from controller, NOTE: may change for MV / CONV, etc. 
   // activation buffer wr signal
   input wire [2*WID_ACT-1:0] act_data_in;
   
   input wire [N_TILE-1:0]    act_wr_en;
   // activation buffer wr signal
   input wire [WID_ACTADDR-2:0] act_wr_addr_hbit;
   // activation buffer rd signal
   input wire [WID_ACTADDR-2:0] act_rd_addr_hbit;
   // weight buffer rd signal
   input wire [WID_WADDR-1:0]   w_rd_addr;
   // psum buffer wr signal
   input wire [WID_PSUMADDR-1:0] psum_wr_addr;
   input wire                    psum_wr_en;
   // psum buffer rd signal
   input wire [WID_PSUMADDR-1:0] psum_rd_addr;
   // FIXME
   output wire [2*WID_PSUM-1:0]  psum_rd_data;

   // tmp wire for psum of each DSP
   wire [N_TILE*48-1:0]          psum;  // psum output of each stile

   // dealy of act_in
   reg [2*WID_ACT-1:0] act_wr_data_d[N_TILE/ACT_WR_DELAY_FACTOR];
   reg [N_TILE-1:0] act_wr_en_d[N_TILE/ACT_WR_DELAY_FACTOR];
   reg [WID_ACTADDR-2:0] act_wr_addr_hbit_d[N_TILE/ACT_WR_DELAY_FACTOR];
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_act_wr_data_d
      if(~rst_n) begin
         for (int ii=0; ii<N_TILE/ACT_WR_DELAY_FACTOR; ii=ii+1) begin
            act_wr_data_d[ii] <= 0;
            act_wr_en_d[ii] <= 0;
            act_wr_addr_hbit_d[ii] <= 0;
         end
      end else begin
         act_wr_data_d[0] <= act_data_in;
         act_wr_en_d[0] <= act_wr_en;
         act_wr_addr_hbit_d[0] <= act_wr_addr_hbit;
         for (int ii=1; ii<N_TILE/ACT_WR_DELAY_FACTOR; ii=ii+1) begin
            act_wr_data_d[ii] <= act_wr_data_d[ii-1];
            act_wr_en_d[ii] <= act_wr_en_d[ii-1];
            act_wr_addr_hbit_d[ii] <= act_wr_addr_hbit_d[ii-1];
         end
      end
   end


   // clkh->clkl connection, add two delay stages for timing
   reg [WID_PSUM-1:0]     psum_wr_d;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_wr_d
      if(~rst_n) begin
         psum_wr_d <= 0;
      end else begin
         //FIXME: select the proper bits from the last stile psum
         psum_wr_d <= psum[(N_TILE-1)*48+PSUM_SPLIT_START_POS+:WID_PSUM];
      end
   end

   reg  [2*WID_PSUM-1:0]      psum_wr_data;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_psum_wr_data
      if(~rst_n) begin
         psum_wr_data <= 0;
      end else begin
         psum_wr_data <= {psum[(N_TILE-1)*48+PSUM_SPLIT_START_POS+:WID_PSUM], psum_wr_d};
      end
   end

   reg clkh_toggle;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_clkh_toggle
      if(~rst_n) begin
         clkh_toggle <= 0;
      end else begin
         clkh_toggle <= ~clkh_toggle;
      end
   end


   wire [WID_PSUM-1:0]      psum_stile_in;
   reg [WID_PSUM-1:0]       psum_stile_in_d;
   reg [2*WID_PSUM-1:0]     psum_rd_data_d;
   assign psum_stile_in = clkh_toggle? psum_rd_data_d[WID_PSUM+:WID_PSUM] : psum_rd_data_d[0+:WID_PSUM];

   always_ff @(posedge clk_l or negedge rst_n) begin : proc_psum_rd_data_d
      if(~rst_n) begin
         psum_rd_data_d <= 0;     
      end else begin         
         psum_rd_data_d <= psum_rd_data;
      end
   end

   always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_stile_in_d
      if(~rst_n) begin
         psum_stile_in_d <= 0;
      end else begin
         psum_stile_in_d <= psum_stile_in;
      end
   end

   // delay the addr signals, NOTE: 1-cycle dealy constraint of cascaded DSPs
   reg [WID_ACTADDR-1:0] act_rd_addr_d[N_TILE+4:0];
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_rd_addr_d
      if(~rst_n) begin
         for (int jj=0; jj<N_TILE+5; jj=jj+1) begin
            act_rd_addr_d[jj] <= 0;
         end
      end else begin
         act_rd_addr_d[0] <= {act_rd_addr_hbit, clkh_toggle};
         for (int jj=1; jj<N_TILE+5; jj=jj+1) begin
            act_rd_addr_d[jj] <= act_rd_addr_d[jj-1];
         end
      end
   end


   // propogate the w_rd_addr with clk_h 
   reg [WID_WADDR-1:0] w_rd_addr_d[N_TILE:0];
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_w_rd_addr_d
      if(~rst_n) begin
         for (int jj=0; jj<N_TILE+1; jj=jj+1) begin
            w_rd_addr_d[jj] <= 0;
         end
      end else begin
         w_rd_addr_d[0] <= w_rd_addr;
         for (int jj=1; jj<N_TILE+1; jj=jj+1) begin
            w_rd_addr_d[jj] <= w_rd_addr_d[jj-1];
         end
      end
   end

   // instance SuperTiles
   // start tile
   stile #(.OPMODE(7'b0110101))
   u_start_stile(
                 .clk_l(clk_l),
                 .clk_h(clk_h),
                 .rst_n(rst_n),
                 .w_wr_en(1'b0),
                 .w_rd_addr(w_rd_addr_d[1]),
                 .act_wr_data(act_wr_data_d[0]),
                 .act_wr_en(act_wr_en_d[0][0]),
                 .act_wr_addr_hbit(act_wr_addr_hbit_d[0]),
                 .act_rd_addr(act_rd_addr_d[4]),
                 .p_casout(psum[0*48+:48]),
                 .p_sumin({{(48-PSUM_SPLIT_START_POS-WID_PSUM){1'b0}}, psum_stile_in_d, {PSUM_SPLIT_START_POS{1'b0}}})
                 );
   // middle tiles
   genvar                         ii;
   generate
      for (ii=1; ii<N_TILE-1; ii=ii+1) begin: u_mid_tile
         stile
              u_mid_stile(
                          .clk_l(clk_l),
                          .clk_h(clk_h),
                          .rst_n(rst_n),
                          .w_wr_en(1'b0),
                          .w_rd_addr(w_rd_addr_d[ii+1]),
                          .act_wr_data(act_wr_data_d[ii/ACT_WR_DELAY_FACTOR]),
                          .act_wr_en(act_wr_en_d[ii/ACT_WR_DELAY_FACTOR][ii]),
                          .act_wr_addr_hbit(act_wr_addr_hbit_d[ii/ACT_WR_DELAY_FACTOR]),
                          .act_rd_addr(act_rd_addr_d[ii+4]),
                          .p_casout(psum[ii*48+:48]),
                          .p_casin(psum[(ii-1)*48+:48])
                          );
      end
   endgenerate

   // last tile
   stile
     u_end_stile(
                 .clk_l(clk_l),
                 .clk_h(clk_h),
                 .rst_n(rst_n),
                 .w_wr_en(1'b0),
                 .w_rd_addr(w_rd_addr_d[N_TILE]),
                 .act_wr_data(act_wr_data_d[(N_TILE-1)/ACT_WR_DELAY_FACTOR]),
                 .act_wr_en(act_wr_en_d[(N_TILE-1)/ACT_WR_DELAY_FACTOR][N_TILE-1]),
                 .act_wr_addr_hbit(act_wr_addr_hbit_d[(N_TILE-1)/ACT_WR_DELAY_FACTOR]),
                 .act_rd_addr(act_rd_addr_d[N_TILE+3]),
                 .p_out(psum[(N_TILE-1)*48+:48]),
                 .p_casin(psum[(N_TILE-1-1)*48+:48])
                 );


   // instante partial sum buffer
   BRAM_SDP_MACRO #(
      .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb" 
      .DEVICE("7SERIES"), // Target device: "7SERIES" 
      .WRITE_WIDTH(72),    // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      .READ_WIDTH(72),     // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      .DO_REG(1),         // Optional output register (0 or 1)
      .INIT_FILE ("NONE"),
      .SIM_COLLISION_CHECK ("ALL"), // Collision check enable "ALL", "WARNING_ONLY",
                                    //   "GENERATE_X_ONLY" or "NONE" 
      .SRVAL(72'h000000000000000000), // Set/Reset value for port output
      .INIT(72'h000000000000000000),  // Initial values on output port
      .WRITE_MODE("WRITE_FIRST")  // Specify "READ_FIRST" for same clock or synchronous clocks
                                   //   Specify "WRITE_FIRST for asynchronous clocks on ports
   ) BRAM_SDP_MACRO_inst (
      .DO(psum_rd_data),         // Output read data port, width defined by READ_WIDTH parameter
      .DI(psum_wr_data),         // Input write data port, width defined by WRITE_WIDTH parameter
      .RDADDR(psum_rd_addr), // Input read address, width defined by read port depth
      .RDCLK(clk_l),   // 1-bit input read clock
      .RDEN(1'b1),     // 1-bit input read port enable
      .REGCE(1'b1),   // 1-bit input read output register enable
      .RST(~rst_n),       // 1-bit input reset
      .WE(psum_wr_en),         // Input write enable, width defined by write port depth
      .WRADDR(psum_wr_addr), // Input write address, width defined by write port depth
      .WRCLK(clk_l),   // 1-bit input write clock
      .WREN(1'b1)      // 1-bit input write port enable
   );

endmodule
