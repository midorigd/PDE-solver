module init #(
    parameter N = 32, // grid dimension
    parameter DATA_WIDTH = 16,
    
    parameter TOP_VAL    = (1 << (DATA_WIDTH/2)),
    parameter BOTTOM_VAL = {DATA_WIDTH{1'b0}},
    parameter LEFT_VAL   = {DATA_WIDTH{1'b0}},
    parameter RIGHT_VAL  = {DATA_WIDTH{1'b0}}
)(
    input clk, rst, start,
    output reg done,

    output weA, weB,
    output [$clog2(N*N)-1 : 0] wAddrA, wAddrB,
    output [DATA_WIDTH-1 : 0]  wDataA, wDataB
);

    reg started;

    // global registers since BRAMs A and B mirror each other
    reg we;
    reg [$clog2(N*N)-1 : 0] addr;
    wire [DATA_WIDTH-1 : 0] data;

    assign weA = we;
    assign weB = we;
    assign wAddrA = addr;
    assign wAddrB = addr;
    assign wDataA = data;
    assign wDataB = data;


    // compute addresses
    wire [$clog2(N)-1 : 0] i, j;

    assign i = addr[$clog2(N*N)-1 : $clog2(N)];
    assign j = addr[$clog2(N)-1 : 0];


    // assign cell value based on indices
    assign data = (i == 0)   ? TOP_VAL    :
                  (i == N-1) ? BOTTOM_VAL :
                  (j == 0)   ? LEFT_VAL   :
                  (j == N-1) ? RIGHT_VAL  :
                              {DATA_WIDTH{1'b0}};   // interior



    always @(posedge clk) begin
        done <= 0;

        // disable writes
        if (rst) begin
            started <= 0;
            we <= 0;
            addr <= 0;
        end

        // started state is loop condition
        else if (start) begin
            started <= 1;
            we <= 1;
        end

        // main logic
        else if (started) begin
            // raise done flag and end after all addresses written
            if (addr == N*N - 1) begin
                started <= 0;
                we <= 0;
                addr <= 0;
                done <= 1;
            end
            else begin
                addr <= addr + 1;
            end
        end
    end

endmodule
