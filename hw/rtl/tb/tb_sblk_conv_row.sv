// unit test for sblk row
`timescale 1ns / 10ps
module tb_sblk_conv_row;

parameter CLKH_PERIOD = 4;
parameter CLKL_PERIOD = 8;


reg                                            clk_h;
reg                                            clk_l;
reg                                            rst_n;

reg            [2*`ACTBUF_DATA_LEN-1:0]        actbuf_wr_data;
wire                                           actbuf_wr_req;
reg                                            actbuf_wr_vld;

wire                                           sblk_status;
reg            [`HW_TEMP_PARAM_LEN-1:0]        temp_param;
reg                                            temp_param_en;

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
    temp_param_en <= 1'b0;
    repeat(2) @(posedge clk_l);
    rst_n = 1'b0;
    repeat(2) @(posedge clk_l);
    rst_n = 1'b1;
    repeat(2) @(posedge clk_l);
    temp_param_en <= 1'b1;
    temp_param[`HW_TEMP_PARAM0_POS+:`HW_TEMP_PARAM0_LEN] <= 4;
    temp_param[`HW_TEMP_PARAM1_POS+:`HW_TEMP_PARAM1_LEN] <= 7;
    temp_param[`HW_TEMP_PARAM2_POS+:`HW_TEMP_PARAM2_LEN] <= 2;
    temp_param[`HW_TEMP_PARAM3_POS+:`HW_TEMP_PARAM3_LEN] <= 8;
    temp_param[`HW_TEMP_PARAM4_POS+:`HW_TEMP_PARAM4_LEN] <= 8;
    temp_param[`HW_TEMP_PARAM5_POS+:`HW_TEMP_PARAM5_LEN] <= 7;
    temp_param[`HW_TEMP_PARAM6_POS+:`HW_TEMP_PARAM6_LEN] <= 2;
    temp_param[`HW_TEMP_PARAM7_POS+:`HW_TEMP_PARAM7_LEN] <= 4;
    repeat(1) @(posedge clk_l);
    temp_param_en <= 1'b0;
end

int actbuf_file;
string actbuf_file_name;
string x_str, l_str;
initial begin
    for (int x=0; x<7*2*4; x=x+1) begin
        x_str.itoa(x);
        for (int l=0; l<8; l=l+1) begin
            l_str.itoa(l);
            actbuf_file_name = {"/home/yhding/ftdnn/hw/mem/act/actbuf_0_0_",x_str,"_", l_str, ".dat"};
            $display(actbuf_file_name);
            actbuf_file = $fopen(actbuf_file_name, "r");
            @(posedge sblk_status) $fclose(actbuf_file);
            if (x==1&l==1) begin
                repeat(5) @(posedge clk_h);
                $finish;
            end
        end
    end
end

string line;
function integer read_actbuf_updt();
    $fgets(line, actbuf_file);
    return line.atohex();
endfunction

int tb_sta;
int actbuf_cnt;
int actbuf_stop_cnt;
int actbuf_data;
parameter STA_IDLE = 0;
parameter STA_WAIT_REQ = 1;
parameter STA_SEND_DATA = 2;
parameter STA_STOP_DATA = 3;
always_ff @(posedge clk_l or negedge rst_n) begin
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
                if(actbuf_wr_req==1) begin
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

sblk_conv_row u_sblk_conv_row(
    .clk_h(clk_h),
    .clk_l(clk_l),
    .rst_n(rst_n),
    .sblk_status(sblk_status),
    .temp_param(temp_param),
    .temp_param_en(temp_param_en),
    .actbuf_wr_data(actbuf_wr_data),
    .actbuf_wr_req(actbuf_wr_req),
    .actbuf_wr_vld(actbuf_wr_vld),
    .pbuf_rd_data()
);

endmodule
