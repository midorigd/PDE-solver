`include "bram.v"
`include "init.v"
`include "jacobi.v"

module PDEsolver #(
    parameter N = 32,
    parameter DATA_WIDTH = 16,
    parameter MAX_ITERS = 1000,
    parameter EPSILON = 16'h0005
)(
    input clk, rst, start,
    output done
);

    reg initialized;
    wire initDone;

    wire weA, weB;
    wire [$clog2(N*N)-1 : 0] wAddrA, wAddrB, rAddrA, rAddrB;
    wire [DATA_WIDTH-1 : 0]  wDataA, wDataB, rDataA, rDataB;

    wire initWeA, initWeB;
    wire [$clog2(N*N)-1 : 0] initWAddrA, initWAddrB;
    wire [DATA_WIDTH-1 : 0]  initWDataA, initWDataB;

    wire jacobiWeA, jacobiWeB;
    wire [$clog2(N*N)-1 : 0] jacobiWAddrA, jacobiWAddrB;
    wire [DATA_WIDTH-1 : 0]  jacobiWDataA, jacobiWDataB;


    assign weA = initialized ? jacobiWeA : initWeA;
    assign weB = initialized ? jacobiWeB : initWeB;
    assign wAddrA = initialized ? jacobiWAddrA : initWAddrA;
    assign wAddrB = initialized ? jacobiWAddrB : initWAddrB;
    assign wDataA = initialized ? jacobiWDataA : initWDataA;
    assign wDataB = initialized ? jacobiWDataB : initWDataB;


    always @(posedge clk) begin
        if (rst)
            initialized <= 0;
        else if (initDone)
            initialized <= 1;
    end


    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(N*N)
    ) BRAM_A (
        .clk(clk),
        .we(weA),
        .rAddr(rAddrA),
        .wAddr(wAddrA),
        .rData(rDataA),
        .wData(wDataA)
    );

    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(N*N)
    ) BRAM_B (
        .clk(clk),
        .we(weB),
        .rAddr(rAddrB),
        .wAddr(wAddrB),
        .rData(rDataB),
        .wData(wDataB)
    );

    init #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) initializer (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(initDone),

        .weA(initWeA),
        .weB(initWeB),
        .wAddrA(initWAddrA),
        .wAddrB(initWAddrB),
        .wDataA(initWDataA),
        .wDataB(initWDataB)
    );

    jacobi #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_ITERS(MAX_ITERS),
        .EPSILON(EPSILON)
    ) jacobiFSM (
        .clk(clk),
        .rst(rst),
        .start(initDone),
        .done(done),

        .rDataA(rDataA),
        .rDataB(rDataB),
        .rAddrA(rAddrA),
        .rAddrB(rAddrB),

        .weA(jacobiWeA),
        .weB(jacobiWeB),
        .wAddrA(jacobiWAddrA),
        .wAddrB(jacobiWAddrB),
        .wDataA(jacobiWDataA),
        .wDataB(jacobiWDataB)
    );

endmodule
