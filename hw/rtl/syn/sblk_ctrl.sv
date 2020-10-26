`timescale 1ns / 1ns
`include "ftdnn_conf.vh"

module sblk_ctrl (
    // Outputs
    wbuf_rd_addr, actbuf_wr_en, actbuf_wr_addrh, actbuf_wr_req, actbuf_rd_addr, actbuf_rd_addr_increment,
    pbuf_wr_en, pbuf_wr_addr, pbuf_rd_addr, sblk_status,
    // Inputs
    clk_l, rst_n, actbuf_wr_vld, temp_param, temp_param_en
);
parameter POS_D3=0;

input wire                                     clk_l;
input wire                                     rst_n;

output wire                                    sblk_status;
input wire     [`HW_TEMP_PARAM_LEN-1:0]        temp_param;
input                                          temp_param_en;

output reg     [`WBUF_ADDR_LEN-1:0]            wbuf_rd_addr;

output wire    [`HW_D1-1:0]                    actbuf_wr_en;
output wire    [`ACTBUF_ADDRH_LEN-1:0]         actbuf_wr_addrh;
output reg                                     actbuf_wr_req;
input wire                                     actbuf_wr_vld;

output wire    [`ACTBUF_ADDR_LEN-1:0]          actbuf_rd_addr;
output reg     [`ACTBUF_ADDR_LEN-1:0]          actbuf_rd_addr_increment;

output wire                                    pbuf_wr_en;
output wire    [`PBUF_ADDR_LEN-1:0]            pbuf_wr_addr;
output wire    [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr;

/*********************************************************************************************/
/**************state control signal***********************************************************/
/*********************************************************************************************/

wire                                           actbuf_flag;
reg                                            actbuf_swap_en;
reg                                            actbuf_updt_sel;
reg                                            actbuf_calc_sel;
reg                                            actbuf_calc_sel_d;
reg                                            actbuf_updt_busy;
reg                                            actbuf_calc_busy;
wire                                           actbuf_updt_finish;
wire                                           actbuf_calc_finish;

reg                                            pbuf_calc_sel;

/*********************************************************************************************/
/**************temporal loop signal***********************************************************/
/*********************************************************************************************/

reg                                            calc_loop_en;
wire                                           calc_flag;
reg                                            t_param_update_en;
// auto generate
reg            [`HW_TEMP_PARAM0_LEN-1:0]       t_param0_cnt;
reg            [`HW_TEMP_PARAM0_LEN-1:0]       T_PARAM0;
wire                                           t_param0_en;
wire                                           t_param0_rst;
reg            [`HW_TEMP_PARAM1_LEN-1:0]       t_param1_cnt;
reg            [`HW_TEMP_PARAM1_LEN-1:0]       T_PARAM1;
wire                                           t_param1_en;
wire                                           t_param1_rst;
reg            [`HW_TEMP_PARAM2_LEN-1:0]       t_param2_cnt;
reg            [`HW_TEMP_PARAM2_LEN-1:0]       T_PARAM2;
wire                                           t_param2_en;
wire                                           t_param2_rst;
reg            [`HW_TEMP_PARAM3_LEN-1:0]       t_param3_cnt;
reg            [`HW_TEMP_PARAM3_LEN-1:0]       T_PARAM3;
wire                                           t_param3_en;
wire                                           t_param3_rst;
reg            [`HW_TEMP_PARAM4_LEN-1:0]       t_param4_cnt;
reg            [`HW_TEMP_PARAM4_LEN-1:0]       T_PARAM4;
wire                                           t_param4_en;
wire                                           t_param4_rst;
reg            [`HW_TEMP_PARAM5_LEN-1:0]       t_param5_cnt;
reg            [`HW_TEMP_PARAM5_LEN-1:0]       T_PARAM5;
wire                                           t_param5_en;
wire                                           t_param5_rst;
reg            [`HW_TEMP_PARAM6_LEN-1:0]       t_param6_cnt;
reg            [`HW_TEMP_PARAM6_LEN-1:0]       T_PARAM6;
wire                                           t_param6_en;
wire                                           t_param6_rst;
reg            [`HW_TEMP_PARAM7_LEN-1:0]       t_param7_cnt;
reg            [`HW_TEMP_PARAM7_LEN-1:0]       T_PARAM7;
wire                                           t_param7_en;
wire                                           t_param7_rst;

/*********************************************************************************************/
/**************ACTBUF update control signal***************************************************/
/*********************************************************************************************/

wire                                           actbuf_updt_tpe_en;
reg            [`HW_D1_LEN-1:0]                actbuf_updt_tpe_cnt;
wire                                           actbuf_updt_tpe_rst;
wire                                           actbuf_updt_addrm_en;
reg            [`ACTBUF_ADDRM_LEN-1:0]         actbuf_updt_addrm_cnt;
wire                                           actbuf_updt_addrm_rst;
reg            [`ACTBUF_ADDRM_LEN-1:0]         ACTBUF_UPDT_ADDRM_CAP;

/*********************************************************************************************/
/**************calculation control signal*****************************************************/
/*********************************************************************************************/

// ACTBUF read address counter
reg            [`ACTBUF_ADDR_LEN-2:0]          actbuf_rd_cnt;
// PBUF read address counter
reg            [`PBUF_ADDR_LEN-2:0]            pbuf_rd_cnt;

/*********************************************************************************************/
/**************delay control signal***********************************************************/
/*********************************************************************************************/

// delay from pbuf_rd_addr to pbuf_wr_addr
localparam PBUF_WR_ADDR_DELAY = 4 + (`HW_D1+1)/2 + 1;
reg            [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr_d[PBUF_WR_ADDR_DELAY];
// delay from calc_loop_en to pbuf_wr_en
localparam PBUF_WR_EN_DELAY = 1 + PBUF_WR_ADDR_DELAY;
reg                                            calc_loop_en_d[PBUF_WR_EN_DELAY];

// for simulation
assign sblk_status = actbuf_flag;

/*********************************************************************************************/
/**************state control******************************************************************/
/*********************************************************************************************/

assign actbuf_flag = (actbuf_updt_finish&actbuf_calc_finish)|
                    (actbuf_updt_finish&(~actbuf_calc_busy))|
                    (actbuf_calc_finish&(~actbuf_updt_busy));
// ACTBUF state
always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_sta
    if(~rst_n) begin
        actbuf_swap_en <= 0;
        actbuf_updt_sel <= 0;
        actbuf_calc_sel <= 1;
        actbuf_updt_busy <= 1;
        actbuf_calc_busy <= 0;
    end else begin
        // both finished, enable swap
        if (actbuf_flag) begin
            actbuf_swap_en <= 1;
            actbuf_updt_busy <= 1;
            actbuf_calc_busy <= 1;
        end
        // one of them finished, set busy; nothing happen if none of them finished
        else begin
            if (actbuf_updt_finish) begin
                actbuf_updt_busy <= 0;
            end
            if (actbuf_calc_finish) begin
                actbuf_calc_busy <= 0;
            end
        end
        // swap double buffering select bit
        if (actbuf_swap_en) begin
            actbuf_swap_en <= 0;
            actbuf_updt_sel <= ~actbuf_updt_sel;
            actbuf_calc_sel <= ~actbuf_calc_sel;
        end
    end
end

/*********************************************************************************************/
/**************temporal loop read*************************************************************/
/*********************************************************************************************/

always @(posedge clk_l or negedge rst_n) begin : proc_temp_param
    if (~rst_n) begin
        T_PARAM0 <= 0;
        T_PARAM1 <= 0;
        T_PARAM2 <= 0;
        T_PARAM3 <= 0;
        T_PARAM4 <= 0;
        T_PARAM5 <= 0;
        T_PARAM6 <= 0;
        T_PARAM7 <= 0;
        t_param_update_en <=0;
        ACTBUF_UPDT_ADDRM_CAP <= 0;
    end else begin
        if (temp_param_en) begin
            t_param_update_en <= 1;
            T_PARAM0 <= temp_param[`HW_TEMP_PARAM0_POS+:`HW_TEMP_PARAM0_LEN];
            T_PARAM1 <= temp_param[`HW_TEMP_PARAM1_POS+:`HW_TEMP_PARAM1_LEN];
            T_PARAM2 <= temp_param[`HW_TEMP_PARAM2_POS+:`HW_TEMP_PARAM2_LEN];
            T_PARAM3 <= temp_param[`HW_TEMP_PARAM3_POS+:`HW_TEMP_PARAM3_LEN];
            T_PARAM4 <= temp_param[`HW_TEMP_PARAM4_POS+:`HW_TEMP_PARAM4_LEN];
            T_PARAM5 <= temp_param[`HW_TEMP_PARAM5_POS+:`HW_TEMP_PARAM5_LEN];
            T_PARAM6 <= temp_param[`HW_TEMP_PARAM6_POS+:`HW_TEMP_PARAM6_LEN];
            T_PARAM7 <= temp_param[`HW_TEMP_PARAM7_POS+:`HW_TEMP_PARAM7_LEN];
        end
        else begin
            t_param_update_en <= 0;
        end
        if (t_param_update_en) begin
            // be careful about the size calculation
            ACTBUF_UPDT_ADDRM_CAP <= ((T_PARAM2+1)*(T_PARAM0+1)*(T_PARAM1+1))>>1;
        end
    end
end

/*********************************************************************************************/
/**************ACTBUF update******************************************************************/
/*********************************************************************************************/

// actbuf_wr_req: act write data request
// 1: update on ACTBUF finished
// 0: update on ACTBUF running
always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_wr_req
    if(~rst_n) begin
        actbuf_wr_req <= 0;
    end else begin
        if (actbuf_updt_busy) begin
            actbuf_wr_req <= 1;
            if (actbuf_updt_finish) begin
                actbuf_wr_req <= 0;
            end
        end
    end
end

// wr_en is based on vld on current clk(sync to actbuf_data, actbuf_vld)
assign actbuf_wr_en = actbuf_updt_tpe_en?(1<<actbuf_updt_tpe_cnt):{(`HW_D1){1'b0}};
assign actbuf_wr_addrh = {actbuf_updt_sel, actbuf_updt_addrm_cnt};
assign actbuf_updt_finish = actbuf_wr_vld & actbuf_updt_tpe_rst & actbuf_updt_addrm_rst;  // make sure last valid data is written in

// tpe_cnt and addr_cnt for actbuf_updt, count updated data(based on req and vld on last clk)
assign actbuf_updt_tpe_en = actbuf_wr_vld & actbuf_wr_req;
assign actbuf_updt_tpe_rst = (actbuf_updt_tpe_cnt==`HW_D1-1);
assign actbuf_updt_addrm_en = actbuf_updt_tpe_en & actbuf_updt_tpe_rst;
assign actbuf_updt_addrm_rst = (actbuf_updt_addrm_cnt==ACTBUF_UPDT_ADDRM_CAP-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_updt
    if(~rst_n) begin
        actbuf_updt_tpe_cnt <= 0;
        actbuf_updt_addrm_cnt <= 0;
    end else begin
        actbuf_updt_tpe_cnt <= actbuf_updt_tpe_en?(actbuf_updt_tpe_rst? 0 : actbuf_updt_tpe_cnt+1):actbuf_updt_tpe_cnt;
        actbuf_updt_addrm_cnt <= actbuf_updt_addrm_en?(actbuf_updt_addrm_rst? 0 : actbuf_updt_addrm_cnt+1):actbuf_updt_addrm_cnt;
    end
end

/*********************************************************************************************/
/**************temporal loop control**********************************************************/
/*********************************************************************************************/

// calc_loop_en:
// 1: enable calculating, loop running
// 0: disable calculating, loop stop
always_ff @(posedge clk_l or negedge rst_n) begin : proc_calc_loop_en
    if(~rst_n) begin
         calc_loop_en <= 0;
    end else begin
         if (actbuf_calc_busy) begin
            calc_loop_en <= 1;
            if (actbuf_calc_finish) begin
                calc_loop_en <= 0;
            end
         end
    end
end

// Loop control
// param0
assign t_param0_en = calc_loop_en;
assign t_param0_rst = (t_param0_cnt==T_PARAM0-2);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param0_cnt
    if(~rst_n) begin
        t_param0_cnt <= 0;
    end else begin
        t_param0_cnt <= t_param0_en? (t_param0_rst? 0 : t_param0_cnt + 2) : t_param0_cnt;
    end
end
// param1
assign t_param1_en = t_param0_en&t_param0_rst;
assign t_param1_rst = (t_param1_cnt==T_PARAM1-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param1_cnt
    if(~rst_n) begin
        t_param1_cnt <= 0;
    end else begin
        t_param1_cnt <= t_param1_en? (t_param1_rst? 0 : t_param1_cnt + 1) : t_param1_cnt;
    end
end
// param2
assign t_param2_en = t_param1_en&t_param1_rst;
assign t_param2_rst = (t_param2_cnt==T_PARAM2-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param2_cnt
    if(~rst_n) begin
        t_param2_cnt <= 0;
    end else begin
        t_param2_cnt <= t_param2_en? (t_param2_rst? 0 : t_param2_cnt + 1) : t_param2_cnt;
    end
end
// param3
assign t_param3_en = t_param2_en&t_param2_rst;
assign t_param3_rst = (t_param3_cnt==T_PARAM3-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param3_cnt
    if(~rst_n) begin
        t_param3_cnt <= 0;
    end else begin
        t_param3_cnt <= t_param3_en? (t_param3_rst? 0 : t_param3_cnt + 1) : t_param3_cnt;
    end
end
// param4
assign t_param4_en = t_param3_en&t_param3_rst;
assign t_param4_rst = (t_param4_cnt==T_PARAM4-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param4_cnt
    if(~rst_n) begin
        t_param4_cnt <= 0;
    end else begin
        t_param4_cnt <= t_param4_en? (t_param4_rst? 0 : t_param4_cnt + 1) : t_param4_cnt;
    end
end
// param5
assign t_param5_en = t_param4_en&t_param4_rst;
assign t_param5_rst = (t_param5_cnt==T_PARAM5-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param5_cnt
    if(~rst_n) begin
        t_param5_cnt <= 0;
    end else begin
        t_param5_cnt <= t_param5_en? (t_param5_rst? 0 : t_param5_cnt + 1) : t_param5_cnt;
    end
end
// param6
assign t_param6_en = t_param5_en&t_param5_rst;
assign t_param6_rst = (t_param6_cnt==T_PARAM6-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param6_cnt
    if(~rst_n) begin
        t_param6_cnt <= 0;
    end else begin
        t_param6_cnt <= t_param6_en? (t_param6_rst? 0 : t_param6_cnt + 1) : t_param6_cnt;
    end
end
// param7
assign t_param7_en = t_param6_en&t_param6_rst;
assign t_param7_rst = (t_param7_cnt==T_PARAM7-1);
always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_param7_cnt
    if(~rst_n) begin
        t_param7_cnt <= 0;
    end else begin
        t_param7_cnt <= t_param7_en? (t_param7_rst? 0 : t_param7_cnt + 1) : t_param7_cnt;
    end
end

/*********************************************************************************************/
/**************calculation control************************************************************/
/*********************************************************************************************/

// ACTBUF calculation finished flag
assign actbuf_calc_finish = t_param4_en;

// ActBUF read address
assign actbuf_rd_addr = {actbuf_calc_sel_d, actbuf_rd_cnt};
always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_rd_cnt
    if(~rst_n) begin
        actbuf_rd_cnt <= 0;
        actbuf_rd_addr_increment <= 0;
    end else begin
        actbuf_rd_cnt <= t_param2_cnt*T_PARAM0*T_PARAM1 + t_param0_cnt*T_PARAM1 + t_param1_cnt;
        actbuf_rd_addr_increment <= T_PARAM1;
    end
end

// WBUF read address
always_ff @(posedge clk_l or negedge rst_n) begin : proc_wbuf_rd_addr
    if(~rst_n) begin
        wbuf_rd_addr <= 0;
    end else begin
        wbuf_rd_addr <= t_param3_cnt*T_PARAM7*T_PARAM4*T_PARAM2 + t_param7_cnt*T_PARAM4*T_PARAM2 + t_param4_cnt*T_PARAM2 + t_param2_cnt;
    end
end

// PBUF read address
assign pbuf_rd_addr = {pbuf_calc_sel, pbuf_rd_cnt};
always_ff @(posedge clk_l or negedge rst_n) begin : proc_pbuf_rd_cnt
    if(~rst_n) begin
        pbuf_calc_sel <= 0;
        pbuf_rd_cnt <= 0;
    end else begin
        pbuf_rd_cnt <= t_param3_cnt*T_PARAM0*T_PARAM1 + t_param0_cnt*T_PARAM1 + t_param1_cnt;
    end
end

/*********************************************************************************************/
/**************delay control******************************************************************/
/*********************************************************************************************/

// for alignment with address cnt
always_ff @(posedge clk_l or negedge rst_n) begin : proc_calc_sel_d
    if(~rst_n) begin
        actbuf_calc_sel_d <= 0;
    end else begin
        actbuf_calc_sel_d <= actbuf_calc_sel;
    end
end

// PBUF write address
// assign pbuf_wr_addr with the last level delay
assign pbuf_wr_addr = pbuf_rd_addr_d[PBUF_WR_ADDR_DELAY-1];
// PBUF read address delay
always_ff @(posedge clk_l or negedge rst_n) begin : proc_pbuf_rd_addr_d
    if(~rst_n) begin
        for (int jj=0; jj<PBUF_WR_ADDR_DELAY; jj=jj+1) begin
            pbuf_rd_addr_d[jj] <= 0;
        end
    end else begin
        pbuf_rd_addr_d[0] <= pbuf_rd_addr;
        for (int jj=1; jj<PBUF_WR_ADDR_DELAY; jj=jj+1) begin
            pbuf_rd_addr_d[jj] <= pbuf_rd_addr_d[jj-1];
        end
    end
end

// PBUF write enable
// assign pbuf_wr_en with the last level delay
assign pbuf_wr_en = calc_loop_en_d[PBUF_WR_EN_DELAY-1];
// calc_loop_en delay
always_ff @(posedge clk_l or negedge rst_n) begin : proc_calc_loop_en_d
    if(~rst_n) begin
        for (int jj=0; jj<PBUF_WR_EN_DELAY; jj=jj+1) begin
            calc_loop_en_d[jj] <= 0;
        end
    end else begin
        calc_loop_en_d[0] <= calc_loop_en;
        for (int jj=1; jj<PBUF_WR_EN_DELAY; jj=jj+1) begin
            calc_loop_en_d[jj] <= calc_loop_en_d[jj-1];
        end
    end
end

/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/


endmodule