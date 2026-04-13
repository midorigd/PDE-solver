`include "stencil.v"

module jacobi #(
    parameter N = 32,
    parameter DATA_WIDTH = 16,
    parameter MAX_ITERS = 1000,
    parameter EPSILON = 16'h0005
)(
    input clk, reset, start,
    output reg done,

    // read ports
    input [DATA_WIDTH-1 : 0]   rDataA, rDataB,
    output [$clog2(N*N)-1 : 0] rAddrA, rAddrB,

    // write ports
    output weA, weB,
    output [$clog2(N*N)-1 : 0] wAddrA, wAddrB,
    output [DATA_WIDTH-1 : 0]  wDataA, wDataB
);

    // state encoding and registers

    reg [2:0] state;

    localparam IDLE = 0;
    localparam READ = 1;
    localparam COMPUTE = 2;
    localparam WRITE = 3;
    localparam NEXT_POINT = 4;
    localparam CHECK_CONV = 5;
    localparam NEXT_ITER = 6;


    // datapath registers

    reg [$clog2(N)-1 : 0] i, j;     // point coordinates
    reg bufSel;                     // BRAM path selector

    reg [$clog2(MAX_ITERS)-1 : 0] iterCount;
    reg [2:0] readCount;

    // storing stencil data for current cycle
    reg [DATA_WIDTH-1 : 0] maxDelta;
    reg [DATA_WIDTH-1 : 0] uAbove, uBelow, uLeft, uRight, uCenter;


    // internal data wires

    wire [DATA_WIDTH-1 : 0] uNew, delta, rData;
    wire [$clog2(N*N)-1 : 0] wAddr;
    reg  [$clog2(N*N)-1 : 0] rAddr;


    // stencil module to find neighboring point averages and convergence

    stencil stencilUnit(
        .uAbove(uAbove),
        .uBelow(uBelow),
        .uLeft(uLeft),
        .uRight(uRight),
        .uCenter(uCenter),
        .uNew(uNew),
        .delta(delta)
    );


    // BRAM routing and other internal combinational

    // bufSel:
    // 0: read A -> write B
    // 1: read B -> write A

    assign weA =  bufSel & (state == WRITE);
    assign weB = ~bufSel & (state == WRITE);

    assign wAddr = (i << $clog2(N)) + j; // i * N + j
    assign wAddrA = wAddr;
    assign wAddrB = wAddr;

    assign wDataA = uNew;
    assign wDataB = uNew;

    assign rAddrA = rAddr;
    assign rAddrB = rAddr;

    assign rData = bufSel ? rDataB : rDataA;


    // FSM behavior

    always @(posedge clk) begin
        done <= 0;

        if (reset) begin
            state <= IDLE;
            i <= 1;
            j <= 1;
            bufSel <= 0;
            iterCount <= 0;
            readCount <= 0;
            maxDelta <= 0;
            rAddr <= 0;
        end
        else
            case (state)

                // wait for start signal, nothing driven
                IDLE: begin
                    if (start)
                        state <= READ;
                end

                // read and latch each neighbor point (1-cycle latency)
                READ: begin
                    case (readCount)
                        0: rAddr <= ((i-1) << $clog2(N)) + j;

                        1: begin
                            rAddr <= ((i+1) << $clog2(N)) + j;
                            uAbove <= rData;
                        end

                        2: begin
                            rAddr <= (i << $clog2(N)) + j-1;
                            uBelow <= rData;
                        end

                        3: begin
                            rAddr <= (i << $clog2(N)) + j+1;
                            uLeft <= rData;
                        end

                        4: begin
                            rAddr <= (i << $clog2(N)) + j;
                            uRight <= rData;
                        end

                        5: begin
                            uCenter <= rData;
                        end
                    endcase

                    if (readCount == 5) begin
                        readCount <= 0;
                        state <= COMPUTE;
                    end else
                        readCount <= readCount + 1;
                end

                // update maxDelta if applicable
                COMPUTE: begin
                    if (maxDelta < delta)
                        maxDelta <= delta;
                    state <= WRITE;
                end

                // write uNew to BRAM, all done combinationally
                WRITE: state <= NEXT_POINT;

                // move to the next point and read again, or move on if all points have been read
                NEXT_POINT: begin
                    if (i == N - 2 && j == N - 2) begin
                        i <= 1;
                        j <= 1;
                        state <= CHECK_CONV;
                    end
                    else if (j == N - 2) begin
                        j <= 1;
                        i <= i + 1;
                        state <= READ;
                    end
                    else begin
                        j <= j + 1;
                        state <= READ;
                    end
                end

                // exit if convergence or iteration limit reached
                CHECK_CONV: begin
                    if (maxDelta < EPSILON || iterCount == MAX_ITERS - 1) begin
                        done <= 1;
                        state <= IDLE;
                    end else
                        state <= NEXT_ITER;
                end

                // invert BRAM routing, reset for next iteration
                NEXT_ITER: begin
                    bufSel <= ~bufSel;
                    maxDelta <= 0;
                    iterCount <= iterCount + 1;
                    state <= READ;
                end
            endcase
    end

endmodule
