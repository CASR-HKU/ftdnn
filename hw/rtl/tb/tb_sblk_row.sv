// unit test for sblk row
`timescale 1ns / 1ns

module tb_sblk_row;

    parameter CLKL_PERIOD = 4;
    parameter CLKH_PERIOD = CLKL_PERIOD/2;

    parameter N_TILE = 4;
    parameter WID_N_TILE = $clog2(N_TILE);
    parameter WID_W = 16;
    parameter WID_WADDR = 10;
    parameter WID_ACT = 16;
    parameter WID_ACTADDR = 6;
    parameter WID_PSUM = 36;
    parameter WID_PSUMADDR = 9;
    parameter PSUM_SPLIT_START_POS = 12;

    parameter WID_INST_TN=3;
    parameter WID_INST_TM=3;
    parameter WID_INST_TP=3;
// FIXME: arbitrary width
parameter WID_INST_LN=3;
parameter WID_INST_LP=3;

parameter WID_INST = WID_INST_TN + WID_INST_TM + WID_INST_TP + WID_INST_LN + WID_INST_LP;
parameter WB_DELAY_CYCLE = N_TILE + 8;

// variables
int ii, jj;

reg clk_l, clk_h;
reg rst_n;

// instruction input signal
reg [WID_INST-1:0] inst_data;
reg                inst_en;

reg                act_data_in_vld;
reg [2*WID_ACT-1:0] act_data_in;


// instruction partition
reg [WID_INST_TN-1:0] n_tn;
reg [WID_INST_TM-1:0] n_tm;
reg [WID_INST_TP-1:0] n_tp;
reg [WID_INST_LN-1:0] n_ln;
reg [WID_INST_LP-1:0] n_lp;

// output wires of the module
wire                  act_data_in_req;
wire                  status_sblk;

initial begin
    clk_l = 1'b1;
    forever #(CLKL_PERIOD/2) clk_l = ~clk_l;
end

initial begin
    clk_h = 1'b1;
    forever #(CLKH_PERIOD/2) clk_h = ~clk_h;
end

initial begin
    rst_n = 1'b1;
    repeat(2) @(negedge clk_l);
    rst_n = 1'b0;
    repeat(20) @(negedge clk_l);
    rst_n = 1'b1;
end

// set instruction
initial begin
    n_tp = 4; n_tm = 6; n_tn = 3; n_ln = 1; n_lp = 1;
    inst_data = {n_lp, n_ln, n_tp, n_tm, n_tn};
    inst_en = 0;
    repeat(40) @(negedge clk_l);
    inst_en = 1;
    @(negedge clk_l);
    inst_en = 0;

    // @(negedge status_sblk);
    // n_tp = 3; n_tm = 2; n_tn = 2; n_ln = 2; n_lp = 2;
    // inst_data = {n_lp, n_ln, n_tp, n_tm, n_tn};
    // @(negedge clk_l);
    // inst_en = 1;
    // @(negedge clk_l);
    // inst_en = 0;
end

int cnt_tile, cnt_n, cnt_p;
// act data request response
initial begin
    act_data_in_vld = 0;
    cnt_tile = 0;
    cnt_n = 0;
    cnt_p = 0;
    forever begin
        if (act_data_in_req) begin
            while (1) begin
                @(negedge clk_l);
                act_data_in_vld = 1;
                act_data_in[0+:WID_ACT] = {cnt_tile[3:0], cnt_n[3:0], cnt_p[3:0], 4'h0};
                act_data_in[WID_ACT+:WID_ACT] = {cnt_tile[3:0], cnt_n[3:0], cnt_p[3:0], 4'h1};
                cnt_p = cnt_p + 1;
                if(cnt_p == n_tp) begin
                    cnt_p = 0;
                    cnt_n = cnt_n + 1;
                    if(cnt_n == n_tn) begin
                        cnt_n = 0;
                        cnt_tile = cnt_tile + 1;
                        if(cnt_tile == N_TILE) begin
                            cnt_tile = 0;
                            break;
                        end
                    end
                end
            end
        end
        else begin
            @(negedge clk_l);
            act_data_in_vld = 0;
            act_data_in <= 0;
        end
    end
end



initial begin
    repeat(1000) @(posedge clk_l);
    $finish;
end

sblk_row u_sblk_row(
    .clk_l(clk_l),
    .clk_h(clk_h),
    .rst_n(rst_n),
    .inst_data(inst_data),
    .inst_en(inst_en),
    .act_data_in_vld(act_data_in_vld),
    .act_data_in(act_data_in),
    .act_data_in_req(act_data_in_req),
    .status_sblk(status_sblk)
    );

endmodule
