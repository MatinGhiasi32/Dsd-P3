`timescale 1ns/1ps

module tb_MultShiftAdd;
    // Parameters
    localparam WIDTH      = 16;
    localparam CLK_PERIOD = 10;

    // Inputs to DUT
    reg                     clk, rst, start;
    reg      [WIDTH-1:0]    a, b;
    // Outputs from DUT
    wire [2*WIDTH-1:0]      product;
    wire                    done;

    // Instantiate DUT
    MultShiftAdd #(.WIDTH(WIDTH)) dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .a        (a),
        .b        (b),
        .product  (product),
        .done     (done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task to run a single multiplication test
    task run_test;
        input [WIDTH-1:0] in_a, in_b;
        input [2*WIDTH-1:0] exp;
        begin
            // apply inputs
            @(negedge clk);
            a     = in_a;
            b     = in_b;
            start = 1;
            @(negedge clk);
            start = 0;

            // wait for completion
            wait(done);

            // give one more clock for product to settle
            @(negedge clk);

            // display results
            $display("a = %0d, b = %0d, expected = %0d, actual = %0d",
                     in_a, in_b, exp, product);
        end
    endtask

    // Test sequence
    initial begin
        rst   = 1;
        start = 0;
        a     = 0;
        b     = 0;
        #(2*CLK_PERIOD);
        rst = 0;

        // Run multiple tests
        run_test(16'd3,     16'd4,     32'd12);
        run_test(16'd0,     16'd123,   32'd0);
        run_test(16'd255,   16'd255,   32'd65025);
        run_test(16'd10,    16'd20,    32'd200);
        run_test(16'd123,   16'd456,   32'd56088);
        run_test(16'd1023,  16'd1023,  32'd1046529);
        run_test(16'd1,     16'hFFFF,  32'd65535);
        run_test(16'd30000, 16'd2,     32'd60000);

        $stop;
    end

endmodule
