`timescale 1ns / 1ps

`include "PDEsolver.v"

module tb;

    reg clk, rst, start;
    wire done;

    always #5 clk = ~clk;

    PDEsolver #(.N(8)) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done)
    );

    initial begin
        clk = 0;
        rst = 0;
        start = 0;

        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        @(posedge done);
        $display("simulation finished");
        $finish;
    end

endmodule
