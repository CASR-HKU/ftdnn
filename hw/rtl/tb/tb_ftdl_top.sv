// unit test for ftdl top
`timescale 1ns / 10ps
module tb_ftdl_top;

parameter CLKH_PERIOD = 4;
parameter CLKL_PERIOD = 8;


reg                                            clk_h;
reg                                            clk_l;
reg                                            rst_n;

reg            [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data;
wire                                           actbuf_wr_req;
reg                                            actbuf_wr_vld;

wire                                           sblk_status;
reg            [`HW_XLT_LEN-1:0]               sblk_param;
reg                                            sblk_param_en;

initial begin
    clk_h = 1'b1;
    forever #(CLKH_PERIOD/2) clk_h = ~clk_h;
end

initial begin
    clk_l = 1'b1;
    forever #(CLKL_PERIOD/2) clk_l = ~clk_l;
end

initial begin
    rst_n = 1'b1;
    sblk_param_en <= 1'b0;
    repeat(2) @(posedge clk_l);
    rst_n = 1'b0;
    repeat(2) @(posedge clk_l);
    rst_n = 1'b1;
    repeat(2) @(posedge clk_l);
    sblk_param_en <= 1'b1;
    sblk_param[`HW_X_K1_POS+:`HW_X_K1_LEN] <= `HW_X_K1;
    sblk_param[`HW_L_K3_POS+:`HW_L_K3_LEN] <= `HW_L_K3;
    sblk_param[`HW_T_K1_POS+:`HW_T_K1_LEN] <= `HW_T_K1;
    sblk_param[`HW_T_K2_POS+:`HW_T_K2_LEN] <= `HW_T_K2;
    sblk_param[`HW_T_K3_POS+:`HW_T_K3_LEN] <= `HW_T_K3;
    sblk_param[`ACTBUF_ADDRM_POS+:`ACTBUF_ADDRM_LEN] <= `ACTBUF_ADDRM_MAX;
    repeat(1) @(posedge clk_l);
    sblk_param_en <= 1'b0;
end

int actbuf_file;
string line;
int actbuf_data;
initial begin
    actbuf_file = $fopen("/home/yhding/ftdnn/hw/mem/act/actbuf_0_0_0.dat", "r");
    @(posedge sblk_status) $fclose(actbuf_file);
    actbuf_file = $fopen("/home/yhding/ftdnn/hw/mem/act/actbuf_0_0_1.dat", "r");
    @(posedge sblk_status) $fclose(actbuf_file);
    repeat(5) @(posedge clk_h);
    $finish;
end

function integer read_actbuf_updt();
    $fgets(line, actbuf_file);
    return line.atohex();
endfunction

int tb_sta;
int actbuf_cnt;
int actbuf_stop_cnt;
parameter STA_IDLE = 0;
parameter STA_WAIT_REQ = 1;
parameter STA_SEND_DATA = 2;
parameter STA_STOP_DATA = 3;
always_ff @(posedge clk_l) begin
    if(~rst_n) begin
        actbuf_wr_vld <= 0;
        actbuf_wr_data <= 0;
        tb_sta = STA_WAIT_REQ;
        actbuf_cnt = 0;
        actbuf_stop_cnt = 0;
    end else begin
        case (tb_sta)
            STA_WAIT_REQ: begin
                if(actbuf_wr_req==1) begin
                    tb_sta = STA_STOP_DATA;
                end
            end
            STA_SEND_DATA: begin
                actbuf_data = read_actbuf_updt();
                actbuf_wr_vld <= 1;
                actbuf_wr_data <= actbuf_data;
                actbuf_cnt = actbuf_cnt + 1;
                if (actbuf_cnt==27) begin
                    tb_sta = STA_STOP_DATA;
                end
                else if (actbuf_cnt==120) begin
                    tb_sta = STA_STOP_DATA;
                end
            end
            STA_STOP_DATA: begin
                actbuf_stop_cnt = actbuf_stop_cnt + 1;
                actbuf_wr_vld <= 0;
                actbuf_wr_data <= {16'hffff, 16'hffff};
                if (actbuf_stop_cnt==5) begin
                    tb_sta = STA_SEND_DATA;
                    actbuf_stop_cnt = 0;
                end
            end
        endcase
    end
end

ftdl_top u_ftdl_top(
    .clk_h(clk_h),
    .clk_l(clk_l),
    .rst_n(rst_n),
    .sblk_status(sblk_status),
    .sblk_param(sblk_param),
    .sblk_param_en(sblk_param_en),
    .actbuf_wr_data(actbuf_wr_data),
    .actbuf_wr_req(actbuf_wr_req),
    .actbuf_wr_vld(actbuf_wr_vld)
);

endmodule
