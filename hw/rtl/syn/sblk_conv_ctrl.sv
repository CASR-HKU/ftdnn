`timescale 1ns / 1ns
`include "ftdnn_conv_conf.vh"

module sblk_conv_ctrl (
    // Outputs
    wbuf_rd_addr, actbuf_wr_en, actbuf_wr_addrh, actbuf_wr_req, actbuf_rd_addrh,
    pbuf_wr_en, pbuf_wr_addr, pbuf_rd_addr, sblk_status,
    // Inputs
    clk_l, rst_n, actbuf_wr_vld, sblk_param, sblk_param_en
);
parameter POS_D3=0;

input wire                                     clk_l;
input wire                                     rst_n;

output wire                                    sblk_status;
input wire     [`HW_XLT_LEN-1:0]               sblk_param;
input                                          sblk_param_en;

output reg     [`WBUF_ADDR_LEN-1:0]            wbuf_rd_addr;

output wire    [`HW_D1-1:0]                    actbuf_wr_en;
output wire    [`ACTBUF_ADDRH_LEN-1:0]         actbuf_wr_addrh;
output reg                                     actbuf_wr_req;
input wire                                     actbuf_wr_vld;

output wire    [`ACTBUF_ADDRH_LEN-1:0]         actbuf_rd_addrh;

output wire                                    pbuf_wr_en;
output wire    [`PBUF_ADDR_LEN-1:0]            pbuf_wr_addr;
output wire    [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr;

/*********************************************************************************************/
/**************SIGNAL DECLARATION*************************************************************/
/*********************************************************************************************/

/**************SBLK_CTRL state control********************************************************/
wire                                           actbuf_flag;
reg                                            actbuf_swap_en;
reg                                            actbuf_updt_sel;
reg                                            actbuf_calc_sel;
reg                                            actbuf_updt_busy;
reg                                            actbuf_calc_busy;
wire                                           actbuf_updt_finish;
wire                                           actbuf_calc_finish;

reg                                            pbuf_calc_sel;
/**************ACTBUF update control**********************************************************/
reg            [`HW_D1_LEN-1:0]                actbuf_updt_tpe_cnt;
wire                                           actbuf_updt_tpe_sig;
reg            [`ACTBUF_ADDRM_LEN-1:0]         actbuf_updt_addrm_cnt;
wire                                           actbuf_updt_addrm_sig;
wire           [`ACTBUF_ADDRM_LEN-1:0]         actbuf_updt_addrm_max;

/**************Calculation loop control*******************************************************/
reg            [`HW_XLT_LEN-1:0]               sblk_param_reg;
reg                                            calc_loop_en;
// T loop cnt and finish flag of each k-level
reg            [`HW_T_K3_LEN-1:0]              t_k3_cnt;
wire           [`HW_T_K3_LEN-1:0]              t_k3_max;
wire                                           t_k3_sig;
reg            [`HW_T_K2_LEN-1:0]              t_k2_cnt;
wire           [`HW_T_K2_LEN-1:0]              t_k2_max;
wire                                           t_k2_sig;
reg            [`HW_T_K1_LEN-1:0]              t_k1_cnt;
wire           [`HW_T_K1_LEN-1:0]              t_k1_max;
wire                                           t_k1_sig;
wire                                           t_flag;
// delay from t_flag to calc_flag: 3 necessary delay, then is the same as PBUF_WR_ADDR_DELAY.
localparam ACTBUF_CALC_FLAG_DELAY=2 + `HW_D1/2 + 1;
reg                                            t_flag_d[ACTBUF_CALC_FLAG_DELAY];
wire                                           calc_flag;
// L loop cnt and finish flag of each k-level
// cl_k2 and cl_k1 are not used
reg            [`HW_L_K3_LEN-1:0]              l_k3_cnt;
wire           [`HW_L_K3_LEN-1:0]              l_k3_max;
wire                                           l_k3_sig;
wire                                           l_flag;
// X loop cnt and finish flag of each k-level
// cx_k3 and cx_k2 are not used
reg            [`HW_X_K1_LEN-1:0]              x_k1_cnt;
wire           [`HW_X_K1_LEN-1:0]              x_k1_max;
wire                                           x_k1_sig;
wire                                           x_flag;
// ACTBUF read address counter
reg            [`ACTBUF_ADDRH_LEN-1:0]         actbuf_rd_cnt;
// PBUF read address counter
reg            [`PBUF_ADDR_LEN-1:0]            pbuf_rd_cnt;
// delay from pbuf_rd_addr to pbuf_wr_addr
localparam PBUF_WR_ADDR_DELAY = 4 + `HW_D1/2 + 1;
reg            [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr_d[PBUF_WR_ADDR_DELAY];
// delay from calc_loop_en to pbuf_wr_en
localparam PBUF_WR_EN_DELAY = 1 + PBUF_WR_ADDR_DELAY;
reg                                            calc_loop_en_d[PBUF_WR_EN_DELAY];


assign sblk_status = actbuf_flag;

/*********************************************************************************************/
/**************SBLK_CTRL state control********************************************************/
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

// Loop param

always @(posedge clk_l or negedge rst_n) begin : proc_sblk_param
    if (~rst_n) begin
        sblk_param_reg <= 0;
    end else begin
        if (sblk_param_en) begin
            sblk_param_reg <= sblk_param;
        end
    end
end

assign t_k3_max = sblk_param_reg[`HW_T_K3_POS+:`HW_T_K3_LEN];
assign t_k2_max = sblk_param_reg[`HW_T_K2_POS+:`HW_T_K2_LEN];
assign t_k1_max = sblk_param_reg[`HW_T_K1_POS+:`HW_T_K1_LEN];
assign l_k3_max = sblk_param_reg[`HW_L_K3_POS+:`HW_L_K3_LEN];
assign x_k1_max = sblk_param_reg[`HW_X_K1_POS+:`HW_X_K1_LEN];
assign actbuf_updt_addrm_max = sblk_param_reg[`ACTBUF_ADDRM_LEN-1:0];

/*********************************************************************************************/
/**************ACTBUF update control**********************************************************/
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
assign actbuf_wr_en = actbuf_wr_vld?(1<<actbuf_updt_tpe_cnt):{(`HW_D1){1'b0}};
assign actbuf_wr_addrh = {actbuf_updt_sel, actbuf_updt_addrm_cnt};

// tpe_cnt and addr_cnt for actbuf_updt, count updated data(based on req and vld on last clk)
assign actbuf_updt_tpe_sig = (actbuf_updt_tpe_cnt==`HW_D1-1);
assign actbuf_updt_addrm_sig = (actbuf_updt_addrm_cnt==actbuf_updt_addrm_max-1);
assign actbuf_updt_finish = actbuf_wr_vld & actbuf_updt_tpe_sig & actbuf_updt_addrm_sig;  // make sure last valid data is written in
always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_updt
    if(~rst_n) begin
        actbuf_updt_tpe_cnt <= 0;
        actbuf_updt_addrm_cnt <= 0;
    end else begin
        actbuf_updt_tpe_cnt <= actbuf_wr_vld?(actbuf_updt_tpe_sig? 0 : actbuf_updt_tpe_cnt+1):actbuf_updt_tpe_cnt;
        actbuf_updt_addrm_cnt <= (actbuf_wr_vld&actbuf_updt_tpe_sig)?(actbuf_updt_addrm_sig? 0 : actbuf_updt_addrm_cnt+1):actbuf_updt_addrm_cnt;
    end
end

/*********************************************************************************************/
/**************Calculation loop control*******************************************************/
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

// ACTBUF calculation finished flag
assign actbuf_calc_finish = t_flag;

// T loop control
assign t_k3_sig = (t_k3_cnt==t_k3_max-2);
assign t_k2_sig = (t_k2_cnt==t_k2_max-1);
assign t_k1_sig = (t_k1_cnt==t_k1_max-1);
assign t_flag = t_k3_sig & t_k2_sig & t_k1_sig;

always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_k3_cnt
    if(~rst_n) begin
        t_k3_cnt <= 0;
    end else begin
        t_k3_cnt <= calc_loop_en? (t_k3_sig? 0 : t_k3_cnt + 2) : t_k3_cnt;
    end
end

always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_k2_cnt
    if(~rst_n) begin
        t_k2_cnt <= 0;
    end else begin
        t_k2_cnt <= (t_k3_sig)? (t_k2_sig? 0 : t_k2_cnt + 1) : t_k2_cnt;
    end
end

always_ff @(posedge clk_l or negedge rst_n) begin : proc_t_k1_cnt
    if(~rst_n) begin
        t_k1_cnt <= 0;
    end else begin
        t_k1_cnt <= (t_k3_sig&t_k2_sig)? (t_k1_sig? 0 : t_k1_cnt + 1) : t_k1_cnt;
    end
end

// L loop control
assign l_k3_sig = (l_k3_cnt==l_k3_max-1);
assign l_flag = t_flag & l_k3_sig;

always_ff @(posedge clk_l or negedge rst_n) begin : proc_l_k3_cnt
    if(~rst_n) begin
        l_k3_cnt <= 0;
    end else begin
        l_k3_cnt <= (t_flag)? (l_k3_sig? 0 : l_k3_cnt + 1) : l_k3_cnt;
    end
end


// X loop control
assign x_k1_sig = (x_k1_cnt==x_k1_max-1);
assign x_flag = l_flag & x_k1_sig;

always_ff @(posedge clk_l or negedge rst_n) begin : proc_x_k1_cnt
    if(~rst_n) begin
        x_k1_cnt <= 0;
    end else begin
        x_k1_cnt <= (l_flag)? (x_k1_sig? 0 : x_k1_cnt + 1) : x_k1_cnt;
    end
end

// TPE calc. r/w control

// WBUF read address
always_ff @(posedge clk_l or negedge rst_n) begin : proc_wbuf_rd_addr
    if(~rst_n) begin
        wbuf_rd_addr <= 0;
    end else begin
        wbuf_rd_addr <= x_k1_cnt*t_k1_max*t_k2_max + t_k1_cnt*t_k2_max + t_k2_cnt;
    end
end

// ActBUF read address
assign actbuf_rd_addrh = {actbuf_calc_sel, actbuf_rd_cnt[`ACTBUF_ADDRH_LEN-1:1]};
always_ff @(posedge clk_l or negedge rst_n) begin : proc_actbuf_rd_cnt
    if(~rst_n) begin
        actbuf_rd_cnt <= 0;
    end else begin
        actbuf_rd_cnt <= t_k1_cnt*t_k3_max + t_k3_cnt;
    end
end

// PBUF read address
assign pbuf_rd_addr = {pbuf_calc_sel, pbuf_rd_cnt[`PBUF_ADDR_LEN-1:1]};
always_ff @(posedge clk_l or negedge rst_n) begin : proc_pbuf_rd_cnt
    if(~rst_n) begin
        pbuf_calc_sel <= 0;
        pbuf_rd_cnt <= 0;
    end else begin
        pbuf_rd_cnt <= l_k3_cnt*t_k2_max*t_k3_max + t_k2_cnt*t_k3_max + t_k3_cnt;
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