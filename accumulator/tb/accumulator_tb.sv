`timescale 1ns/1ps

module accumulator_tb;

    // Parameters for easy modification
    parameter int CYCLE_TIME_NS   = 10;      // 100 MHz clock
    parameter int HALF_CYCLE_NS   = CYCLE_TIME_NS / 2;
    parameter int TOTAL_CYCLES    = 200;
    parameter int RESET_CYCLE     = 50;
    parameter int LOAD_CYCLE      = 100;
    parameter int LOAD_VALUE      = 16'hFFFE - 300; // Value below the 16-bit max for a safe load

    logic [15:0] in;
    logic [15:0] load;
    logic        load_en;
    logic        rst;
    logic        clock;
    logic [15:0] out;
    logic        ovl_det;

    logic [15:0] expected;
    logic        expected_ovl_det;
    int cycle_count;

    accumulator uut (
        .in(in),
        .load(load),
        .load_en(load_en),
        .rst(rst),
        .out(out),
        .ovl_det(ovl_det),
        .clock(clock)
    );

    initial begin
        $dumpfile("build/accumulator_tb.vcd");
        $dumpvars(0, accumulator_tb);
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
        in         = 16'd0;
        load       = LOAD_VALUE;
        load_en    = 1'b0;
        rst        = 1'b1;   // start in reset for deterministic initialization
        expected   = 17'd0;
        expected_ovl_det = 1'b0;
        cycle_count = 0;

        $display("time(ns) cycle rst load_en load in expected out ovl_det");
        $monitor("%0t %0d %b %b %0d %0d %0d %0d %b", $time, cycle_count, rst, load_en, load, in, expected, out, expected_ovl_det);

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
                expected = 17'h0;
                expected_ovl_det = 1'b0;
            end else if (load_en) begin
                expected = load;
                expected_ovl_det = 1'b0;
            end else begin
                if (expected_ovl_det) begin
                    $display("overload condition");
                    expected = 17'hFFFF;
                    expected_ovl_det = 1'b1;
                end else if (expected + in > 17'hFFFF) begin
                    $display("overload expected");
                    expected = 17'hFFFF;
                    expected_ovl_det = 1'b1;
                end else begin
                    $display("overload not expected");
                    expected = expected + in;
                    expected_ovl_det = 1'b0;
                end
            end

            @(posedge clock);

            // check output after clock edge
            if ((out !== expected) || (ovl_det !== expected_ovl_det)) begin
                $error("Mismatch at cycle %0d: expected=%0d/ovl=%0b out=%0d/ovl=%0b",
                       cycle_count, expected, expected_ovl_det, out, ovl_det);
            end

            cycle_count++;
        end

        # (CYCLE_TIME_NS);
        $display("Simulation complete after %0d cycles", TOTAL_CYCLES);
        $finish;
    end

endmodule
