module Karatsuba_tb;
    reg clk, rst, start;
    reg [15:0] a, b;
    wire [31:0] product;
    wire done;

    Karatsuba uut (
        .clk(clk), .rst(rst), .start(start),
        .a(a), .b(b), .product(product), .done(done)
    );

    // Clock
    parameter CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    task run_test;
        input [15:0] val_a, val_b;
        input [31:0] expected;
        begin
            @(negedge clk);
            a = val_a;
            b = val_b;
            start = 1;
            @(negedge clk);
            start = 0;

            wait (done);

            @(negedge clk);
            $display("a = %0d, b = %0d, Expected = %0d, Actual = %0d", 
                     val_a, val_b, expected, product);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        a = 0;
        b = 0;

        #(2 * CLK_PERIOD);
        rst = 0;

        // Run test cases
        run_test(16'd3, 16'd4, 32'd12);
        run_test(16'd0, 16'd123, 32'd0);
        run_test(16'd255, 16'd255, 32'd65025);
        run_test(16'd10, 16'd20, 32'd200);
        run_test(16'd123, 16'd456, 32'd56088);
        run_test(16'd1023, 16'd1023, 32'd1046529);
        run_test(16'd1, 16'd65535, 32'd65535);
        run_test(16'd30000, 16'd2, 32'd60000);

        $stop;
    end
endmodule
