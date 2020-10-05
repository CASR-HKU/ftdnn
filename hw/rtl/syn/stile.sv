// SuperTile
`timescale 1ns / 1ns
`include "ftdl_conf.vh"

module stile(/*AUTOARG*/
    // Outputs
    psum_out, psum_casout,
    // Inputs
    clk_h, clk_l, rst_n, wbuf_wr_en, wbuf_wr_addr, wbuf_wr_data, wbuf_rd_addr,
    actbuf_wr_en, actbuf_wr_addrh, actbuf_wr_data, actbuf_rd_addrh,
    psum_in, psum_casin
);
parameter POS_D3=0;
parameter POS_D2=0;
parameter POS_D1=0;
// OPMODE for DSP
parameter OPMODE = 7'b0010101;  // 7'b0110101 for the start NOTE: for DSPE2 in UltraScale, should use 8bit 8'bx0010101
// 1: TPE index is odd;   0: TPE index is even
localparam ODD_INDEX_TPE = POS_D1%2;
// initialize wbuf, for behavioral sim use only
// localparam with $sformatf() may cause error
parameter WBUF_FILE=$sformatf("wbuf_%0d_%0d_%0d.mem",POS_D3,POS_D2,POS_D1);
// parameter WBUF_FILE="wbuf_0_0_0.mem";
// parameter WBUF_FILE="NONE";

input wire                                     clk_h;
input wire                                     clk_l;
input wire                                     rst_n;

//FIXME: to BRAM, weight buffer wr signal, not used currently
input wire                                     wbuf_wr_en;
input wire     [`WBUF_ADDR_LEN-1:0]            wbuf_wr_addr;
input wire     [`WBUF_DATA_LEN-1:0]            wbuf_wr_data;

input wire     [`WBUF_ADDR_LEN-1:0]            wbuf_rd_addr;
wire           [`WBUF_DATA_LEN-1:0]            wbuf_rd_data;
reg            [`WBUF_DATA_LEN-1:0]            wbuf_rd_data_d0;
reg            [`WBUF_DATA_LEN-1:0]            wbuf_rd_data_d1;

// to DisRAM, act buffer wr signal
input wire                                     actbuf_wr_en;
input wire     [`ACTBUF_ADDR_LEN-2:0]          actbuf_wr_addrh;
reg                                            actbuf_wr_addrl;
input wire     [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data;

input wire     [`ACTBUF_ADDR_LEN-2:0]          actbuf_rd_addrh;
reg                                            actbuf_rd_addrl;
wire           [`ACTBUF_DATA_LEN-1:0]          actbuf_rd_data;
reg            [`ACTBUF_DATA_LEN-1:0]          actbuf_rd_data_d0;
reg            [`ACTBUF_DATA_LEN-1:0]          actbuf_rd_data_d1;


// DSP connection signal
wire           [29:0]                          dsp_a_in;
wire           [17:0]                          dsp_b_in;
input wire     [48-1:0]                        psum_in;
input wire     [48-1:0]                        psum_casin;
output wire    [48-1:0]                        psum_casout;
output wire    [48-1:0]                        psum_out;


// process actbuf_rd_data delay
generate
    // for even index TPE
    if (ODD_INDEX_TPE==0) begin
        // 0 cycle delay for actbuf_rd_data
        // always_ff @(posedge clk_h or negedge rst_n) begin
        //     if(~rst_n) begin
        //         actbuf_rd_data_d0 <= 0;
        //     end else begin
        //         actbuf_rd_data_d0 <= actbuf_rd_data;
        //     end
        // end
        // assign dsp input with actbuf_rd_data_d0
        assign dsp_b_in = {{(18-`ACTBUF_DATA_LEN){1'b0}}, actbuf_rd_data};
    end
    else begin
        // 1 cycle delay for actbuf_rd_data
        always_ff @(posedge clk_h or negedge rst_n) begin
            if(~rst_n) begin
                actbuf_rd_data_d0 <= 0;
                actbuf_rd_data_d1 <= 0;
            end else begin
                actbuf_rd_data_d0 <= actbuf_rd_data;
                actbuf_rd_data_d1 <= actbuf_rd_data_d0;
            end
        end
        // assign dsp input with actbuf_rd_data_d1
        assign dsp_b_in = {{(18-`ACTBUF_DATA_LEN){1'b0}}, actbuf_rd_data_d0};
    end
endgenerate

// process wbuf_rd_data delay
generate
    // for even index TPE
    if (ODD_INDEX_TPE==0) begin
        // 0 cycle delay for wbuf_rd_data
        // assign dsp input with wbuf_rd_data
        assign dsp_a_in = {{(30-`WBUF_DATA_LEN){1'b0}}, wbuf_rd_data};
    end
    else begin
        // 1 cycle delay for wbuf_rd_data
        always_ff @(posedge clk_h or negedge rst_n) begin
            if(~rst_n) begin
                wbuf_rd_data_d0 <= 0;
                wbuf_rd_data_d1 <= 0;
            end else begin
                wbuf_rd_data_d0 <= wbuf_rd_data;
                wbuf_rd_data_d1 <= wbuf_rd_data_d0;
            end
        end
        // assign dsp input with wbuf_rd_data_d1
        assign dsp_a_in = {{(30-`WBUF_DATA_LEN){1'b0}}, wbuf_rd_data_d0};
    end
endgenerate

// process act_addrl to fit clk_h
always_ff @(posedge clk_h or negedge rst_n) begin : proc_act_addrl
  if(~rst_n) begin
    // init as 1, then 0 comes first
    actbuf_rd_addrl <= 1;
    actbuf_wr_addrl <= 1;
end else begin
    actbuf_rd_addrl <= ~actbuf_rd_addrl;
    actbuf_wr_addrl <= ~actbuf_wr_addrl;
end
end


wire [`ACTBUF_DATA_LEN-1:0] actbuf_wr_data_clkh;
assign actbuf_wr_data_clkh = actbuf_wr_addrl? actbuf_wr_data[`ACTBUF_DATA_LEN+:`ACTBUF_DATA_LEN] : actbuf_wr_data[0+:`ACTBUF_DATA_LEN];

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
  .AREG(1),                          // Pipeline stages for A (0-2)
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
  .PCOUT(psum_casout),                   // 48-bit output: Cascade output
  // Control outputs: Control Inputs/Status Bits
  // .OVERFLOW(OVERFLOW),             // 1-bit output: Overflow in add/acc
  // .PATTERNBDETECT(PATTERNBDETECT), // 1-bit output: Pattern bar detect
  // .PATTERNDETECT(PATTERNDETECT),   // 1-bit output: Pattern detect
  // .UNDERFLOW(UNDERFLOW),           // 1-bit output: Underflow in add/acc
  // Data outputs: Data Ports
  // .CARRYOUT(CARRYOUT),             // 4-bit output: Carry
  .P(psum_out),                           // 48-bit output: Primary data
  // .XOROUT(XOROUT),                 // 8-bit output: XOR data
  // Cascade inputs: Cascade Ports
  // .ACIN(ACIN),                     // 30-bit input: A cascade data
  // .BCIN(BCIN),                     // 18-bit input: B cascade
  // .CARRYCASCIN(CARRYCASCIN),       // 1-bit input: Cascade carry
  // .MULTSIGNIN(MULTSIGNIN),         // 1-bit input: Multiplier sign cascade
  .PCIN(psum_casin),                     // 48-bit input: P cascade
  // Control inputs: Control Inputs/Status Bits
  .ALUMODE(4'b0000),               // 4-bit input: ALU control, 4'b0000 represents Z+X+Y
  // .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select
  .CLK(clk_h),                       // 1-bit input: Clock
  .INMODE(4'b0001),                 // 5-bit input: INMODE control, 4'b0001 represents using A1 as A port
  .OPMODE(OPMODE),                 // 9-bit input: Operation mode
  // Data inputs: Data Ports
  .A(dsp_a_in),                           // 30-bit input: A data
  .B(dsp_b_in),                           // 18-bit input: B data
  .C(psum_in),                           // 48-bit input: C data
  // .CARRYIN(CARRYIN),               // 1-bit input: Carry-in
  // .D(D),                           // 27-bit input: D data
  // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
  .CEA1(1'b1),                     // 1-bit input: Clock enable for 1st stage AREG
  .CEA2(1'b1),                     // 1-bit input: Clock enable for 2nd stage AREG
  .CEAD(1'b1),                     // 1-bit input: Clock enable for ADREG
  .CEALUMODE(1'b1),           // 1-bit input: Clock enable for ALUMODE
  .CEB1(1'b1),                     // 1-bit input: Clock enable for 1st stage BREG
  .CEB2(1'b1),                     // 1-bit input: Clock enable for 2nd stage BREG
  .CEC(1'b1),                       // 1-bit input: Clock enable for CREG
  .CECARRYIN(1'b1),           // 1-bit input: Clock enable for CARRYINREG
  .CECTRL(1'b1),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
  .CED(1'b1),                       // 1-bit input: Clock enable for DREG
  .CEINMODE(1'b1),             // 1-bit input: Clock enable for INMODEREG
  .CEM(1'b1),                       // 1-bit input: Clock enable for MREG
  .CEP(1'b1),                       // 1-bit input: Clock enable for PREG
  .RSTA(~rst_n),                     // 1-bit input: Reset for AREG
  .RSTALLCARRYIN(~rst_n),   // 1-bit input: Reset for CARRYINREG
  .RSTALUMODE(~rst_n),         // 1-bit input: Reset for ALUMODEREG
  .RSTB(~rst_n),                     // 1-bit input: Reset for BREG
  .RSTC(~rst_n),                     // 1-bit input: Reset for CREG
  .RSTCTRL(~rst_n),               // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
  .RSTD(~rst_n),                     // 1-bit input: Reset for DREG and ADREG
  .RSTINMODE(~rst_n),           // 1-bit input: Reset for INMODEREG
  .RSTM(~rst_n),                     // 1-bit input: Reset for MREG
  .RSTP(~rst_n)                      // 1-bit input: Reset for PREG
  );
// End of DSP48E2_inst instantiation




genvar ii;
// generate DisRAM array for act buffer
generate
  for (ii=0; ii<`ACTBUF_DATA_LEN; ii=ii+1) begin
    RAM128X1D #(
      .INIT(64'h0000000000000000)       // Initial contents of RAM
      )
    RAM128X1D_inst (
      .DPO(actbuf_rd_data[ii]),            // Read-only 1-bit data output
      // .SPO(SPO),                  // Rw/ 1-bit data output
      .A({actbuf_wr_addrh, actbuf_wr_addrl}),      // Read/write port 7-bit address input
      .D(actbuf_wr_data_clkh[ii]),         // Write 1-bit data input
      .DPRA({actbuf_rd_addrh, actbuf_rd_addrl}),   // Read port 7-bit address input
      .WCLK(clk_h),                     // Write clock input
      .WE(actbuf_wr_en)                    // Write enable input
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
  // .DOB_REG(1),
  // ENADDRENA/ENADDRENB: Address enable pin enable, "TRUE", "FALSE" 
  .ENADDRENA("FALSE"),
  .ENADDRENB("FALSE"),
  // INIT_A, INIT_B: Initial values on output ports
  .INIT_A(18'h00000),
  .INIT_B(18'h00000),
  // Initialization File: RAM initialization file
  // .INIT_FILE("wbuf_0_0_0.mem"),
  .INIT_FILE(WBUF_FILE),
  // .INIT_00(256'h000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f),
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
  .READ_WIDTH_A(18),                                                                 // 0-9
  .READ_WIDTH_B(0),                                                                 // 0-9
  .WRITE_WIDTH_A(0),                                                                // 0-9
  .WRITE_WIDTH_B(0),                                                                // 0-9
  // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
  .RSTREG_PRIORITY_A("RSTREG"),
  .RSTREG_PRIORITY_B("RSTREG"),
  // SRVAL_A, SRVAL_B: Set/reset value for output
  .SRVAL_A(18'h00000),
  .SRVAL_B(18'h00000),
  // Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
  .SLEEP_ASYNC("FALSE"),
  // WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST" 
  .WRITE_MODE_A("READ_FIRST"),
  .WRITE_MODE_B("READ_FIRST") 
  )
RAMB18E2_inst (
  // Cascade Signals outputs: Multi-BRAM cascade signals
  // .CASDOUTA(CASDOUTA),               // 16-bit output: Port A cascade output data
  // .CASDOUTB(CASDOUTB),               // 16-bit output: Port B cascade output data
  // .CASDOUTPA(CASDOUTPA),             // 2-bit output: Port A cascade output parity data
  // .CASDOUTPB(CASDOUTPB),             // 2-bit output: Port B cascade output parity data
  // Port A Data outputs: Port A data
  .DOUTADOUT(wbuf_rd_data),             // 16-bit output: Port A data/LSB data
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
  .ADDRARDADDR({wbuf_rd_addr, {(14-`WBUF_ADDR_LEN){1'b0}}}),         // 14-bit input: A/Read port address
  .ADDRENA(1'b1),                 // 1-bit input: Active-High A/Read port address enable
  .CLKARDCLK(clk_l),             // 1-bit input: A/Read port clock
  .ENARDEN(1'b1),                 // 1-bit input: Port A enable/Read enable
  .REGCEAREGCE(1'b1),         // 1-bit input: Port A register enable/Register enable
  .RSTRAMARSTRAM(~rst_n),     // 1-bit input: Port A set/reset
  .RSTREGARSTREG(~rst_n),     // 1-bit input: Port A register set/reset
  .WEA(2'b00)                         // 2-bit input: Port A write enable
  // Port A Data inputs: Port A data
  // .DINADIN(DINADIN),                 // 16-bit input: Port A data/LSB data
  // .DINPADINP(DINPADINP),             // 2-bit input: Port A parity/LSB parity
  // Port B Address/Control Signals inputs: Port B address and control signals
  // .ADDRBWRADDR(ADDRBWRADDR),         // 14-bit input: B/Write port address
  // .ADDRENB(ADDRENB),                 // 1-bit input: Active-High B/Write port address enable
  // .CLKBWRCLK(CLKBWRCLK),             // 1-bit input: B/Write port clock
  // .ENBWREN(ENBWREN),                 // 1-bit input: Port B enable/Write enable
  // .REGCEB(REGCEB),                   // 1-bit input: Port B register enable
  // .RSTRAMB(RSTRAMB),                 // 1-bit input: Port B set/reset
  // .RSTREGB(RSTREGB),                 // 1-bit input: Port B register set/reset
  // .SLEEP(SLEEP),                     // 1-bit input: Sleep Mode
  // .WEBWE(WEBWE),                     // 4-bit input: Port B write enable/Write enable
  // Port B Data inputs: Port B data
  // .DINBDIN(DINBDIN),                 // 16-bit input: Port B data/MSB data
  // .DINPBDINP(DINPBDINP)              // 2-bit input: Port B parity/MSB parity
  );
// End of RAMB18E2_inst instantiation

endmodule

