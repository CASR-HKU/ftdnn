// SuperBlock

module sblk(/*AUTOARG*/
   // Inputs
   clk_h, clk_l, rst_n
   );

   // number of supertile inside the superblock
   parameter N_TILE = 4;
   parameter WID_W = 16;
   parameter WID_WADDR = 10;
   parameter WID_ACT = 16;
   parameter WID_ACTADDR = 6;

   parameter WID_PSUM = 36;
   parameter WID_PSUMADDR = 9;
   // strip the tail 12-btis in the 48-bits psum from dsp
   parameter PSUM_SPLIT_START_POS = 12;

   
   input wire clk_h, clk_l;
   input wire rst_n;
   

   // signals from controller, NOTE: may change for MV / CONV, etc. 
   // activation buffer wr signal
   wire [WID_ACT-1:0] act_wr_data;
   wire [N_TILE-1:0]  act_wr_en;
   wire [WID_ACTADDR-2:0] act_wr_addr_hbit;
   // activation buffer rd signal
   wire [WID_ACTADDR-2:0] act_rd_addr_hbit;
   // weight buffer rd signal
   wire [WID_WADDR-1:0] w_rd_addr;
   // psum buffer rd signal
   wire [WID_PSUM-1:0]    psum_rd_addr;
   // psum buffer wr signal
   wire [2*WID_PSUM-1:0]  psum_wr_data;
   wire [WID_PSUM-1:0]    psum_wr_addr;
   wire                   psum_wr_en;

   wire [WID_PSUM-1:0]    psum_rd_addr;
   wire [2*WID_PSUM-1:0]  psum_rd_data;


   // tmp wire for psum of each DSP
   wire [N_TILE*48-1:0]   psum;  // psum output of each stile

   // clkh->clkl connection, add two delay stages for timing
   reg [WID_PSUM-1:0]     psum_wr_d0;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_wr_d0
      if(~rst_n) begin
         psum_wr_d0 <= 0;
      end else begin
         //FIXME: select the proper bits from the last stile psum
         psum_wr_d0 <= psum[(NTILE-1)*48+PSUM_SPLIT_START_POS+:WID_PSUM];
      end
   end
   assign psum_wr_data = {psum[(NTILE-1)*48+PSUM_SPLIT_START_POS+:WID_PSUM], psum_wr_d0};


   reg clkh_toggle;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_clkh_toggle
      if(~rst_n) begin
         clkh_toggle <= 0;
      end else begin
         clkh_toggle <= ~clkh_toggle;
      end
   end

   reg [WID_PSUM-1:0]     psum_stile_in;
   reg [WID_PSUM-1:0]     psum_stile_in_d;   
   // toggle the half word from psum buffer as the psum input of first stile
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_stile_in
      if(~rst_n) begin
         psum_stile_in <= 0;
         psum_stile_in_d <= 0;
      end else begin
         psum_stile_in <= clkh_toggle? psum_rd_data[WID_PSUM+:WID_PSUM] : psum_rd_data[0+:WID_PSUM];
         psum_stile_in_d <= psum_stile_in;
      end
   end


   // delay the addr signals, NOTE: 1-cycle dealy constraint of cascaded DSPs
   int jj;
   reg [WID_ACTADDR-2:0]  act_rd_addr_hbit_d[N_TILE-1:0];   
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_rd_addr_hbit_d
      if(~rst_n) begin
         for (jj=0; jj<N_TILE; jj=jj+1) begin
            act_rd_addr_hbit_d[jj] <= 0;
         end
      end else begin
         act_rd_addr_hbit_d[0] <= act_rd_addr_hbit;
         for (jj=1; jj<N_TILE; jj=jj+1) begin
            act_rd_addr_hbit_d[jj] <= act_rd_addr_hbit_d[jj-1];
         end
      end
   end

   reg [WID_WADDR-1:0] w_rd_addr_d[N_TILE-2:0];
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_w_rd_addr_d
      if(~rst_n) begin
         for (jj=0; jj<N_TILE-2; jj=jj+1) begin
            w_rd_addr_d[jj] <= 0;
         end
      end else begin
         w_rd_addr_d[0] <= w_rd_addr;
         for (jj=1; jj<N_TILE-2; jj=jj+1) begin
            w_rd_addr_d[jj] <= w_rd_addr_d[jj-1];
         end
      end
   end


   // instance SuperTiles
   // start tile
   stile u_startstile(
                      .clk_l(clk_l),
                      .clk_h(clk_h),
                      .rst_n(rst_n),
                      .act_wr_data(act_wr_data),
                      .act_wr_en(act_wr_en[0]),
                      .act_wr_addr_hbit(act_wr_addr_hbit),
                      .act_rd_addr_hbit(act_rd_addr_hbit_d[0]),
                      .p_casout(psum[0*48+:48]),
                      .p_sumin(psum_stile_in_d)
                      );
   // middle tiles
   genvar                         ii;
   generate
      for (ii=1; ii<N_TILE-1; ii=ii+1) begin
         stile u_stile(
                       .clk_l(clk_l),
                       .clk_h(clk_h),
                       .rst_n(rst_n),
                       .act_wr_data(act_wr_data),
                       .act_wr_en(act_wr_en[ii]),
                       .act_wr_addr_hbit(act_wr_addr_hbit),
                       .act_rd_addr_hbit(act_rd_addr_hbit_d[ii]),
                       .p_casout(psum[ii*48+:48]),
                       .p_casin(psum[(ii-1)*48+:48])
                       );
      end
   endgenerate

   // last tile
   stile u_stile(
                 .clk_l(clk_l),
                 .clk_h(clk_h),
                 .rst_n(rst_n),
                 .act_wr_data(act_wr_data),
                 .act_wr_en(act_wr_en[ii]),
                 .act_wr_addr_hbit(act_wr_addr_hbit),
                 .act_rd_addr_hbit(act_rd_addr_hbit_d[N_TILE-1]),
                 .p_out(psum[ii*48+:48]),
                 .p_casin(psum[(ii-1)*48+:48])
                 );

   // instante partial sum buffer
   RAMB36E2 #(
              // CASCADE_ORDER_A, CASCADE_ORDER_B: "FIRST", "MIDDLE", "LAST", "NONE" 
              .CASCADE_ORDER_A("NONE"),
              .CASCADE_ORDER_B("NONE"),
              // CLOCK_DOMAINS: "COMMON", "INDEPENDENT" 
              .CLOCK_DOMAINS("INDEPENDENT"),
              .DOB_REG(1),
              // Collision check: "ALL", "GENERATE_X_ONLY", "NONE", "WARNING_ONLY" 
              .SIM_COLLISION_CHECK("ALL"),
              // DOA_REG, DOB_REG: Optional output register (0, 1)
              .DOA_REG(1),
              // ENADDRENA/ENADDRENB: Address enable pin enable, "TRUE", "FALSE" 
              .ENADDRENA("FALSE"),
              .ENADDRENB("FALSE"),
              // EN_ECC_PIPE: ECC pipeline register, "TRUE"/"FALSE" 
              .EN_ECC_PIPE("FALSE"),
              // EN_ECC_READ: Enable ECC decoder, "TRUE"/"FALSE" 
              .EN_ECC_READ("FALSE"),
              // EN_ECC_WRITE: Enable ECC encoder, "TRUE"/"FALSE" 
              .EN_ECC_WRITE("FALSE"),
              // INIT_A, INIT_B: Initial values on output ports
              .INIT_A(36'h000000000),
              .INIT_B(36'h000000000),
              // Initialization File: RAM initialization file
              .INIT_FILE("NONE"),
              // Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
              .IS_CLKARDCLK_INVERTED(1'b0),
              .IS_CLKBWRCLK_INVERTED(1'b0),
              .IS_ENARDEN_INVERTED(1'b0),
              .IS_ENBWREN_INVERTED(1'b0),
              .IS_RSTRAMARSTRAM_INVERTED(1'b0),
              .IS_RSTRAMB_INVERTED(1'b0),
              .IS_RSTREGARSTREG_INVERTED(1'b0),
              .IS_RSTREGB_INVERTED(1'b0),
              // RDADDRCHANGE: Disable memory access when output value does not change ("TRUE", "FALSE")
              .RDADDRCHANGEA("FALSE"),
              .RDADDRCHANGEB("FALSE"),
              // READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
              .READ_WIDTH_A(9),                                                                 // 0-9
              .READ_WIDTH_B(9),                                                                 // 0-9
              .WRITE_WIDTH_A(9),                                                                // 0-9
              .WRITE_WIDTH_B(9),                                                                // 0-9
              // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
              .RSTREG_PRIORITY_A("RSTREG"),
              .RSTREG_PRIORITY_B("RSTREG"),
              // SRVAL_A, SRVAL_B: Set/reset value for output
              .SRVAL_A(36'h000000000),
              .SRVAL_B(36'h000000000),
              // Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
              .SLEEP_ASYNC("FALSE"),
              // WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST" 
              .WRITE_MODE_A("NO_CHANGE"),
              .WRITE_MODE_B("NO_CHANGE") 
              )
   RAMB36E2_inst (
                  // Cascade Signals outputs: Multi-BRAM cascade signals
                  // .CASDOUTA(CASDOUTA),               // 32-bit output: Port A cascade output data
                  // .CASDOUTB(CASDOUTB),               // 32-bit output: Port B cascade output data
                  // .CASDOUTPA(CASDOUTPA),             // 4-bit output: Port A cascade output parity data
                  // .CASDOUTPB(CASDOUTPB),             // 4-bit output: Port B cascade output parity data
                  // .CASOUTDBITERR(CASOUTDBITERR),     // 1-bit output: DBITERR cascade output
                  // .CASOUTSBITERR(CASOUTSBITERR),     // 1-bit output: SBITERR cascade output
                  // ECC Signals outputs: Error Correction Circuitry ports
                  // .DBITERR(DBITERR),                 // 1-bit output: Double bit error status
                  // .ECCPARITY(ECCPARITY),             // 8-bit output: Generated error correction parity
                  // .RDADDRECC(RDADDRECC),             // 9-bit output: ECC Read Address
                  // .SBITERR(SBITERR),                 // 1-bit output: Single bit error status
                  // Port A Data outputs: Port A data
                  .DOUTADOUT(psum_rd_data),             // 32-bit output: Port A ata/LSB data
                  // .DOUTPADOUTP(DOUTPADOUTP),         // 4-bit output: Port A parity/LSB parity
                  // Port B Data outputs: Port B data
                  .DOUTBDOUT(psum_wr_data),             // 32-bit output: Port B data/MSB data
                  // .DOUTPBDOUTP(DOUTPBDOUTP),         // 4-bit output: Port B parity/MSB parity
                  // Cascade Signals inputs: Multi-BRAM cascade signals
                  // .CASDIMUXA(CASDIMUXA),             // 1-bit input: Port A input data (0=DINA, 1=CASDINA)
                  // .CASDIMUXB(CASDIMUXB),             // 1-bit input: Port B input data (0=DINB, 1=CASDINB)
                  // .CASDINA(CASDINA),                 // 32-bit input: Port A cascade input data
                  // .CASDINB(CASDINB),                 // 32-bit input: Port B cascade input data
                  // .CASDINPA(CASDINPA),               // 4-bit input: Port A cascade input parity data
                  // .CASDINPB(CASDINPB),               // 4-bit input: Port B cascade input parity data
                  // .CASDOMUXA(CASDOMUXA),             // 1-bit input: Port A unregistered data (0=BRAM data, 1=CASDINA)
                  // .CASDOMUXB(CASDOMUXB),             // 1-bit input: Port B unregistered data (0=BRAM data, 1=CASDINB)
                  // .CASDOMUXEN_A(CASDOMUXEN_A),       // 1-bit input: Port A unregistered output data enable
                  // .CASDOMUXEN_B(CASDOMUXEN_B),       // 1-bit input: Port B unregistered output data enable
                  // .CASINDBITERR(CASINDBITERR),       // 1-bit input: DBITERR cascade input
                  // .CASINSBITERR(CASINSBITERR),       // 1-bit input: SBITERR cascade input
                  // .CASOREGIMUXA(CASOREGIMUXA),       // 1-bit input: Port A registered data (0=BRAM data, 1=CASDINA)
                  // .CASOREGIMUXB(CASOREGIMUXB),       // 1-bit input: Port B registered data (0=BRAM data, 1=CASDINB)
                  // .CASOREGIMUXEN_A(CASOREGIMUXEN_A), // 1-bit input: Port A registered output data enable
                  // .CASOREGIMUXEN_B(CASOREGIMUXEN_B), // 1-bit input: Port B registered output data enable
                  // ECC Signals inputs: Error Correction Circuitry ports
                  // .ECCPIPECE(ECCPIPECE),             // 1-bit input: ECC Pipeline Register Enable
                  // .INJECTDBITERR(INJECTDBITERR),     // 1-bit input: Inject a double bit error
                  // .INJECTSBITERR(INJECTSBITERR),
                  // Port A Address/Control Signals inputs: Port A address and control signals
                  .ADDRARDADDR(psum_rd_addr),         // 15-bit input: A/Read port address
                  .ADDRENA(1'b1),                 // 1-bit input: Active-High A/Read port address enable
                  .CLKARDCLK(clk_l),             // 1-bit input: A/Read port clock
                  .ENARDEN(1'b1),                 // 1-bit input: Port A enable/Read enable
                  // .REGCEAREGCE(REGCEAREGCE),         // 1-bit input: Port A register enable/Register enable
                  // .RSTRAMARSTRAM(RSTRAMARSTRAM),     // 1-bit input: Port A set/reset
                  // .RSTREGARSTREG(RSTREGARSTREG),     // 1-bit input: Port A register set/reset
                  // .SLEEP(SLEEP),                     // 1-bit input: Sleep Mode
                  // .WEA(WEA),                         // 4-bit input: Port A write enable
                  // Port A Data inputs: Port A data
                  // .DINADIN(DINADIN),                 // 32-bit input: Port A data/LSB data
                  // .DINPADINP(DINPADINP),             // 4-bit input: Port A parity/LSB parity
                  // Port B Address/Control Signals inputs: Port B address and control signals
                  .ADDRBWRADDR(psum_wr_addr),         // 15-bit input: B/Write port address
                  .ADDRENB(1'b1),                 // 1-bit input: Active-High B/Write port address enable
                  .CLKBWRCLK(clk_l),             // 1-bit input: B/Write port clock
                  .ENBWREN(1'b1),                 // 1-bit input: Port B enable/Write enable
                  // .REGCEB(REGCEB),                   // 1-bit input: Port B register enable
                  // .RSTRAMB(RSTRAMB),                 // 1-bit input: Port B set/reset
                  // .RSTREGB(RSTREGB),                 // 1-bit input: Port B register set/reset
                  .WEBWE(psum_wr_en),                     // 8-bit input: Port B write enable/Write enable
                  // Port B Data inputs: Port B data
                  .DINBDIN(psum_wr_data),                 // 32-bit input: Port B data/MSB data
                  // .DINPBDINP(DINPBDINP)              // 4-bit input: Port B parity/MSB parity
                  );
   
endmodule // sblk

