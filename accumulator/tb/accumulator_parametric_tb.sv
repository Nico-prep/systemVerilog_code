`timescale 1ns/1ps

module accumulator_parametric_tb;

    // Parameters for easy modification
    parameter int WIDTH  = 5;
    parameter int CYCLE_TIME_NS   = 10;      // 100 MHz clock
    parameter int HALF_CYCLE_NS   = CYCLE_TIME_NS / 2;
    parameter int TOTAL_CYCLES    = 400;
    parameter int RESET_CYCLE     = 50;
    parameter int LOAD_CYCLE_1      = 100;
    parameter int LOAD_CYCLE_2      = 200;
    parameter int SWAP_SIGN_CYCLE = 150;

    int MAX_VAL = (1 << (WIDTH-1)) - 1;
    int MIN_VAL = - (1 << (WIDTH-1));
    // values to drive onto `in` immediately after loading 
    int LOAD_VALUE_1 = MAX_VAL - 3;
    int LOAD_VALUE_2 = MIN_VAL + 4;

    logic signed [WIDTH-1:0] in;
    logic signed [WIDTH-1:0] load;
    logic        load_en;
    logic        rst;
    logic        clock;
    logic signed [WIDTH-1:0] out;
    logic        ovl_det_pos;
    logic        ovl_det_neg;
    logic        input_sign_plus;


    accumulator_parametric #(
        .WIDTH(WIDTH)
    ) uut (
        .in(in),
        .load(load),
        .load_en(load_en),
        .rst(rst),
        .clock(clock),
        .out(out),
        .ovl_det_pos(ovl_det_pos),
        .ovl_det_neg(ovl_det_neg)
    );


    int signed   expected;
    int signed   next;
    logic        expected_ovl_det_pos;
    logic        expected_ovl_det_neg;
    int          cycle_count;

    initial begin
        $dumpfile("build/accumulator_parametric_tb.vcd");
        $dumpvars(0, accumulator_parametric_tb);
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
        in                   = 0;
        load                 = LOAD_VALUE_1;
        load_en              = 1'b0;
        rst                  = 1'b1;   // start in reset for deterministic initialization
        input_sign_plus      = 1'b1;
        expected             = 0;
        next = 0;
        expected_ovl_det_pos = 1'b0;
        expected_ovl_det_neg = 1'b0;
        cycle_count          = 0;

        $display("running parametric TB");
        $display("time(ns) cycle rst load_en load in expected expected_ovl_det_pos expected_ovl_det_neg out ovl_det_pos ovl_det_neg");
        $monitor("%0t %0d %b %b %0d %0d %0d %b %b %0d %b %b", $time, cycle_count, rst, load_en, load, in, expected, expected_ovl_det_pos, expected_ovl_det_neg, out, ovl_det_pos, ovl_det_neg);

        wait (clock == 1'b1);
        @(posedge clock);

        while (cycle_count < TOTAL_CYCLES) begin
            
            // default stimulus: set base load (may be overridden below)
            load = LOAD_VALUE_1;
            if (input_sign_plus) begin
                in = in + 1'd1;
            end else begin
                in = in - 1'd1;
            end

            // reset active for one cycle at RESET_CYCLE
            if (cycle_count == RESET_CYCLE) begin
                rst = 1'b1;
            end else begin
                rst = 1'b0;
            end

            // load active for one cycle at LOAD_CYCLE_1 or LOAD_CYCLE_2
            if ((cycle_count == LOAD_CYCLE_1) || (cycle_count == LOAD_CYCLE_2)) begin
                load_en = 1'b1;
                if (cycle_count == LOAD_CYCLE_2) begin
                    load = LOAD_VALUE_2;
                end
            end else begin
                load_en = 1'b0;
            end

            // change input sign for signed accumulator
            if (cycle_count == SWAP_SIGN_CYCLE) begin
                input_sign_plus = ~input_sign_plus;
                in = ~in +1;
            end

            // compute expected value for next cycle
            if (rst) begin
                expected = 0;
                expected_ovl_det_pos = 1'b0;
                expected_ovl_det_neg = 1'b0;
            end else if (load_en) begin
                expected = load; 
                expected_ovl_det_pos = 1'b0;
                expected_ovl_det_neg = 1'b0;
            end else begin
                next = expected+$signed(in);
                expected_ovl_det_pos = 1'b0;
                expected_ovl_det_neg = 1'b0;
                if (next > MAX_VAL) begin
                    $display("overload expected");
                    expected = MAX_VAL;
                    expected_ovl_det_pos = 1'b1;
                    expected_ovl_det_neg = 1'b0;
                end else if (next < MIN_VAL) begin
                    $display("overload expected");
                    expected = MIN_VAL;
                    expected_ovl_det_pos = 1'b0;
                    expected_ovl_det_neg = 1'b1;  
                end else  begin

                    expected = next;

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
