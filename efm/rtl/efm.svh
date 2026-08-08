module efm #(
parameter WIDTH = 8
)(
	input  logic [WIDTH-1:0]	in,
    input  logic			rst,clock,
	output logic 			out,
    output logic ovl_det_pos,
    output logic ovl_det_neg,
    output logic [WIDTH-1:0] error 
);
	logic [WIDTH+1:0] delta, sigma, sigma_latched, delta_b;

	assign	delta_b	= {2{sigma_latched[WIDTH+1]}} << WIDTH,
		delta	= in + delta_b,
		sigma	= delta + sigma_latched,
        error   = sigma - delta_b;
    
    assign ovl_det_pos = 0, ovl_det_neg = 0;
	
	always_ff @(posedge clock, posedge rst) begin
		if(rst) begin
			sigma_latched	<= 0;
			out		<= 0;
		end else begin
			sigma_latched	<= sigma;
			out		<= sigma_latched[WIDTH+1];
		end
	end


endmodule
