module counter(
input logic rst,
input logic clock,
input logic enable,
output logic [7:0] count_value
);

// initialization
initial begin 
    count_value = 8'd0;
end

//
always_ff @(posedge clock or posedge rst) begin
    if (rst) begin
        count_value <=8'd0;
    end else if (enable) begin
        count_value<=count_value+1'd1;
    end

end

endmodule