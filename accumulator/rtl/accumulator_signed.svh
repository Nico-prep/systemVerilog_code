module accumulator_signed(
    input logic signed [15:0] in,
    input logic signed [15:0] load,
    input logic load_en,
    input logic rst,
    input logic clock,
    output logic signed [15:0] out,
    output logic ovl_det_pos,
    output logic ovl_det_neg
);

logic signed [16:0] state;

initial begin
    state = 17'sh0;
    ovl_det_pos = 1'b0;
    ovl_det_neg = 1'b0;
end

always_ff @(posedge clock or posedge rst) begin
    // reset 
    if (rst) begin
        state <= 17'sh0;
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b0;

        // load 
    end else if (load_en) begin
                // explicitly sign-extend 16-bit load into 17-bit state
                state <= {{1{load[15]}}, load};
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b0;

        // positive overload
    end else if ($signed(state) + $signed(in) > 32767) begin
        state <= 32767;
        ovl_det_pos <= 1'b1;
        ovl_det_neg <= 1'b0;

        // negative overload
    end else if ($signed(state) + $signed(in) < -32768) begin
        state <= -32768;
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b1;

        // normal operation
    end else begin
                // perform signed addition and store in signed state
                state <= $signed(state) + $signed(in);
        ovl_det_pos <= 1'b0;
        ovl_det_neg <= 1'b0;
    end
end

assign out = state[15:0];

endmodule
