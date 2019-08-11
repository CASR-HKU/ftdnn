// SuperBlock

module sblk(/*AUTOARG*/
            // Inputs
            clk_h, clk_l
            );

   // number of supertile inside the superblock
   parameter NTILE = 4;

   parameter W_BIT = 16;
   parameter WADDR_BIT = 10;
   parameter ACT_BIT = 16;
   parameter ACTADDR_BIT = 6;   

   parameter PSUM_BUF_BIT = 16;
   parameter PSUM_START_POS = 22;

   
   input wire clk_h, clk_l;
   input wire rst_n;
   
   input wire [NTILE*ACT_BIT-1:0] act_wr_data;
   input wire [NTILE-1:0]         act_wr_en;
   input wire [NTILE*W_BIT-1:0]   w_wr_data;
   input wire [NTILE-1:0]         w_wr_en;

   wire [NTILE*48-1:0]            psum;  // psum output of each stile
   
   
   // instance SuperTiles
   // start tile
   stile u_startstile(
                      .clk_l(clk_l),
                      .clk_h(clk_h),
                      .rst_n(rst_n),
                      .w_wr_data(w_wr_data[0*W_BIT+:W_BIT]),
                      .w_wr_en(w_wr_en[0]),
                      .act_wr_data(act_wr_data[0*ACT_BIT+:ACT_BIT]),
                      .act_wr_en(act_wr_en[0]),
                      .p_casout(psum[0*48+:48]),
                      .p_sumin(psum_stile_in)
                      );

   
   // middle tiles
   genvar                         ii;
   generate
      for (ii=1; ii<NUM_TILE-1; ii=ii+1) begin
         stile u_stile(
                       .clk_l(clk_l),
                       .clk_h(clk_h),
                       .rst_n(rst_n),
                       .w_wr_data(w_wr_data[ii*W_BIT+:W_BIT]),
                       .w_wr_en(w_wr_en[ii]),
                       .act_wr_data(act_wr_data[ii*ACT_BIT+:ACT_BIT]),
                       .act_wr_en(act_wr_en[ii]),
                       .p_casout(psum[ii*48+:48]),
                       .p_casin(psum[(ii-1)*48+:48])
                       );
      end
   endgenerate

   // endtile
   stile u_endtile(
                   .clk_l(clk_l),
                   .clk_h(clk_h),
                   .rst_n(rst_n),
                   .w_wr_data(w_wr_data[(NTILE-1)*W_BIT+:W_BIT]),
                   .w_wr_en(w_wr_en[NTILE-1]),
                   .act_wr_data(act_wr_data[(NTILE-1)*ACT_BIT+:ACT_BIT]),
                   .act_wr_en(act_wr_en[NTILE-1]),
                   .p_out(psum[(NTILE-1)*48+:48]),
                   .p_casin(psum[(NTILE-1)*48+:48])
                   );


   // controller part

   // control registers
   reg [3-1:0] kernel; // MAX8 NOTE: the number should be -1 than the real kernel size
   reg [2-1:0] stride; // MAX4 NOTE: the number should be -1 than the real stride
   reg [5-1:0] n_wintile; // window number in one tile NOTE: the real win number is the double of this number -1
   reg [4-1:0] n_ofm; // number of output feature maps scheduled on this SuperBlock
   // FIXME: should be loaded outside
   parameter KERLINE_OFFSET = {12, 0, 4, 8}; // represent L4 L1 L2 L3 in kernel
   parameter ACTUPDATE_FLAG = {0, 1, 1, 1}; // 0 represents no update in computing this kernel line, for reuse the same act for next kerline   
   // 
   reg [6-1:0] kerline_offset[8-1:0];
   // reg [10-1:0] kerofm_offset[16-1:0];
   reg [8-1:0] actupdate_flag;
   
   // act_rd_addr generator
   reg [ACTADDR_BIT-1:0] act_rd_addr;
   reg [ACTADDR_BIT-1:0] act_rd_addr0_clkl, act_rd_addr1_clkl;


   // state counter
   reg [3-1:0]           cnt_kerw;
   reg [3-1:0]           cnt_kerh;
   reg [5-1:0]           cnt_wintile;
   reg [4-1:0]           cnt_ofm;
   // FIXME: evaluate the logic resource
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_cnt
      if(~rst_n) begin
         cnt_kerw <= 0;
         cnt_kerh <= 0;
         cnt_wintile <=0;
         cnt_ofm <= 0;
      end else begin
         // cycle0 for `act_rd_addr`
         cnt_kerw <= (cnt_kerw==kernel)? 0 : (cnt_kerw + 1);
         cnt_wintile <= (cnt_kerw==kernel)? ((cnt_wintile==n_wintile)?0:(cnt_wintile+1)) : cnt_wintile;
         cnt_ofm <= (cnt_kerw==kernel && cnt_wintile==n_wintile)? ((cnt_ofm==n_ofm)?0:cnt_ofm+1) : cnt_ofm;
         // cnt_kerh
         if (cnt_kerw==kernel && cnt_wintile==n_wintile && cnt_ofm==n_ofm) begin
            cnt_kerh <= (cnt_kerh==kernel)? 0 : (cnt_kerh + 1);
         end
      end // else: !if(~rst_n)
   end // block: proc_cnt

   // activation read address generator
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_act_rd_addr_clkl
      if(~rst_n) begin
         act_rd_addr0_clkl <= 0;
         act_rd_addr1_clkl <= 0;
      end else begin
         // cycle1 in `act_rd_addr`
         act_rd_addr0_clkl <= (cnt_wintile << 1)*(stride+1) + cnt_kerw;
         act_rd_addr1_clkl <= (cnt_wintile << 1 + 1)*(stride+1) + cnt_kerw;
      end
   end

   always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_rd_addr
      if(~rst_n) begin
         act_rd_addr <= 0;
      end else begin
         act_rd_addr <= clkh_toggle ? act_rd_addr1_clkl : act_rd_addr0_clkl;
      end
   end


   // w_rd_addr generator (for SRAM in stile)
   reg [WADDR_BIT-1:0] w_rd_addr;
   always_ff @(posedge clk_l or negedge rst_n) begin : proc_w_rd_addr
      if(~rst_n) begin
         w_rd_addr <= 0;
      end else begin
         w_rd_addr <= kerline_offset[cnt_kerh] + cnt_kerw + cnt_ofm * kernel * kernel;
      end
   end

   
   
   // CLKH->CLKL concoction, add two delay stages for timing
   reg [PSUM_BUF_BIT-1:0] psum_wr_d0, psum_wr_d1;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_wr_d
      if(~rst_n) begin
         psum_wr_d0 <= 0;
         psum_wr_d1 <= 0;
      end else begin
         // select the proper bits from the last stile psum
         psum_wr_d0 <= psum[(NTILE-1)*48+PSUM_START_POS+:PSUM_BUF_BIT];
         psum_wr_d1 <= psum_wr_d0;
      end
   end

   assign psum_buf_wr_data = {psum_wr_d0, psum_wr_d1};


   // CLKL->CLKH separation
   // toggle
   reg clkh_toggle;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_clkh_toggle
      if(~rst_n) begin
         clkh_toggle <= 0;
      end else begin
         clkh_toggle <= ~clkh_toggle;
      end
   end

     
   // mux for psum selection
   reg [48-1:0] psum_stile_in;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_stile_in
      if(~rst_n) begin
         psum_stile_in <= 0;
      end else begin
         psum_stile_in <= clkh_toggle ? {{48-PSUM_BUF_BIT-PSUM_START_POS{psum_buf_rd_data[PSUM_BUF_BIT*2-1]}}, psum_buf_rd_data[PSUM_BUF_BIT+:PSUM_BUF_BIT], {PSUM_START_POS{1'b0}}} :  {{48-PSUM_BUF_BIT-PSUM_START_POS{psum_buf_rd_data[PSUM_BUF_BIT-1]}}, psum_buf_rd_data[0+:PSUM_BUF_BIT], {PSUM_START_POS{1'b0}}};
       end
   end


   // psum buffer rd addr generator
   

   




   // psum buffer
   wire [PSUM_BUF_BIT*2-1:0] psum_buf_rd_data;
   wire [PSUM_BUF_BIT*2-1:0] psum_buf_wr_data;

   wire [10-1:0]              psum_buf_rd_addr;
   wire [10-1:0]              psum_buf_wr_addr;

   wire                      psum_buf_wr_en;

   BRAM_SDP_MACRO #(
                    .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb" 
                    .DEVICE("7SERIES"), // Target device: "7SERIES" 
                    .WRITE_WIDTH(PSUM_BUF_BIT*2),    // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
                    .READ_WIDTH(PSUM_BUF_BIT*2),     // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
                    .DO_REG(1),         // Optional output register (0 or 1)
                    .INIT_FILE ("NONE"),
                    .SIM_COLLISION_CHECK ("ALL"), // Collision check enable "ALL", "WARNING_ONLY", 
                    //   "GENERATE_X_ONLY" or "NONE" 
                    .SRVAL(72'h000000000000000000), // Set/Reset value for port output
                    .INIT(72'h000000000000000000),  // Initial values on output port
                    .WRITE_MODE("WRITE_FIRST")  // Specify "READ_FIRST" for same clock or synchronous clocks
                    //   Specify "WRITE_FIRST for asynchronous clocks on ports
                    )      
   BRAM_SDP_MACRO_inst (
                        .DO(psum_buf_rd_data),         // Output read data port, width defined by READ_WIDTH parameter
                        .DI(psum_buf_wr_data),         // Input write data port, width defined by WRITE_WIDTH parameter
                        .RDADDR(psum_buf_rd_addr), // Input read address, width defined by read port depth
                        .RDCLK(clk_l),   // 1-bit input read clock
                        .RDEN(1),     // 1-bit input read port enable
                        .REGCE(1),   // 1-bit input read output register enable
                        .RST(~rst_n),       // 1-bit input reset      
                        .WE(psum_buf_wr_en),         // Input write enable, width defined by write port depth
                        .WRADDR(psum_buf_wr_addr), // Input write address, width defined by write port depth
                        .WRCLK(clk_l),   // 1-bit input write clock
                        .WREN(1'b1)      // 1-bit input write port enable
                        );   

   
endmodule // sblk

