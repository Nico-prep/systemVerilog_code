module accumulator(
    input logic [15:0] in,
    input logic [15:0] load,
    input logic load_en,
    input logic rst,
    input logic clock,
    output logic [15:0] out
);

logic [15:0] state;

initial begin
    state = 16'h0;
end

always_ff @(posedge clock or posedge rst) begin
    if (rst)
        state <= 16'h0;
    else if (load_en)
        state <= load;
    else
        state <= state + in;
end

assign out = state;

endmodule
