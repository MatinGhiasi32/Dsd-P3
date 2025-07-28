`timescale 1ns/1ps

module ALU_tb;

    // Parameters
    localparam WIDTH      = 16;
    localparam CLK_PERIOD = 10;
    // Approximate latency of Karatsuba (in cycles)
    localparam MUL_LATENCY = 22;

    // Inputs to DUT
    reg                   clk, rst, start;
    reg        [2:0]      opcode;
    reg  [WIDTH-1:0]      a, b;
    // Output from DUT
    wire [WIDTH-1:0]      result;

    // Instantiate the ALU with new interface
    ALU #(.WIDTH(WIDTH)) dut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .opcode (opcode),
        .a      (a),
        .b      (b),
        .result (result)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task to run a combinational test (ADD/SUB/LOAD/STR)
    task run_comb;
        input [2:0] op;
        input [WIDTH-1:0] in1, in2, exp;
        begin
            @(negedge clk);
            opcode = op;
            a      = in1;
            b      = in2;
            start  = 1;
            @(negedge clk);
            start  = 0;
            //(combinational) result ready next cycle
            @(negedge clk);
            $display("OP=%b A=%0d B=%0d => R=%0d (exp=%0d)", op, in1, in2, result, exp);
        end
    endtask

    // Task to run a multiply test (MUL)
    task run_mul;
        input [WIDTH-1:0] in1, in2;
        input [WIDTH-1:0] exp_lo;
        begin
            @(negedge clk);
            opcode = 3'b010;
            a      = in1;
            b      = in2;
            start  = 1;
            @(negedge clk);
            start  = 0;
            // wait worst-case latency
            // repeat (MUL_LATENCY) @(negedge clk);
            wait (dut.kar.done); // wait for Karatsuba to finish
            # (2 * CLK_PERIOD); // allow time for result to stabilize
            $display("OP=010 A=%0d B=%0d => R=%0d (exp=%0d)", in1, in2, result, exp_lo);
        end
    endtask

    initial begin
        // Initialize
        rst   = 1;
        start = 0;
        opcode= 0;
        a = 0; b = 0;
        // hold reset for two cycles
        repeat (2) @(negedge clk);
        rst = 0;

        $display("=== ALU Extended Testbench ===");

        // Combinational ops
        run_comb(3'b000, 28, 22, 50);      // ADD
        run_comb(3'b001,  6,  8, -2);      // SUB (signed)
        run_comb(3'b100, 10, 32, 42);      // LOAD-like
        run_comb(3'b101,  2, 40, 42);      // STR-like

        // Multiply tests
        run_mul(16'd3,     16'd4,     16'd12);
        run_mul(16'd0,     16'd123,   16'd0);
        run_mul(16'd255,   16'd255,   16'd65025);
        run_mul(16'd10,    16'd20,    16'd200);
        run_mul(16'd123,   16'd456,   16'd56088);

        $stop;
    end

endmodule
