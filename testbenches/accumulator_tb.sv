`timescale 1ns/1ps

module accumulator_tb;

    // Parameters for easy modification
    parameter int CYCLE_TIME_NS   = 10;      // 100 MHz clock
    parameter int HALF_CYCLE_NS   = CYCLE_TIME_NS / 2;
    parameter int TOTAL_CYCLES    = 200;
    parameter int RESET_CYCLE     = 50;
    parameter int LOAD_CYCLE      = 100;
    parameter int LOAD_VALUE      = 1000;

    logic [15:0] in;
    logic [15:0] load;
    logic        load_en;
    logic        rst;
    logic        clock;
    logic [15:0] out;

    logic [15:0] expected;
    int cycle_count;

    accumulator uut (
        .in(in),
        .load(load),
        .load_en(load_en),
        .rst(rst),
        .out(out),
        .clock(clock)
    );

    // Clock generation
    initial begin
        clock = 0;
        forever begin
            #(HALF_CYCLE_NS) clock = ~clock;
        end
    end

    // Stimulus
    initial begin
        in         = 16'd0;
        load       = LOAD_VALUE;
        load_en    = 1'b0;
        rst        = 1'b0;
        expected   = 16'd0;
        cycle_count = 0;

        $display("time(ns) cycle rst load_en load expected out");
        $monitor("%0t %0d %b %b %0d %0d %0d", $time, cycle_count, rst, load_en, load, expected, out);

        wait (clock == 1'b1);
        @(posedge clock);

        while (cycle_count < TOTAL_CYCLES) begin
            // default stimulus
            in = in + 16'd1;
            load = LOAD_VALUE;

            // reset active for one cycle at RESET_CYCLE
            if (cycle_count == RESET_CYCLE) begin
                rst = 1'b1;
            end else begin
                rst = 1'b0;
            end

            // load active for one cycle at LOAD_CYCLE
            if (cycle_count == LOAD_CYCLE) begin
                load_en = 1'b1;
            end else begin
                load_en = 1'b0;
            end

            // compute expected value for next cycle
            if (rst) begin
                expected = 16'h0;
            end else if (load_en) begin
                expected = load;
            end else begin
                expected = expected + in;
            end

            @(posedge clock);

            // check output after clock edge
            if (out !== expected) begin
                $error("Mismatch at cycle %0d: expected=%0d out=%0d", cycle_count, expected, out);
            end

            cycle_count++;
        end

        # (CYCLE_TIME_NS);
        $display("Simulation complete after %0d cycles", TOTAL_CYCLES);
        $finish;
    end

endmodule
