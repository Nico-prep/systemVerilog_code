`timescale 1ns/1ps

module efm_tb;

    // Parameters for easy modification
    parameter int WIDTH = 7;
    parameter int CYCLE_TIME_NS   = 10;      // 100 MHz clock
    parameter int HALF_CYCLE_NS   = CYCLE_TIME_NS / 2;
    parameter int TOTAL_CYCLES    = 2048;
    parameter real INPUT_FRAC = 0.05; // fraction of max value to use as input
    parameter int RESET_CYCLE     = TOTAL_CYCLES+1; // no reset during simulation
    
    logic signed [WIDTH-1:0] in;
    logic        rst;
    logic        clock;
    logic        out;
    logic        ovl_det_pos;
    logic        ovl_det_neg;
    logic signed [WIDTH-1:0] error;

   efm #(
    .WIDTH(WIDTH)
    ) uut (
        .in(in),
        .rst(rst),
        .clock(clock),
        .out(out),
        .error(error),
        .ovl_det_pos(ovl_det_pos),
        .ovl_det_neg(ovl_det_neg)
    );

// TB variables
    int cycle_count;

    initial begin
        $dumpfile("build/efm_tb.vcd");
        $dumpvars(0, efm_tb);
    end

    // Clock generation
    initial begin
        clock = 0;
        forever begin
            #(HALF_CYCLE_NS) clock = ~clock;
        end
    end

    // Stimulus
    initial begin
        in         = WIDTH'(0);
        rst        = 1'b1;   // start in reset for deterministic initialization
        cycle_count = 0;

        $display("running efm TB");
        $display("time(ns) cycle rst in out ovl_det_pos ovl_det_neg");
        $monitor("%0t %0d %b %0d %0d %b %b", $time, cycle_count, rst, in, out, ovl_det_pos, ovl_det_neg);

        wait (clock == 1'b1);
        @(posedge clock);

        while (cycle_count < TOTAL_CYCLES) begin
            // default stimulus
            in = WIDTH'($rtoi(((1 << (WIDTH-1)) - 1) * INPUT_FRAC));

            // reset active for one cycle at RESET_CYCLE
            if (cycle_count == RESET_CYCLE) begin
                rst = 1'b1;
            end else begin
                rst = 1'b0;
            end

            @(posedge clock);

            cycle_count++;
        end

        # (CYCLE_TIME_NS);
        $display("Simulation complete after %0d cycles", TOTAL_CYCLES);
        $finish;
    end

endmodule