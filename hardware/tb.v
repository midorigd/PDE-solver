`timescale 1ns / 1ps

`include "PDEsolver.v"

module tb;

    localparam N = 8;
    localparam DATA_WIDTH = 16;

    reg clk, rst, start;
    wire done;

    reg [DATA_WIDTH-1 : 0] refMem [0 : N*N-1];
    reg [DATA_WIDTH-1 : 0] hwVal;
    integer fd, errors, i;

    always #5 clk = ~clk;

    PDEsolver #(
        .N(N),
        .MAX_ITERS(10),
        .EPSILON(16'hFFFF)
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

        // @(posedge dut.initDone);
        // $stop;

        @(posedge done);

        // load comparison file from Python simulator
        $readmemh("reference.hex", refMem);

        fd = $fopen("output.hex", "w");
        errors = 0;

        for (i = 0; i < N*N; i = i + 1) begin
            hwVal = dut.jacobiFSM.bufSel ? dut.BRAM_A.mem[i] : dut.BRAM_B.mem[i];

            $fwrite(fd, "%h\n", hwVal);

            if (hwVal - refMem[i] > 16'h0008 || refMem[i] - hwVal > 16'h0008)
                errors = errors + 1;
        end

        $fclose(fd);

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
