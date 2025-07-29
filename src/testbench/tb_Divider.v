`timescale 1ns/1ps

module tb_Divider;
    // Parameters
    localparam CLK_PERIOD = 10;

    // Inputs to the DUT
    reg         clk;
    reg         rst;
    reg         start;
    reg  [31:0] dividend;
    reg  [15:0] divisor;

    // Outputs from the DUT
    wire [31:0] quotient;
    wire [15:0] remainder;
    wire        done;

    // Instantiate the divider
    Divider dut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .dividend  (dividend),
        .divisor   (divisor),
        .quotient  (quotient),
        .remainder (remainder),
        .done      (done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Helper task to run one division test
    task run_div_test(
        input [15:0] a, 
        input [15:0] b
    );
        integer exp_q, exp_r;
    begin
        // zero-extend a into the 32-bit dividend port
        dividend = {16'b0, a};
        divisor  = b;
        // compute expected results (in Verilog integer arithmetic)
        exp_q = a / b;
        exp_r = a % b;

        // pulse start for one cycle
        start = 1;
        @(posedge clk);
        start = 0;

        // wait for done
        @(posedge clk);
        while (!done)
            @(posedge clk);
        # (35 * CLK_PERIOD)
        // display
        $display("DIVIDE %0d / %0d => Q=%0d, R=%0d    (exp Q=%0d, R=%0d)",
                  a, b,
                  quotient, remainder,
                  exp_q, exp_r);
    end
    endtask

    // Test sequence
    initial begin
        rst = 1;
        start = 0;
        # (2*CLK_PERIOD);
        rst = 0;

        run_div_test(16'd35,   16'd2);
        run_div_test(16'd100,  16'd3);
        run_div_test(16'd65535,16'd255);
        run_div_test(16'd1234, 16'd123);
        run_div_test(16'd0,    16'd7);
        run_div_test(16'd7,    16'd16);

        $display("All tests done.");
        $stop;
    end

endmodule
