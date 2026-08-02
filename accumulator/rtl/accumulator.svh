module accumulator(
    input logic [15:0] in,
    input logic [15:0] load,
    input logic load_en,
    input logic rst,
    input logic clock,
    output logic [15:0] out,
    output logic ovl_det
);

logic [16:0] state;

initial begin
    state = 17'h0;
    ovl_det = 1'b0;
end

always_ff @(posedge clock or posedge rst) begin
    if (rst) begin
        state <= 17'h0;
        ovl_det <= 1'b0;
    end else if (load_en) begin
        state <= load;
        ovl_det <= 1'b0;
    end else if (state + in > 17'h0FFFF) begin
        state <= 17'h0FFFF;
        ovl_det <= 1'b1;
    end else begin
        state <= state + in;
        ovl_det <= 1'b0;
    end
end

assign out = state[15:0];

endmodule
