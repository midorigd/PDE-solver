`timescale 1ns / 1ps

`include "PDEsolver.v"

module tb;

    localparam N = 32;
    localparam DATA_WIDTH = 32;
    localparam MAX_ITERS = 1000;
    localparam EPSILON   = 32'h00000008;
    localparam TOLERANCE = 32'h00000020;

    localparam TOP_VAL    = (1 << (DATA_WIDTH/2));
    localparam BOTTOM_VAL = {DATA_WIDTH{1'b0}};
    localparam LEFT_VAL   = {DATA_WIDTH{1'b0}};
    localparam RIGHT_VAL  = {DATA_WIDTH{1'b0}};

    reg clk, rst, start;
    wire done;

    reg [DATA_WIDTH-1 : 0] refMem [0 : N*N-1];
    reg [DATA_WIDTH-1 : 0] hwVal;
    reg [DATA_WIDTH : 0] diff;
    integer fd, errors, i;

    always #5 clk = ~clk;

    PDEsolver #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_ITERS(MAX_ITERS),
        .EPSILON(EPSILON),

        .TOP_VAL(TOP_VAL),
        .BOTTOM_VAL(BOTTOM_VAL),
        .LEFT_VAL(LEFT_VAL),
        .RIGHT_VAL(RIGHT_VAL)
    ) dut (
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

        // load comparison file from Python simulator
        $readmemh("reference.hex", refMem);

        fd = $fopen("output.hex", "w");
        errors = 0;

        for (i = 0; i < N*N; i = i + 1) begin
            hwVal = dut.jacobiFSM.bufSel ? dut.BRAM_A.mem[i] : dut.BRAM_B.mem[i];
            $fwrite(fd, "%h\n", hwVal);

            diff = refMem[i] - hwVal;
            if (diff[DATA_WIDTH])
                diff = ~diff + 1;

            if (diff > TOLERANCE) begin
                $display("addr=%0d, ref=%h, actual=%h, delta=%h", i+1, refMem[i], hwVal, diff);
                errors = errors + 1;
            end
        end

        $fclose(fd);

        $display("Iterations: %0d", dut.jacobiFSM.iterCount);
        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
