`timescale 1ns / 1ns

module tb_round;


    reg clk;
    reg rst_n;
    reg [32-1:0] data_in[2];
    wire [8-1:0] data_out[2];


    initial begin
        clk = 1;
        forever #2 clk = ~clk;
    end

    initial begin
        rst_n = 1;
        repeat(5) @(posedge clk);
        rst_n = 0;
        repeat(20) @(posedge clk);
        rst_n = 1;
    end

    initial begin
        data_in[0] = {(32){1'b0}};
        data_in[1] = {(32){1'b0}};
        @(posedge rst_n);
        repeat(1000) begin
            @(posedge clk);
            data_in[0] = $random();
            data_in[1] = $random();
        end
        $finish();
    end

    stochastic_round test_pr(
        .clk(clk),
        .rst_n(rst_n),
        .data_in({data_in[1],data_in[0]}),
        .data_out({data_out[1],data_out[0]})
        );
endmodule