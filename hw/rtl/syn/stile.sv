// SuperTile
`timescale 1ns / 1ns

module stile(/*AUTOARG*/
             // Outputs
             p_out, p_casout,
             // Inputs
             clk_h, clk_l, rst_n, w_wr_data, w_wr_addr, w_wr_en, w_rd_addr,
             act_wr_data, act_wr_addr_hbit, act_wr_en, act_rd_addr,
             p_casin, p_sumin
             );

   parameter WID_W = 16;
   // each BRAM18 can be configured to a shape of 16x1024
   parameter WID_WADDR = 10;
   parameter WID_ACT = 16;
   // TODO: Distributed RAM size, 64x1S cost 1LUT
   parameter WID_ACTADDR = 6;
   // OPMODE for DSP
   parameter OPMODE = 7'b0010101;  // 7'b0110101 for the start NOTE: for DSPE2 in UltraScale, should use 8bit 8'bx0010101
   parameter [256-1:0] BRAM_INIT_VAL[64-1:0] = '{64{256'h0001000100010001000100010001000100010001000100010001000100010001}};

   input wire clk_h;
   input wire clk_l;

   input wire rst_n;
   
   //FIXME: to BRAM, weight buffer wr signal, not used currently
   input wire [WID_W-1:0] w_wr_data;
   input wire [WID_WADDR-1:0] w_wr_addr;
   input wire                 w_wr_en;

   wire [WID_W-1:0]           w_rd_data;
   input wire [WID_WADDR-1:0] w_rd_addr;

   // to DisRAM, act buffer wr signal
   input wire [2*WID_ACT-1:0]   act_wr_data;
   input wire [WID_ACTADDR-2:0] act_wr_addr_hbit;
   input wire                   act_wr_en;

   wire [WID_ACT-1:0]           act_rd_data;
   input wire [WID_ACTADDR-1:0] act_rd_addr;

   
   // reg                          act_rd_addr_lbit;
   reg                          act_wr_addr_lbit;
   
   // DSP connection signal
   input wire [48-1:0]          p_casin;
   input wire [48-1:0]          p_sumin;   
   output wire [48-1:0]         p_out;
   output wire [48-1:0]         p_casout;

   always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_rd_wr_addr_lbit
      if(~rst_n) begin
         // act_rd_addr_lbit <= 0;
         act_wr_addr_lbit <= 0;
      end else begin
         // act_rd_addr_lbit <= ~act_rd_addr_lbit;
         act_wr_addr_lbit <= ~act_wr_addr_lbit;
      end
   end

   reg [WID_ACT-1:0] act_rd_data_d;
   always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_rd_data_d
     if(~rst_n) begin
       act_rd_data_d <= 0;
     end else begin
       act_rd_data_d <= act_rd_data;
     end
   end


   wire [WID_ACT-1:0] act_wr_data_clkh;
   assign act_wr_data_clkh = act_wr_addr_lbit? act_wr_data[WID_ACT+:WID_ACT] : act_wr_data[0+:WID_ACT];
   

   DSP48E1 #(
      // Feature Control Attributes: Data Path Selection
      .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
      .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
      .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
      // Pattern Detector Attributes: Pattern Detection Configuration
      .AUTORESET_PATDET("NO_RESET"),    // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
      .MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
      .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
      .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
      .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
      .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(1),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
      .ADREG(1),                        // Number of pipeline stages for pre-adder (0 or 1)
      .ALUMODEREG(1),                   // Number of pipeline stages for ALUMODE (0 or 1)
      .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
      .BCASCREG(1),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
      .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
      .CARRYINREG(1),                   // Number of pipeline stages for CARRYIN (0 or 1)
      .CARRYINSELREG(1),                // Number of pipeline stages for CARRYINSEL (0 or 1)
      .CREG(1),                         // Number of pipeline stages for C (0 or 1)
      .DREG(1),                         // Number of pipeline stages for D (0 or 1)
      .INMODEREG(1),                    // Number of pipeline stages for INMODE (0 or 1)
      .MREG(1),                         // Number of multiplier pipeline stages (0 or 1)
      .OPMODEREG(1),                    // Number of pipeline stages for OPMODE (0 or 1)
      .PREG(1)                          // Number of pipeline stages for P (0 or 1)
   )
   DSP48E1_inst (
      // Cascade: 30-bit (each) output: Cascade Ports
      // .ACOUT(ACOUT),                   // 30-bit output: A port cascade output
      // .BCOUT(BCOUT),                   // 18-bit output: B port cascade output
      // .CARRYCASCOUT(CARRYCASCOUT),     // 1-bit output: Cascade carry output
      // .MULTSIGNOUT(MULTSIGNOUT),       // 1-bit output: Multiplier sign cascade output
      .PCOUT(p_casout),                   // 48-bit output: Cascade output
      // Control: 1-bit (each) output: Control Inputs/Status Bits
      // .OVERFLOW(OVERFLOW),             // 1-bit output: Overflow in add/acc output
      // .PATTERNBDETECT(PATTERNBDETECT), // 1-bit output: Pattern bar detect output
      // .PATTERNDETECT(PATTERNDETECT),   // 1-bit output: Pattern detect output
      // .UNDERFLOW(UNDERFLOW),           // 1-bit output: Underflow in add/acc output
      // Data: 4-bit (each) output: Data Ports
      // .CARRYOUT(CARRYOUT),             // 4-bit output: Carry output
      .P(p_out),                           // 48-bit output: Primary data output
      // Cascade: 30-bit (each) input: Cascade Ports
      // .ACIN(ACIN),                     // 30-bit input: A cascade data input
      // .BCIN(BCIN),                     // 18-bit input: B cascade input
      // .CARRYCASCIN(CARRYCASCIN),       // 1-bit input: Cascade carry input
      // .MULTSIGNIN(MULTSIGNIN),         // 1-bit input: Multiplier sign input
      .PCIN(p_casin),                     // 48-bit input: P cascade input
      // Control: 4-bit (each) input: Control Inputs/Status Bits
      .ALUMODE(4'b0000),               // 4-bit input: ALU control input
      // .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select input
      .CLK(clk_h),                       // 1-bit input: Clock input
      .INMODE(4'b0001),                 // 5-bit input: INMODE control input
      .OPMODE(OPMODE),                 // 7-bit input: Operation mode input
      // Data: 30-bit (each) input: Data Ports
      .A(w_rd_data),                           // 30-bit input: A data input
      .B(act_rd_data_d),                           // 18-bit input: B data input
      .C(p_sumin),                           // 48-bit input: C data input
      // .CARRYIN(CARRYIN),               // 1-bit input: Carry input signal
      // .D(D),                           // 25-bit input: D data input
      // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
      .CEA1(1),                     // 1-bit input: Clock enable input for 1st stage AREG
      .CEA2(1),                     // 1-bit input: Clock enable input for 2nd stage AREG
      .CEAD(1),                     // 1-bit input: Clock enable input for ADREG
      .CEALUMODE(1),           // 1-bit input: Clock enable input for ALUMODE
      .CEB1(1),                     // 1-bit input: Clock enable input for 1st stage BREG
      .CEB2(1),                     // 1-bit input: Clock enable input for 2nd stage BREG
      .CEC(1),                       // 1-bit input: Clock enable input for CREG
      .CECARRYIN(1),           // 1-bit input: Clock enable input for CARRYINREG
      .CECTRL(1),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
      .CED(1),                       // 1-bit input: Clock enable input for DREG
      .CEINMODE(1),             // 1-bit input: Clock enable input for INMODEREG
      .CEM(1),                       // 1-bit input: Clock enable input for MREG
      .CEP(1),                       // 1-bit input: Clock enable input for PREG
      .RSTA(~rst_n),                     // 1-bit input: Reset input for AREG
      .RSTALLCARRYIN(~rst_n),   // 1-bit input: Reset input for CARRYINREG
      .RSTALUMODE(~rst_n),         // 1-bit input: Reset input for ALUMODEREG
      .RSTB(~rst_n),                     // 1-bit input: Reset input for BREG
      .RSTC(~rst_n),                     // 1-bit input: Reset input for CREG
      .RSTCTRL(~rst_n),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
      .RSTD(~rst_n),                     // 1-bit input: Reset input for DREG and ADREG
      .RSTINMODE(~rst_n),           // 1-bit input: Reset input for INMODEREG
      .RSTM(~rst_n),                     // 1-bit input: Reset input for MREG
      .RSTP(~rst_n)                      // 1-bit input: Reset input for PREG
   );


   genvar                       ii;
   // generate DisRAM array for act buffer
   generate
      for (ii=0; ii<WID_ACT; ii=ii+1) begin
         RAM64X1D #(
                    .INIT(64'h0000000000000000) // Initial contents of RAM
                    )
         RAM64X1D_inst (
                        .DPO(act_rd_data[ii]),     // Read-only 1-bit data output
                        // .SPO(SPO),     // Rw/ 1-bit data output
                        .A0(act_wr_addr_lbit),       // Rw/ address[0] input bit
                        .A1(act_wr_addr_hbit[0]),       // Rw/ address[1] input bit
                        .A2(act_wr_addr_hbit[1]),       // Rw/ address[2] input bit
                        .A3(act_wr_addr_hbit[2]),       // Rw/ address[3] input bit
                        .A4(act_wr_addr_hbit[3]),       // Rw/ address[4] input bit
                        .A5(act_wr_addr_hbit[4]),       // Rw/ address[5] input bit
                        .D(act_wr_data_clkh[ii]),         // Write 1-bit data input
                        .DPRA0(act_rd_addr[0]), // Read-only address[0] input bit
                        .DPRA1(act_rd_addr[1]), // Read-only address[1] input bit
                        .DPRA2(act_rd_addr[2]), // Read-only address[2] input bit
                        .DPRA3(act_rd_addr[3]), // Read-only address[3] input bit
                        .DPRA4(act_rd_addr[4]), // Read-only address[4] input bit
                        .DPRA5(act_rd_addr[5]), // Read-only address[5] input bit
                        .WCLK(clk_h),   // Write clock input
                        .WE(act_wr_en)        // Write enable input
                        );
      end
   endgenerate

   BRAM_SINGLE_MACRO #(
      .BRAM_SIZE("18Kb"), // Target BRAM, "18Kb" or "36Kb" 
      .DEVICE("7SERIES"), // Target Device: "7SERIES" 
      .DO_REG(1), // Optional output register (0 or 1)
      .INIT(36'h000000000), // Initial values on output port
      .INIT_FILE ("NONE"),
      .WRITE_WIDTH(16), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      .READ_WIDTH(16),  // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      .SRVAL(36'h000000000), // Set/Reset value for port output
      .WRITE_MODE("READ_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE" 
      .INIT_00(BRAM_INIT_VAL[0]),
      .INIT_01(BRAM_INIT_VAL[1]),
      .INIT_02(BRAM_INIT_VAL[2]),
      .INIT_03(BRAM_INIT_VAL[3]),
      .INIT_04(BRAM_INIT_VAL[4]),
      .INIT_05(BRAM_INIT_VAL[5]),
      .INIT_06(BRAM_INIT_VAL[6]),
      .INIT_07(BRAM_INIT_VAL[7]),
      .INIT_08(BRAM_INIT_VAL[8]),
      .INIT_09(BRAM_INIT_VAL[9]),
      .INIT_0A(BRAM_INIT_VAL[10]),
      .INIT_0B(BRAM_INIT_VAL[11]),
      .INIT_0C(BRAM_INIT_VAL[12]),
      .INIT_0D(BRAM_INIT_VAL[13]),
      .INIT_0E(BRAM_INIT_VAL[14]),
      .INIT_0F(BRAM_INIT_VAL[15]),
      .INIT_10(BRAM_INIT_VAL[16]),
      .INIT_11(BRAM_INIT_VAL[17]),
      .INIT_12(BRAM_INIT_VAL[18]),
      .INIT_13(BRAM_INIT_VAL[19]),
      .INIT_14(BRAM_INIT_VAL[20]),
      .INIT_15(BRAM_INIT_VAL[21]),
      .INIT_16(BRAM_INIT_VAL[22]),
      .INIT_17(BRAM_INIT_VAL[23]),
      .INIT_18(BRAM_INIT_VAL[24]),
      .INIT_19(BRAM_INIT_VAL[25]),
      .INIT_1A(BRAM_INIT_VAL[26]),
      .INIT_1B(BRAM_INIT_VAL[27]),
      .INIT_1C(BRAM_INIT_VAL[28]),
      .INIT_1D(BRAM_INIT_VAL[29]),
      .INIT_1E(BRAM_INIT_VAL[30]),
      .INIT_1F(BRAM_INIT_VAL[31]),
      .INIT_20(BRAM_INIT_VAL[32]),
      .INIT_21(BRAM_INIT_VAL[33]),
      .INIT_22(BRAM_INIT_VAL[34]),
      .INIT_23(BRAM_INIT_VAL[35]),
      .INIT_24(BRAM_INIT_VAL[36]),
      .INIT_25(BRAM_INIT_VAL[37]),
      .INIT_26(BRAM_INIT_VAL[38]),
      .INIT_27(BRAM_INIT_VAL[39]),
      .INIT_28(BRAM_INIT_VAL[40]),
      .INIT_29(BRAM_INIT_VAL[41]),
      .INIT_2A(BRAM_INIT_VAL[42]),
      .INIT_2B(BRAM_INIT_VAL[43]),
      .INIT_2C(BRAM_INIT_VAL[44]),
      .INIT_2D(BRAM_INIT_VAL[45]),
      .INIT_2E(BRAM_INIT_VAL[46]),
      .INIT_2F(BRAM_INIT_VAL[47]),
      .INIT_30(BRAM_INIT_VAL[48]),
      .INIT_31(BRAM_INIT_VAL[49]),
      .INIT_32(BRAM_INIT_VAL[50]),
      .INIT_33(BRAM_INIT_VAL[51]),
      .INIT_34(BRAM_INIT_VAL[52]),
      .INIT_35(BRAM_INIT_VAL[53]),
      .INIT_36(BRAM_INIT_VAL[54]),
      .INIT_37(BRAM_INIT_VAL[55]),
      .INIT_38(BRAM_INIT_VAL[56]),
      .INIT_39(BRAM_INIT_VAL[57]),
      .INIT_3A(BRAM_INIT_VAL[58]),
      .INIT_3B(BRAM_INIT_VAL[59]),
      .INIT_3C(BRAM_INIT_VAL[60]),
      .INIT_3D(BRAM_INIT_VAL[61]),
      .INIT_3E(BRAM_INIT_VAL[62]),
      .INIT_3F(BRAM_INIT_VAL[63])
   ) BRAM_SINGLE_MACRO_inst (
      .DO(w_rd_data),       // Output data, width defined by READ_WIDTH parameter
      .ADDR(w_rd_addr),   // Input address, width defined by read/write port depth
      .CLK(clk_l),     // 1-bit input clock
      // .DI(DI),       // Input data port, width defined by WRITE_WIDTH parameter
      .EN(1'b1),       // 1-bit input RAM enable
      .REGCE(1'b1), // 1-bit input output register enable
      .RST(~rst_n),     // 1-bit input reset
      .WE(1'b0)        // Input write enable, width defined by write port depth
   );

endmodule

