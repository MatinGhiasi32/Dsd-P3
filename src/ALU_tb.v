`timescale 1ns/1ps

module ALU_tb;

    // Parameters
    localparam WIDTH = 16;

    // Test inputs
    reg  [2:0]           opcode;
    reg  [WIDTH-1:0]     a, b;
    wire [WIDTH-1:0]     result;

    // Instantiate the ALU
    ALU #(
        .WIDTH(WIDTH)
    ) dut (
        .opcode (opcode),
        .a      (a),
        .b      (b),
        .result (result)
    );

    // Task to run a test
    task run_test;
        input [2:0] op;
        input [WIDTH-1:0] in1, in2;
        input [WIDTH-1:0] exp;
        begin
            opcode = op;
            a = in1;
            b = in2;
            #1; // small delay for result to settle
            $display("OPCODE = %b | A = %0d | B = %0d | RESULT = %0d", op, in1, in2, $signed(result));
        end
    endtask

    initial begin
        $display("=== ALU Testbench ===");

        // Test ADD (opcode 000)
        run_test(3'b000, 16'd28, 16'd22, 16'd42);

        // Test SUB (opcode 001)
        run_test(3'b001, 16'd6, 16'd8,  16'd42);

        // Test SUB (opcode 001)
        run_test(3'b001, 16'd100, 16'd8,  16'd42);

        // Test LOAD-like ADD (opcode 100)
        run_test(3'b100, 16'd10, 16'd32, 16'd42);

        // Test STR-like ADD (opcode 101)
        run_test(3'b101, 16'd2,  16'd40, 16'd42);
        $stop;
    end

endmodule
