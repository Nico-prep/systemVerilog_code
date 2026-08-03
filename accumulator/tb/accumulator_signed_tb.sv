`timescale 1ns/1ps

module accumulator_tb;

    // Parameters for easy modification
    parameter int CYCLE_TIME_NS   = 10;      // 100 MHz clock
    parameter int HALF_CYCLE_NS   = CYCLE_TIME_NS / 2;
    parameter int TOTAL_CYCLES    = 200;
    parameter int RESET_CYCLE     = 50;
    parameter int LOAD_CYCLE      = 100;
    parameter int LOAD_VALUE      = 10000; 
    parameter int SWAP_SIGN_CYCLE = 120;

    logic signed [15:0] in;
    logic signed [15:0] load;
    logic        load_en;
    logic        rst;
    logic        clock;
    logic signed [15:0] out;
    logic        ovl_det_pos;
    logic        ovl_det_neg;
    logic        input_sign_plus;


    accumulator_signed uut (
        .in(in),
        .load(load),
        .load_en(load_en),
        .rst(rst),
        .clock(clock),
        .out(out),
        .ovl_det_pos(ovl_det_pos),
        .ovl_det_neg(ovl_det_neg)
    );


    logic signed [16:0] expected;
    logic        expected_ovl_det_pos;
    logic        expected_ovl_det_neg;
    int cycle_count;

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
        in                   = 16'd0;
        load                 = LOAD_VALUE;
        load_en              = 1'b0;
        rst                  = 1'b1;   // start in reset for deterministic initialization
        input_sign_plus      = 1'b0;
        expected             = 17'd0;
        expected_ovl_det_pos = 1'b0;
        expected_ovl_det_neg = 1'b0;
        cycle_count          = 0;

        $display("running signed TB");
        $display("time(ns) cycle rst load_en load in expected expected_ovl_det_pos expected_ovl_det_neg out ovl_det_pos ovl_det_neg");
        $monitor("%0t %0d %b %b %0d %0d %0d %b %b %0d %b %b", $time, cycle_count, rst, load_en, load, in, expected, expected_ovl_det_pos, expected_ovl_det_neg, out, ovl_det_pos, ovl_det_neg);

        wait (clock == 1'b1);
        @(posedge clock);

        while (cycle_count < TOTAL_CYCLES) begin
            
            // default stimulus
            if (input_sign_plus) begin
                in = in + 16'd1;
            end else begin
                in = in - 16'd1;
            end
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

            // change input sign for signed accumulator
            if (cycle_count == SWAP_SIGN_CYCLE) begin
                input_sign_plus = ~input_sign_plus;
            end

            // compute expected value for next cycle
            if (rst) begin
                expected = 17'h0;
                expected_ovl_det_pos = 1'b0;
                expected_ovl_det_neg = 1'b0;
            end else if (load_en) begin
                expected = load;
                expected_ovl_det_pos = 1'b0;
                expected_ovl_det_neg = 1'b0;
            end else begin
                if (expected_ovl_det_pos) begin
                    $display("positive overload condition");
                    expected = 17'h7FFF;
                    expected_ovl_det_pos = 1'b1;
                    expected_ovl_det_neg = 1'b0;
                end else  if (expected_ovl_det_neg) begin
                    $display("negative overload condition");
                    expected = 17'h8000;
                    expected_ovl_det_pos = 1'b0;
                    expected_ovl_det_neg = 1'b1;    
                end else if (expected + in > 17'sh7FFF) begin
                    $display("overload expected");
                    expected = 17'sh7FFF;
                    expected_ovl_det_pos = 1'b1;
                    expected_ovl_det_neg = 1'b0;
                end else if (expected + in < 17'sh10000) begin
                    $display("overload expected");
                    expected = 17'sh10000;
                    expected_ovl_det_pos = 1'b0;
                    expected_ovl_det_neg = 1'b1;
                end else begin
                    $display("overload not expected");
                    expected = expected + in;
                    expected_ovl_det_pos = 1'b0;
                    expected_ovl_det_neg = 1'b0;
                end
            end

            @(posedge clock);

            // check output after clock edge
            if ((out !== expected) || (ovl_det_pos !== expected_ovl_det_pos) || (ovl_det_neg !== expected_ovl_det_neg)) begin
                $error("Mismatch at cycle %0d: expected=%0d/ovl_pos=%0b/ovl_neg=%0b out=%0d/ovl_pos=%0b/ovl_neg=%0b",
                       cycle_count, expected, expected_ovl_det_pos,expected_ovl_det_neg, out, ovl_det_pos, ovl_det_neg);
            end

            cycle_count++;
        end

        # (CYCLE_TIME_NS);
        $display("Simulation complete after %0d cycles", TOTAL_CYCLES);
        $finish;
    end

endmodule
