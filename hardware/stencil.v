module stencil #(
    parameter DATA_WIDTH = 16
)(
    input  [DATA_WIDTH-1 : 0] uAbove, uBelow, uLeft, uRight, uCenter,
    output [DATA_WIDTH-1 : 0] uNew, delta
);

    wire [DATA_WIDTH+1 : 0] sum;
    wire [DATA_WIDTH-1 : 0] tempDelta;

    assign sum = uAbove + uBelow + uLeft + uRight;

    assign uNew = sum[DATA_WIDTH+1 : 2];

    assign tempDelta = uNew - uCenter;
    assign delta = tempDelta[DATA_WIDTH-1] ? (~tempDelta + 1) : tempDelta;

endmodule
