module accumulator_parametric #(
    parameter int WIDTH = 16
)(
    input logic signed [WIDTH-1:0] in,
    input logic signed [WIDTH-1:0] load,
    input logic load_en,
    input logic rst,
    input logic clock,
    output logic signed [WIDTH-1:0] out,
    output logic ovl_det_pos,
    output logic ovl_det_neg
);

localparam int STATE_WIDTH = WIDTH + 1;
localparam logic signed [STATE_WIDTH-1:0] MAX_VAL = (1 << (WIDTH-1)) - 1;
localparam logic signed [STATE_WIDTH-1:0] MIN_VAL = - (1 << (WIDTH-1));

logic signed [STATE_WIDTH-1:0] state;

initial begin
    state = '0;
    ovl_det_pos = 1'b0;
    ovl_det_neg = 1'b0;
end

always_ff @(posedge clock or posedge rst) begin
    if (rst) begin
        state <= '0;
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b0;
    end else if (load_en) begin
        state <= {{1{load[WIDTH-1]}}, load};
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b0;
    end else if ($signed(state) + $signed(in) > MAX_VAL) begin
        state <= MAX_VAL;
        ovl_det_pos <= 1'b1;
        ovl_det_neg <= 1'b0;
    end else if ($signed(state) + $signed(in) < MIN_VAL) begin
        state <= MIN_VAL;
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b1;
    end else begin
        state <= $signed(state) + $signed(in);
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b0;
    end
end

assign out = state[WIDTH-1:0];

endmodule
