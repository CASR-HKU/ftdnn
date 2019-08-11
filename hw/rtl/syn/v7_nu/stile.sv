// SuperTile

module stile(/*AUTOARG*/
   // Outputs
   p_out,
   // Inputs
   clk_h, clk_l, rst_n, w_wr_data, w_wr_addr, w_wr_en, act_wr_data,
   act_wr_addr, act_wr_en, p_casin, p_sumin
   );

   parameter W_BIT = 16;
   // each BRAM18 can be configured to a shape of 16x1024
   parameter WADDR_BIT = 10;
   parameter ACT_BIT = 16;
   // TODO: Distributed RAM size, 64x1S cost 1LUT
   parameter ACTADDR_BIT = 6;
   // OPMODE for DSP
   parameter OPMODE = 7'b0010101;  // 7'b0110101 for the start DSP

   input wire clk_h;
   input wire clk_l;

   input wire rst_n;
   
   // to BRAM, weight buffer wr signal
   input wire [W_BIT-1:0] w_wr_data;
   input wire [WADDR_BIT-1:0] w_wr_addr;
   input wire                 w_wr_en;

   wire [W_BIT-1:0]           w_rd_data;
   // FIXME
   reg [WADDR_BIT-1:0]        w_rd_addr;

   // to DisRAM, act buffer wr signal
   input wire [ACT_BIT-1:0]   act_wr_data;
   input wire [ACTADDR_BIT-1:0] act_wr_addr;
   input wire                   act_wr_en;

   wire [ACT_BIT-1:0]           act_rd_data;
   // FIXME
   reg [ACTADDR_BIT-1:0]        act_rd_aadr;
   

   // DSP connection signal
   input wire [48-1:0]          p_casin;
   input wire [48-1:0]          p_sumin;   
   output wire [48-1:0]         p_out;
   // output wire [48-1:0]         p_casout;
   wire [48-1:0]                p_casout;
   
   // DSP primitive configuration (Note: this is the primitive for Virtex-7)
   DSP48E1 #(
             // Feature Control Attributes: Data Path Selection
             .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
             .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
             .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
             .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
             .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
             // Register Control Attributes: Pipeline Register Configuration
             // .ACASCREG(1),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
             // .ADREG(1),                        // Number of pipeline stages for pre-adder (0 or 1)
             .ALUMODEREG(1),                   // Number of pipeline stages for ALUMODE (0 or 1)
             .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
             // .BCASCREG(1),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
             .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
             // .CARRYINREG(1),                   // Number of pipeline stages for CARRYIN (0 or 1)
             // .CARRYINSELREG(1),                // Number of pipeline stages for CARRYINSEL (0 or 1)
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
                 .ALUMODE(4'b0000),               // 4-bit input: ALU control input, 4'b0000 represents Z+X+Y
                 // .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select input
                 .CLK(clk_h),                       // 1-bit input: Clock input
                 .INMODE(4'b0001),                 // 5-bit input: INMODE control input, 4'b0001 represents using A1 as A port
                 .OPMODE(OPMODE),                 // 7-bit input: Operation mode input
                 // Data: 30-bit (each) input: Data Ports
                 .A(w_rd_data),                           // 30-bit input: A data input, operand A
                 .B(act_rd_data),                           // 18-bit input: B data input, operand B
                 .C(p_sum_in)                           // 48-bit input: C data input, load for psum outside
                 // .CARRYIN(CARRYIN),               // 1-bit input: Carry input signal
                 // .D(D),                           // 25-bit input: D data input
                 // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
                 // .CEA1(CEA1),                     // 1-bit input: Clock enable input for 1st stage AREG
                 // .CEA2(CEA2),                     // 1-bit input: Clock enable input for 2nd stage AREG
                 // .CEAD(CEAD),                     // 1-bit input: Clock enable input for ADREG
                 // .CEALUMODE(CEALUMODE),           // 1-bit input: Clock enable input for ALUMODE
                 // .CEB1(CEB1),                     // 1-bit input: Clock enable input for 1st stage BREG
                 // .CEB2(CEB2),                     // 1-bit input: Clock enable input for 2nd stage BREG
                 // .CEC(CEC),                       // 1-bit input: Clock enable input for CREG
                 // .CECARRYIN(CECARRYIN),           // 1-bit input: Clock enable input for CARRYINREG
                 // .CECTRL(CECTRL),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
                 // .CED(CED),                       // 1-bit input: Clock enable input for DREG
                 // .CEINMODE(CEINMODE),             // 1-bit input: Clock enable input for INMODEREG
                 // .CEM(CEM),                       // 1-bit input: Clock enable input for MREG
                 // .CEP(CEP),                       // 1-bit input: Clock enable input for PREG
                 // .RSTA(RSTA),                     // 1-bit input: Reset input for AREG
                 // .RSTALLCARRYIN(RSTALLCARRYIN),   // 1-bit input: Reset input for CARRYINREG
                 // .RSTALUMODE(RSTALUMODE),         // 1-bit input: Reset input for ALUMODEREG
                 // .RSTB(RSTB),                     // 1-bit input: Reset input for BREG
                 // .RSTC(RSTC),                     // 1-bit input: Reset input for CREG
                 // .RSTCTRL(RSTCTRL),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
                 // .RSTD(RSTD),                     // 1-bit input: Reset input for DREG and ADREG
                 // .RSTINMODE(RSTINMODE),           // 1-bit input: Reset input for INMODEREG
                 // .RSTM(RSTM),                     // 1-bit input: Reset input for MREG
                 // .RSTP(RSTP)                      // 1-bit input: Reset input for PREG
                 );

   genvar                       ii;
   // generate DisRAM array for act buffer
   generate
      for (ii=0; ii<ACT_BIT; ii=ii+1) begin
         RAM64X1D #(
                    .INIT(64'h0000000000000000) // Initial contents of RAM
                    )
         RAM64X1D_inst (
                        .DPO(act_rd_data[ii]),     // Read-only 1-bit data output
                        // .SPO(SPO),     // Rw/ 1-bit data output
                        .A0(act_wr_addr[0]),       // Rw/ address[0] input bit
                        .A1(act_wr_addr[1]),       // Rw/ address[1] input bit
                        .A2(act_wr_addr[2]),       // Rw/ address[2] input bit
                        .A3(act_wr_addr[3]),       // Rw/ address[3] input bit
                        .A4(act_wr_addr[4]),       // Rw/ address[4] input bit
                        .A5(act_wr_addr[5]),       // Rw/ address[5] input bit
                        .D(act_wr_data[ii]),         // Write 1-bit data input
                        .DPRA0(act_rd_aadr[0]), // Read-only address[0] input bit
                        .DPRA1(act_rd_aadr[1]), // Read-only address[1] input bit
                        .DPRA2(act_rd_aadr[2]), // Read-only address[2] input bit
                        .DPRA3(act_rd_aadr[3]), // Read-only address[3] input bit
                        .DPRA4(act_rd_aadr[4]), // Read-only address[4] input bit
                        .DPRA5(act_rd_aadr[5]), // Read-only address[5] input bit
                        .WCLK(clk_h),   // Write clock input
                        .WE(act_wr_en)        // Write enable input
                        );
      end
   endgenerate

   // BRAM for weight buffer
   BRAM_SDP_MACRO #(
                    .BRAM_SIZE("18Kb"), // Target BRAM, "18Kb" or "36Kb" 
                    .DEVICE("7SERIES"), // Target device: "7SERIES" 
                    .WRITE_WIDTH(16),    // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
                    .READ_WIDTH(16),     // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
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
                        .DO(w_rd_data),         // Output read data port, width defined by READ_WIDTH parameter
                        .DI(w_wr_data),         // Input write data port, width defined by WRITE_WIDTH parameter
                        .RDADDR(w_rd_addr), // Input read address, width defined by read port depth
                        .RDCLK(clk_l),   // 1-bit input read clock
                        .RDEN(1),     // 1-bit input read port enable
                        .REGCE(1),   // 1-bit input read output register enable
                        .RST(~rst_n),       // 1-bit input reset      
                        .WE(w_wr_en),         // Input write enable, width defined by write port depth
                        .WRADDR(w_wr_addr), // Input write address, width defined by write port depth
                        .WRCLK(clk_l),   // 1-bit input write clock
                        .WREN(1'b1)      // 1-bit input write port enable
                        );

   // FIXME: DisRAM addr generator
   always @(posedge clk_h or negedge rst_n) begin : proc_disram_addr
      if(~rst_n) begin
         act_rd_aadr <= 0;
      end else begin
         act_rd_aadr <= act_rd_aadr + 1;
      end
   end

   // BRAM addr generator
   always @(posedge clk_l or negedge rst_n) begin: proc_bram_addr
      if(~rst_n) begin
         w_rd_addr <= 0;
      end else begin
         w_rd_addr <= w_rd_addr + 1;
      end
   end
   
endmodule // stile
