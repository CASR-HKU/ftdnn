// unit test for sblk control
`include "ftdl_conf.vh"
module tb_sblk_ctrl;

parameter CLK_PERIOD = 10;


reg                                            clk_l;
reg                                            rst_n;

wire           [`WBUF_ADDR_LEN-1:0]            wbuf_rd_addr;

wire           [`HW_D1-1:0]                    actbuf_wr_en;
wire           [`ACTBUF_ADDR_LEN-2:0]          actbuf_wr_addrh;
wire                                           actbuf_wr_req;
reg                                            actbuf_wr_vld;

wire           [`ACTBUF_ADDR_LEN-2:0]          actbuf_rd_addrh;

wire                                           pbuf_wr_en;
wire           [`PBUF_ADDR_LEN-1:0]            pbuf_wr_addr;
wire           [`PBUF_ADDR_LEN-1:0]            pbuf_rd_addr;
wire                                           status_sblk;

initial begin
    clk_l = 1'b1;
    forever #(CLK_PERIOD/2) clk_l = ~clk_l;
end

initial begin
    rst_n = 1'b1;
    repeat(2) @(negedge clk_l);
    rst_n = 1'b0;
    repeat(2) @(negedge clk_l);
    rst_n = 1'b1;
end

initial begin
    repeat(20000) @(posedge clk_l);
    $finish;
end

reg            [15:0]                          vld_cnt;
initial begin
    actbuf_wr_vld = 0;
    vld_cnt = 16'hffff;
    @ (posedge actbuf_wr_req);
    repeat(5) @(posedge clk_l);
    for (int i = 0; i < 27; i++) begin
        @(posedge clk_l) begin 
            if (actbuf_wr_req==1) begin
                actbuf_wr_vld = 1;
                vld_cnt = vld_cnt+1;
            end
        end
    end
    for (int i = 0; i < 5; i++) begin
        @(posedge clk_l) begin
            actbuf_wr_vld = 0;
        end
    end
    while (1) begin
        @(posedge clk_l) begin 
            if (actbuf_wr_req==1) begin
                actbuf_wr_vld = 1;
                vld_cnt = vld_cnt+1;
            end
        end
    end
end

sblk_ctrl u_sblk_ctrl(
    .clk_l(clk_l),
    .rst_n(rst_n),
    .wbuf_rd_addr(wbuf_rd_addr),
    .actbuf_wr_en(actbuf_wr_en),
    .actbuf_wr_addrh(actbuf_wr_addrh),
    .actbuf_wr_req(actbuf_wr_req),
    .actbuf_wr_vld(actbuf_wr_vld),
    .actbuf_rd_addrh(actbuf_rd_addrh),
    .pbuf_wr_en(pbuf_wr_en),
    .pbuf_wr_addr(pbuf_wr_addr),
    .pbuf_rd_addr(pbuf_rd_addr),
    .status_sblk(status_sblk)
);
endmodule
