// SuperTile

module stile(/*AUTOARG*/
             // Outputs
             p_out, p_casout,
             // Inputs
             clk_h, clk_l, rst_n, w_wr_data, w_wr_addr, w_wr_en, w_rd_addr,
             act_wr_data, act_wr_addr_hbit, act_wr_en, act_rd_addr_hbit,
             p_casin, p_sumin
             );

   parameter WID_W = 16;
   // each BRAM18 can be configured to a shape of 16x1024
   parameter WID_WADDR = 10;
   parameter WID_ACT = 16;
   // TODO: Distributed RAM size, 64x1S cost 1LUT
   parameter WID_ACTADDR = 6;
   // OPMODE for DSP
   parameter OPMODE = 7'b0010101;  // 7'b0110101 for the start DSP

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
   input wire [WID_ACT-1:0]   act_wr_data;
   input wire [WID_ACTADDR-2:0] act_wr_addr_hbit;
   input wire                   act_wr_en;

   wire [WID_ACT-1:0]           act_rd_data;
   input wire [WID_ACTADDR-2:0] act_rd_addr_hbit;

   
   reg                          act_rd_addr_lbit;
   reg                          act_wr_addr_lbit;
   
   // DSP connection signal
   input wire [48-1:0]          p_casin;
   input wire [48-1:0]          p_sumin;   
   output wire [48-1:0]         p_out;
   output wire [48-1:0]         p_casout;

   always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_rd_wr_addr_lbit
      if(~rst_n) begin
         act_rd_addr_lbit <= 0;
         act_wr_addr_lbit <= 0;
      end else begin
         act_rd_addr_lbit <= ~act_rd_addr_lbit;
         act_wr_addr_lbit <= ~act_wr_addr_lbit;
      end
   end   
   

   // DSP primitive configuration (Note: this is the primitive for UltraScale: DSP48E2)
   DSP48E2 #(
             // Feature Control Attributes: Data Path Selection
             .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
             .A_INPUT("DIRECT"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
             .BMULTSEL("B"),                    // Selects B input to multiplier (AD, B)
             .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
             .PREADDINSEL("A"),                 // Selects input to pre-adder (A, B)
             .RND(48'h000000000000),            // Rounding Constant
             .USE_MULT("MULTIPLY"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
             .USE_SIMD("ONE48"),                // SIMD selection (FOUR12, ONE48, TWO24)
             .USE_WIDEXOR("FALSE"),             // Use the Wide XOR function (FALSE, TRUE)
             .XORSIMD("XOR24_48_96"),           // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
             // Pattern Detector Attributes: Pattern Detection Configuration
             .AUTORESET_PATDET("NO_RESET"),     // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
             .AUTORESET_PRIORITY("RESET"),      // Priority of AUTORESET vs. CEP (CEP, RESET).
             .MASK(48'h3fffffffffff),           // 48-bit mask value for pattern detect (1=ignore)
             .PATTERN(48'h000000000000),        // 48-bit pattern match for pattern detect
             .SEL_MASK("MASK"),                 // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
             .SEL_PATTERN("PATTERN"),           // Select pattern value (C, PATTERN)
             .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
             // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
             .IS_ALUMODE_INVERTED(4'b0000),     // Optional inversion for ALUMODE
             .IS_CARRYIN_INVERTED(1'b0),        // Optional inversion for CARRYIN
             .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
             .IS_INMODE_INVERTED(5'b00000),     // Optional inversion for INMODE
             .IS_OPMODE_INVERTED(9'b000000000), // Optional inversion for OPMODE
             .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
             .IS_RSTALUMODE_INVERTED(1'b0),     // Optional inversion for RSTALUMODE
             .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
             .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
             .IS_RSTCTRL_INVERTED(1'b0),        // Optional inversion for RSTCTRL
             .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
             .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
             .IS_RSTINMODE_INVERTED(1'b0),      // Optional inversion for RSTINMODE
             .IS_RSTM_INVERTED(1'b0),           // Optional inversion for RSTM
             .IS_RSTP_INVERTED(1'b0),           // Optional inversion for RSTP
             // Register Control Attributes: Pipeline Register Configuration
             .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
             .ADREG(1),                         // Pipeline stages for pre-adder (0-1)
             .ALUMODEREG(1),                    // Pipeline stages for ALUMODE (0-1)
             .AREG(2),                          // Pipeline stages for A (0-2)
             .BCASCREG(1),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
             .BREG(1),                          // Pipeline stages for B (0-2)
             .CARRYINREG(1),                    // Pipeline stages for CARRYIN (0-1)
             .CARRYINSELREG(1),                 // Pipeline stages for CARRYINSEL (0-1)
             .CREG(1),                          // Pipeline stages for C (0-1)
             .DREG(1),                          // Pipeline stages for D (0-1)
             .INMODEREG(1),                     // Pipeline stages for INMODE (0-1)
             .MREG(1),                          // Multiplier pipeline stages (0-1)
             .OPMODEREG(1),                     // Pipeline stages for OPMODE (0-1)
             .PREG(1)                           // Number of pipeline stages for P (0-1)
             )
   DSP48E2_inst (
                 // Cascade outputs: Cascade Ports
                 // .ACOUT(ACOUT),                   // 30-bit output: A port cascade
                 // .BCOUT(BCOUT),                   // 18-bit output: B cascade
                 // .CARRYCASCOUT(CARRYCASCOUT),     // 1-bit output: Cascade carry
                 // .MULTSIGNOUT(MULTSIGNOUT),       // 1-bit output: Multiplier sign cascade
                 .PCOUT(p_casout),                   // 48-bit output: Cascade output
                 // Control outputs: Control Inputs/Status Bits
                 // .OVERFLOW(OVERFLOW),             // 1-bit output: Overflow in add/acc
                 // .PATTERNBDETECT(PATTERNBDETECT), // 1-bit output: Pattern bar detect
                 // .PATTERNDETECT(PATTERNDETECT),   // 1-bit output: Pattern detect
                 // .UNDERFLOW(UNDERFLOW),           // 1-bit output: Underflow in add/acc
                 // Data outputs: Data Ports
                 // .CARRYOUT(CARRYOUT),             // 4-bit output: Carry
                 .P(p_out),                           // 48-bit output: Primary data
                 // .XOROUT(XOROUT),                 // 8-bit output: XOR data
                 // Cascade inputs: Cascade Ports
                 // .ACIN(ACIN),                     // 30-bit input: A cascade data
                 // .BCIN(BCIN),                     // 18-bit input: B cascade
                 // .CARRYCASCIN(CARRYCASCIN),       // 1-bit input: Cascade carry
                 // .MULTSIGNIN(MULTSIGNIN),         // 1-bit input: Multiplier sign cascade
                 .PCIN(p_casin),                     // 48-bit input: P cascade
                 // Control inputs: Control Inputs/Status Bits
                 .ALUMODE(4'b0000),               // 4-bit input: ALU control, 4'b0000 represents Z+X+Y
                 // .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select
                 .CLK(clk_h),                       // 1-bit input: Clock
                 .INMODE(4'b0001),                 // 5-bit input: INMODE control, 4'b0001 represents using A1 as A port
                 .OPMODE(OPMODE),                 // 9-bit input: Operation mode
                 // Data inputs: Data Ports
                 .A(w_rd_data),                           // 30-bit input: A data
                 .B(act_rd_data),                           // 18-bit input: B data
                 .C(p_sum_in)                           // 48-bit input: C data
                 // .CARRYIN(CARRYIN),               // 1-bit input: Carry-in
                 // .D(D),                           // 27-bit input: D data
                 // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
                 // .CEA1(CEA1),                     // 1-bit input: Clock enable for 1st stage AREG
                 // .CEA2(CEA2),                     // 1-bit input: Clock enable for 2nd stage AREG
                 // .CEAD(CEAD),                     // 1-bit input: Clock enable for ADREG
                 // .CEALUMODE(CEALUMODE),           // 1-bit input: Clock enable for ALUMODE
                 // .CEB1(CEB1),                     // 1-bit input: Clock enable for 1st stage BREG
                 // .CEB2(CEB2),                     // 1-bit input: Clock enable for 2nd stage BREG
                 // .CEC(CEC),                       // 1-bit input: Clock enable for CREG
                 // .CECARRYIN(CECARRYIN),           // 1-bit input: Clock enable for CARRYINREG
                 // .CECTRL(CECTRL),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
                 // .CED(CED),                       // 1-bit input: Clock enable for DREG
                 // .CEINMODE(CEINMODE),             // 1-bit input: Clock enable for INMODEREG
                 // .CEM(CEM),                       // 1-bit input: Clock enable for MREG
                 // .CEP(CEP),                       // 1-bit input: Clock enable for PREG
                 // .RSTA(RSTA),                     // 1-bit input: Reset for AREG
                 // .RSTALLCARRYIN(RSTALLCARRYIN),   // 1-bit input: Reset for CARRYINREG
                 // .RSTALUMODE(RSTALUMODE),         // 1-bit input: Reset for ALUMODEREG
                 // .RSTB(RSTB),                     // 1-bit input: Reset for BREG
                 // .RSTC(RSTC),                     // 1-bit input: Reset for CREG
                 // .RSTCTRL(RSTCTRL),               // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
                 // .RSTD(RSTD),                     // 1-bit input: Reset for DREG and ADREG
                 // .RSTINMODE(RSTINMODE),           // 1-bit input: Reset for INMODEREG
                 // .RSTM(RSTM),                     // 1-bit input: Reset for MREG
                 // .RSTP(RSTP)                      // 1-bit input: Reset for PREG
                 );
   // End of DSP48E2_inst instantiation


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
                        .D(act_wr_data[ii]),         // Write 1-bit data input
                        .DPRA0(act_rd_addr_lbit), // Read-only address[0] input bit
                        .DPRA1(act_rd_addr_hbit[0]), // Read-only address[1] input bit
                        .DPRA2(act_rd_addr_hbit[1]), // Read-only address[2] input bit
                        .DPRA3(act_rd_addr_hbit[2]), // Read-only address[3] input bit
                        .DPRA4(act_rd_addr_hbit[3]), // Read-only address[4] input bit
                        .DPRA5(act_rd_addr_hbit[4]), // Read-only address[5] input bit
                        .WCLK(clk_h),   // Write clock input
                        .WE(act_wr_en)        // Write enable input
                        );
      end
   endgenerate


   // BRAM for weight buffer
   RAMB18E2 #(
              // CASCADE_ORDER_A, CASCADE_ORDER_B: "FIRST", "MIDDLE", "LAST", "NONE" 
              .CASCADE_ORDER_A("NONE"),
              .CASCADE_ORDER_B("NONE"),
              // CLOCK_DOMAINS: "COMMON", "INDEPENDENT" 
              .CLOCK_DOMAINS("INDEPENDENT"),
              // Collision check: "ALL", "GENERATE_X_ONLY", "NONE", "WARNING_ONLY" 
              .SIM_COLLISION_CHECK("ALL"),
              // DOA_REG, DOB_REG: Optional output register (0, 1)
              .DOA_REG(1),
              .DOB_REG(0),
              // ENADDRENA/ENADDRENB: Address enable pin enable, "TRUE", "FALSE" 
              .ENADDRENA("FALSE"),
              .ENADDRENB("FALSE"),
              // INIT_A, INIT_B: Initial values on output ports
              .INIT_A(18'h00000),
              .INIT_B(18'h00000),
              //TODO: Initialization File: RAM initialization file
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
              .READ_WIDTH_A(2),                                                                 // 0-9
              .READ_WIDTH_B(0),                                                                 // 0-9
              .WRITE_WIDTH_A(0),                                                                // 0-9
              .WRITE_WIDTH_B(2),                                                                // 0-9
              // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
              .RSTREG_PRIORITY_A("RSTREG"),
              .RSTREG_PRIORITY_B("RSTREG"),
              // SRVAL_A, SRVAL_B: Set/reset value for output
              .SRVAL_A(18'h00000),
              .SRVAL_B(18'h00000),
              // Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
              .SLEEP_ASYNC("FALSE"),
              // WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST" 
              .WRITE_MODE_A("NO_CHANGE"),
              .WRITE_MODE_B("NO_CHANGE") 
              )
   RAMB18E2_inst (
                  // Cascade Signals outputs: Multi-BRAM cascade signals
                  // .CASDOUTA(CASDOUTA),               // 16-bit output: Port A cascade output data
                  // .CASDOUTB(CASDOUTB),               // 16-bit output: Port B cascade output data
                  // .CASDOUTPA(CASDOUTPA),             // 2-bit output: Port A cascade output parity data
                  // .CASDOUTPB(CASDOUTPB),             // 2-bit output: Port B cascade output parity data
                  // Port A Data outputs: Port A data
                  .DOUTADOUT(w_rd_data),             // 16-bit output: Port A data/LSB data
                  // .DOUTPADOUTP(DOUTPADOUTP),         // 2-bit output: Port A parity/LSB parity
                  // Port B Data outputs: Port B data
                  // .DOUTBDOUT(DOUTBDOUT),             // 16-bit output: Port B data/MSB data
                  // .DOUTPBDOUTP(DOUTPBDOUTP),         // 2-bit output: Port B parity/MSB parity
                  // Cascade Signals inputs: Multi-BRAM cascade signals
                  // .CASDIMUXA(CASDIMUXA),             // 1-bit input: Port A input data (0=DINA, 1=CASDINA)
                  // .CASDIMUXB(CASDIMUXB),             // 1-bit input: Port B input data (0=DINB, 1=CASDINB)
                  // .CASDINA(CASDINA),                 // 16-bit input: Port A cascade input data
                  // .CASDINB(CASDINB),                 // 16-bit input: Port B cascade input data
                  // .CASDINPA(CASDINPA),               // 2-bit input: Port A cascade input parity data
                  // .CASDINPB(CASDINPB),               // 2-bit input: Port B cascade input parity data
                  // .CASDOMUXA(CASDOMUXA),             // 1-bit input: Port A unregistered data (0=BRAM data, 1=CASDINA)
                  // .CASDOMUXB(CASDOMUXB),             // 1-bit input: Port B unregistered data (0=BRAM data, 1=CASDINB)
                  // .CASDOMUXEN_A(CASDOMUXEN_A),       // 1-bit input: Port A unregistered output data enable
                  // .CASDOMUXEN_B(CASDOMUXEN_B),       // 1-bit input: Port B unregistered output data enable
                  // .CASOREGIMUXA(CASOREGIMUXA),       // 1-bit input: Port A registered data (0=BRAM data, 1=CASDINA)
                  // .CASOREGIMUXB(CASOREGIMUXB),       // 1-bit input: Port B registered data (0=BRAM data, 1=CASDINB)
                  // .CASOREGIMUXEN_A(CASOREGIMUXEN_A), // 1-bit input: Port A registered output data enable
                  // .CASOREGIMUXEN_B(CASOREGIMUXEN_B), // 1-bit input: Port B registered output data enable
                  // Port A Address/Control Signals inputs: Port A address and control signals
                  .ADDRARDADDR(w_rd_addr),         // 14-bit input: A/Read port address
                  .ADDRENA(1'b1),                 // 1-bit input: Active-High A/Read port address enable
                  .CLKARDCLK(clk_l),             // 1-bit input: A/Read port clock
                  .ENARDEN(1'b1),                 // 1-bit input: Port A enable/Read enable
                  .REGCEAREGCE(1'b1),         // 1-bit input: Port A register enable/Register enable
                  // .RSTRAMARSTRAM(RSTRAMARSTRAM),     // 1-bit input: Port A set/reset
                  // .RSTREGARSTREG(RSTREGARSTREG),     // 1-bit input: Port A register set/reset
                  // .WEA(WEA),                         // 2-bit input: Port A write enable
                  // Port A Data inputs: Port A data
                  // .DINADIN(DINADIN),                 // 16-bit input: Port A data/LSB data
                  // .DINPADINP(DINPADINP),             // 2-bit input: Port A parity/LSB parity
                  // Port B Address/Control Signals inputs: Port B address and control signals
                  .ADDRBWRADDR(w_wr_addr),         // 14-bit input: B/Write port address
                  .ADDRENB(1'b1),                 // 1-bit input: Active-High B/Write port address enable
                  .CLKBWRCLK(clk_l),             // 1-bit input: B/Write port clock
                  .ENBWREN(1'b1),                 // 1-bit input: Port B enable/Write enable
                  // .REGCEB(REGCEB),                   // 1-bit input: Port B register enable
                  // .RSTRAMB(RSTRAMB),                 // 1-bit input: Port B set/reset
                  // .RSTREGB(RSTREGB),                 // 1-bit input: Port B register set/reset
                  // .SLEEP(SLEEP),                     // 1-bit input: Sleep Mode
                  .WEBWE(w_wr_en),                     // 4-bit input: Port B write enable/Write enable
                  // Port B Data inputs: Port B data
                  .DINBDIN(w_wr_data)                 // 16-bit input: Port B data/MSB data
                  // .DINPBDINP(DINPBDINP)              // 2-bit input: Port B parity/MSB parity
                  );
   // End of RAMB18E2_inst instantiation

endmodule

