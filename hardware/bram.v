module bram #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 1024
)(
    input clk, we,
    input [$clog2(DEPTH) - 1:0] rAddr, wAddr,
    input      [DATA_WIDTH - 1:0] wData,
    output reg [DATA_WIDTH - 1:0] rData
);

    reg [DATA_WIDTH - 1:0] mem [DEPTH - 1:0];

    always @(posedge clk) begin
        if (we)
            mem[wAddr] <= wData;

        rData <= mem[rAddr];
    end

endmodule
