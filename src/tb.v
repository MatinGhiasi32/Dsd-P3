`timescale 1ns/1ps

module tb;
    // Parameters
    localparam DATA_WIDTH = 16;
    localparam ADDR_WIDTH = 16;
    localparam CLK_PERIOD = 10;

    // Clock and reset
    reg clk, rst;

    // Instantiate the CPU (only clk & rst ports)
    CPU #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) cpu (
        .clk(clk),
        .rst(rst)
    );

    // Drive the clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    integer i;
    initial begin
        rst = 1;
        #CLK_PERIOD;
    
        // Clear RAM
        for (i = 0; i < 256; i = i+1)
            cpu.ram.mem[i] = 0;

        // Prepare data at addresses ≥100
        force cpu.ram.mem[100] = 16'd5;
        force cpu.ram.mem[101] = 16'd7;

        // 4) Force instructions into RAM starting at cell 3
        force cpu.ram.mem[3]  = 16'b100_01_00_001100100; // LOAD R1 ← M[100]
        force cpu.ram.mem[4]  = 16'b100_10_00_001100101; // LOAD R2 ← M[101]
        force cpu.ram.mem[5]  = 16'b010_11_01_10_0000000; // MUL  R3 ← R1 * R2
        force cpu.ram.mem[6]  = 16'b001_00_10_01_0000000; // SUB  R0 ← R2 - R1
        force cpu.ram.mem[7]  = 16'b101_11_11_001100100; // STR  M[R3 + 100] ← R3
        force cpu.ram.mem[8]  = 16'b100_01_11_001100100; // LOAD R1 ← M[ R3+100 = 135 ]
        force cpu.ram.mem[9] = 16'b001_10_01_00_0000000; // SUB  R2 ← R1 - R0
        force cpu.ram.mem[10] = 16'h0000;                // NO-OP
        force cpu.ram.mem[11] = 16'b000_11_10_00_0000000; // ADD  R3 ← R2 + R0
        force cpu.ram.mem[12] = 16'b011_10_11_00_0000000; // DIV  R2 ← R3 / R0

        // Release reset
        # (2 * CLK_PERIOD); 
        rst = 0;

        # (150 * CLK_PERIOD);


        $display("=== Final Register File ===");
        $display("R0 = %0d (expected = 2)", cpu.RF.x0.q);
        $display("R1 = %0d (expected = 35)", cpu.RF.x1.q);
        $display("R2 = %0d (expected = 17)", cpu.RF.x2.q);
        $display("R3 = %0d (expected = 35)", cpu.RF.x3.q);

        $display("=== Final Data RAM ===");
        $display("RAM[100] = %0d (expected = 5)",   cpu.ram.mem[100]);
        $display("RAM[101] = %0d (expected = 7)",   cpu.ram.mem[101]);
        $display("RAM[135] = %0d (expected = 35)",  cpu.ram.mem[135]);
        $stop;
    end


endmodule
