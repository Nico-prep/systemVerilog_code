`timescale 1ns/1ps

module counter_tb;

    // Parameters for easy modification
    parameter int CYCLE_TIME_NS   = 10;      // 100 MHz clock
    parameter int HALF_CYCLE_NS   = CYCLE_TIME_NS / 2;
    parameter int TOTAL_CYCLES    = 400;
    parameter int RESET_CYCLE     = 50;
    parameter int TOGGLE_ENABLE_0  = 10;
    parameter int TOGGLE_ENABLE_1  = 100;
    parameter int TOGGLE_ENABLE_2  = 160;
    parameter int TOGGLE_ENABLE_3  = 380;
   
   // I/O for the uut (see uut)
    logic       enable;
    logic       rst;
    logic       clock;
    logic [7:0] out;

// assign I/O to ports
    counter uut (
        .enable(enable),
        .rst(rst),
        .clock(clock),
        .count_value(out)
    );


    logic [7:0] expected;
    int cycle_count;

    initial begin
        $dumpfile("build/counter_tb.vcd");
        $dumpvars(0, counter_tb);
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

        enable               = 1'b0;
        rst                  = 1'b1;   // start in reset for deterministic initialization
        expected             = 0;
        cycle_count          = 0;

        $display("running counter TB");
        $display("time(ns) cycle rst enable expected out");
        $monitor("%0t %0d %b %b %0d %0d", $time, cycle_count, rst, enable, expected, out);

        wait (clock == 1'b1);
        @(posedge clock);

        while (cycle_count < TOTAL_CYCLES) begin
            

            // reset active for one cycle at RESET_CYCLE
            if (cycle_count == RESET_CYCLE) begin
                rst = 1'b1;
            end else begin
                rst = 1'b0;
            end

            // toggle enable
            if ((cycle_count == TOGGLE_ENABLE_0) || (cycle_count == TOGGLE_ENABLE_1) ||(cycle_count == TOGGLE_ENABLE_2) || (cycle_count == TOGGLE_ENABLE_3) ) begin
                enable = ~enable;
            end

            // compute expected value for next cycle
            if (rst) begin
                expected = 0;
            end else if (enable) begin
                expected = expected + 1;
            end

            @(posedge clock);

            // check output after clock edge
            if (out !== expected)  
                $error("Mismatch at cycle %0d: expected=%0d / out=%0d",cycle_count, expected,  out);

            cycle_count++;
        end

        # (CYCLE_TIME_NS);
        $display("Simulation complete after %0d cycles", TOTAL_CYCLES);
        $finish;
    end

endmodule
