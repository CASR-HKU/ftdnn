// Behavior of SuperBlock Unit (units in horizontal compose the SuperBlock)
`timescale 1ns / 1ns
`include "ftdl_conf.vh"

module sblk_unit(
    // Outputs
    pbuf_rd_data,
    // Inputs
    clk_h, clk_l, rst_n, actbuf_wr_data, actbuf_wr_en, actbuf_wr_addrh,
    actbuf_rd_addrh, wbuf_rd_addr, pbuf_wr_addr, pbuf_wr_en,
    pbuf_rd_addr
);
parameter POS_D3=0;
parameter POS_D2=0;

input wire                                     clk_h;
input wire                                     clk_l;
input wire                                     rst_n;

// signals from controller, NOTE: may change for MV / CONV, etc. 

input wire     [`WBUF_ADDR_LEN-1:0]            wbuf_rd_addr;

input wire     [`HW_D1-1:0]                    actbuf_wr_en;
input wire     [`ACTBUF_ADDRH_LEN-1:0]         actbuf_wr_addrh;
input wire     [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data;

input wire     [`ACTBUF_ADDRH_LEN-1:0]         actbuf_rd_addrh;

input wire                                     pbuf_wr_en;
input wire     [`PBUF_ADDR_LEN-1:0]            pbuf_wr_addr;
reg            [`PBUF_DATA_LEN-1:0]            pbuf_wr_data;

input wire     [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr;
output wire    [`PBUF_DATA_LEN-1:0]            pbuf_rd_data;

// tmp wire for psum of each DSP
wire           [`PSUM_DATA_LEN-1:0]            psum_in;
wire           [48-1:0]                        psum_tmp[`HW_D1-2:0];
wire           [`PSUM_DATA_LEN-1:0]            psum_out;
reg            [`PSUM_DATA_LEN-1:0]            psum_out_d;

// dealy of actbuf_in
reg            [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data_d;

always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_wr_data
    if(~rst_n) begin
        actbuf_wr_data_d <= 0;
    end else begin
        actbuf_wr_data_d <= actbuf_wr_data;
    end
end

always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_out_d
    if(~rst_n) begin
        psum_out_d <= 0;
    end else begin
        psum_out_d <= psum_out;
    end
end

always_ff @(posedge clk_l or negedge rst_n) begin : proc_pbuf_wr_data
    if(~rst_n) begin
        pbuf_wr_data <= 0;
    end else begin
        pbuf_wr_data <= {psum_out, psum_out_d};
    end
end

reg clkh_toggle;
always_ff @(posedge clk_h or negedge rst_n) begin : proc_clkh_toggle
    if(~rst_n) begin
        clkh_toggle <= 1;
    end else begin
        clkh_toggle <= ~clkh_toggle;
    end
end


reg [`PSUM_DATA_LEN-1:0]       proc_psum_in_d0;
assign psum_in = clkh_toggle? pbuf_rd_data[`PSUM_DATA_LEN+:`PSUM_DATA_LEN] : pbuf_rd_data[0+:`PSUM_DATA_LEN];

always_ff @(posedge clk_h or negedge rst_n) begin : proc_psum_in_d
    if(~rst_n) begin
        proc_psum_in_d0 <= 0;
    end else begin
        proc_psum_in_d0 <= psum_in;
    end
end

// delay the actbuf_rd_addrh
// tpe[2*jj] and tpe[2*jj+1] share actbuf_rd_addrh_d[jj]
localparam ACTBUF_RD_ADDRH_BASE = 2;
localparam ACTBUF_RD_ADDRH_DELAY = ACTBUF_RD_ADDRH_BASE + `HW_D1/2;
reg [`ACTBUF_ADDRH_LEN-1:0] actbuf_rd_addrh_d[ACTBUF_RD_ADDRH_DELAY];

always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_rd_addrh_d
    if(~rst_n) begin
        for (int jj=0; jj<ACTBUF_RD_ADDRH_DELAY; jj=jj+1) begin
            actbuf_rd_addrh_d[jj] <= 0;
        end
    end else begin
        actbuf_rd_addrh_d[0] <= actbuf_rd_addrh;
        for (int jj=1; jj<ACTBUF_RD_ADDRH_DELAY; jj=jj+1) begin
            actbuf_rd_addrh_d[jj] <= actbuf_rd_addrh_d[jj-1];
        end
    end
end

// delay the wbuf_rd_addr
// tpe[2*jj] and tpe[2*jj+1] share wbuf_rd_addr_d[jj]
localparam W_RD_ADDR_DELAY=`HW_D1/2;
reg [`WBUF_ADDR_LEN-1:0] wbuf_rd_addr_d[W_RD_ADDR_DELAY];
always_ff @(posedge clk_l or negedge rst_n) begin : proc_wbuf_rd_addr_d
    if(~rst_n) begin
        for (int jj=0; jj<W_RD_ADDR_DELAY; jj=jj+1) begin
            wbuf_rd_addr_d[jj] <= 0;
    end
    end else begin
        wbuf_rd_addr_d[0] <= wbuf_rd_addr;
        for (int jj = 1; jj < W_RD_ADDR_DELAY; jj=jj+1) begin
            wbuf_rd_addr_d[jj] <= wbuf_rd_addr_d[jj-1];
        end
    end
end
// delay the pbuf_rd_addr
reg [`PBUF_ADDR_LEN-1:0] pbuf_rd_addr_d[2];
always_ff @(posedge clk_l or negedge rst_n) begin : proc_pbuf_rd_addr_d
    if(~rst_n) begin
        for (int jj=0; jj<2; jj=jj+1) begin
            pbuf_rd_addr_d[jj] <= 0;
    end
    end else begin
        pbuf_rd_addr_d[0] <= pbuf_rd_addr;
        for (int jj = 1; jj < 2; jj=jj+1) begin
            pbuf_rd_addr_d[jj] <= pbuf_rd_addr_d[jj-1];
        end
    end
end

// generate HW_D1 stile
generate
    for (genvar hw_d1 = 0; hw_d1 < `HW_D1; hw_d1=hw_d1+1) begin: tpe
        // first TPE
        if (hw_d1==0) begin: u
            stile #(
                .POS_D3(POS_D3),
                .POS_D2(POS_D2),
                .POS_D1(hw_d1),
                .OPMODE(7'b0110101)
                )
            stile_inst(
                .clk_h(clk_h),
                .clk_l(clk_l),
                .rst_n(rst_n),
                .wbuf_wr_en(1'b0)  ,
                .wbuf_rd_addr(wbuf_rd_addr_d[hw_d1/2]),
                .actbuf_wr_en(actbuf_wr_en[hw_d1]),
                .actbuf_wr_addrh(actbuf_wr_addrh),
                .actbuf_wr_data(actbuf_wr_data),
                .actbuf_rd_addrh(actbuf_rd_addrh_d[ACTBUF_RD_ADDRH_BASE+hw_d1/2]),
                .psum_in({{(48-`PSUM_DATA_LEN){1'b0}}, proc_psum_in_d0}),
                .psum_casout(psum_tmp[hw_d1])
                );
        end
        // TPE in the mid
        else if (hw_d1!=`HW_D1-1) begin: u
            stile #(
                .POS_D3(POS_D3),
                .POS_D2(POS_D2),
                .POS_D1(hw_d1)
                )
            stile_inst(
                .clk_h(clk_h),
                .clk_l(clk_l),
                .rst_n(rst_n),
                .wbuf_wr_en(1'b0)  ,
                .wbuf_rd_addr(wbuf_rd_addr_d[hw_d1/2]),
                .actbuf_wr_en(actbuf_wr_en[hw_d1]),
                .actbuf_wr_addrh(actbuf_wr_addrh),
                .actbuf_wr_data(actbuf_wr_data),
                .actbuf_rd_addrh(actbuf_rd_addrh_d[ACTBUF_RD_ADDRH_BASE+hw_d1/2]),
                .psum_casin(psum_tmp[hw_d1-1]),
                .psum_casout(psum_tmp[hw_d1])
                );
        end
        // last TPE
        else begin: u
            stile #(
                .POS_D3(POS_D3),
                .POS_D2(POS_D2),
                .POS_D1(hw_d1)
                )
            stile_inst(
                .clk_h(clk_h),
                .clk_l(clk_l),
                .rst_n(rst_n),
                .wbuf_wr_en(1'b0)  ,
                .wbuf_rd_addr(wbuf_rd_addr_d[hw_d1/2]),
                .actbuf_wr_en(actbuf_wr_en[hw_d1]),
                .actbuf_wr_addrh(actbuf_wr_addrh),
                .actbuf_wr_data(actbuf_wr_data),
                .actbuf_rd_addrh(actbuf_rd_addrh_d[ACTBUF_RD_ADDRH_BASE+hw_d1/2]),
                .psum_casin(psum_tmp[hw_d1-1]),
                .psum_out(psum_out)
                );
        end
    end
endgenerate

// instante partial sum buffer
RAMB36E2 #(
    // CASCADE_ORDER_A, CASCADE_ORDER_B: "FIRST", "MIDDLE", "LAST", "NONE" 
    .CASCADE_ORDER_A("NONE"),
    .CASCADE_ORDER_B("NONE"),
    // CLOCK_DOMAINS: "COMMON", "INDEPENDENT" 
    .CLOCK_DOMAINS("INDEPENDENT"),
    // Collision check: "ALL", "GENERATE_X_ONLY", "NONE", "WARNING_ONLY" 
    .SIM_COLLISION_CHECK("ALL"),
    // DOA_REG, DOB_REG: Optional output register (0, 1)
    .DOA_REG(1),
    .DOB_REG(1),
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
    // .INIT_FILE("/home/rbshi/workspace/nnarch/ftdnn/hw/rtl/tb/zero_init.mif"),
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
    .READ_WIDTH_A(72),                                                                 // 0-9
    // .READ_WIDTH_B(36),                                                                 // 0-9
    // .WRITE_WIDTH_A(36),                                                                // 0-9
    .WRITE_WIDTH_B(72),                                                                // 0-9
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
    .DOUTADOUT(pbuf_rd_data[0+:`PSUM_DATA_LEN]),             // 32-bit output: Port A ata/LSB data
    // .DOUTPADOUTP(DOUTPADOUTP),         // 4-bit output: Port A parity/LSB parity
    // Port B Data outputs: Port B data
    .DOUTBDOUT(pbuf_rd_data[`PSUM_DATA_LEN+:`PSUM_DATA_LEN]),             // 32-bit output: Port B data/MSB data
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
    .ADDRARDADDR({pbuf_rd_addr_d[0], {(15- `PBUF_ADDR_LEN){1'b0}}}),         // 15-bit input: A/Read port address
    .ADDRENA(1'b1),                 // 1-bit input: Active-High A/Read port address enable
    .CLKARDCLK(clk_l),             // 1-bit input: A/Read port clock
    .ENARDEN(1'b1),                 // 1-bit input: Port A enable/Read enable
    // .REGCEAREGCE(REGCEAREGCE),         // 1-bit input: Port A register enable/Register enable
    .RSTRAMARSTRAM(~rst_n),     // 1-bit input: Port A set/reset
    .RSTREGARSTREG(~rst_n),     // 1-bit input: Port A register set/reset
    // .SLEEP(SLEEP),                     // 1-bit input: Sleep Mode
    // .WEA(WEA),                         // 4-bit input: Port A write enable
    // Port A Data inputs: Port A data
    .DINADIN(pbuf_wr_data[0+:`PSUM_DATA_LEN]),                 // 32-bit input: Port A data/LSB data
    // .DINPADINP(DINPADINP),             // 4-bit input: Port A parity/LSB parity
    // Port B Address/Control Signals inputs: Port B address and control signals
    .ADDRBWRADDR({pbuf_wr_addr, {(15- `PBUF_ADDR_LEN){1'b0}}}),         // 15-bit input: B/Write port address
    .ADDRENB(1'b1),                 // 1-bit input: Active-High B/Write port address enable
    .CLKBWRCLK(clk_l),             // 1-bit input: B/Write port clock
    .ENBWREN(1'b1),                 // 1-bit input: Port B enable/Write enable
    // .REGCEB(REGCEB),                   // 1-bit input: Port B register enable
    .RSTRAMB(~rst_n),                 // 1-bit input: Port B set/reset
    .RSTREGB(~rst_n),                 // 1-bit input: Port B register set/reset
    .WEBWE({8{pbuf_wr_en}}),                     // 8-bit input: Port B write enable/Write enable
    // Port B Data inputs: Port B data
    .DINBDIN(pbuf_wr_data[`PSUM_DATA_LEN+:`PSUM_DATA_LEN])                // 32-bit input: Port B data/MSB data
    // .DINPBDINP(DINPBDINP)              // 4-bit input: Port B parity/MSB parity
    );
endmodule
