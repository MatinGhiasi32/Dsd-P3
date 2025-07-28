module Karatsuba (
    input               clk,
    input               rst,
    input               start,
    input  [15:0]       a,
    input  [15:0]       b,
    output reg [31:0]   product,
    output reg          done
);

    // Split parameters
    parameter W = 16;
    parameter H = 8;
    parameter SW = 9;

    // Wires for splitting a and b
    wire [H-1:0] a_L = a[H-1:0];
    wire [H-1:0] a_H = a[W-1:H];
    wire [H-1:0] b_L = b[H-1:0];
    wire [H-1:0] b_H = b[W-1:H];

    // Sums and z1
    reg  [SW-1:0] sumA, sumB;
    wire [2*H-1:0] z0, z2;
    wire [2*SW-1:0] z1_raw;
    wire [2*SW:0]   z1_result; 

    // FSM states
    localparam S_IDLE      = 3'd0;
    localparam S_DO_Z0     = 3'd1;
    localparam S_DO_Z2     = 3'd2;
    localparam S_COMP_SUMS = 3'd3;  
    localparam S_DO_Z1     = 3'd4;
    localparam S_COMBINE   = 3'd5;
    localparam S_FINISH    = 3'd6;

    reg [2:0] state, next;

    // Multiplier control
    reg start0, start1, start2;
    wire done0, done1, done2;

    // Instantiate three small multipliers
    MultShiftAdd #(.WIDTH(H)) mul0 (
        .clk(clk), .rst(rst), .start(start0),
        .a(a_L), .b(b_L), .product(z0), .done(done0)
    );

    MultShiftAdd #(.WIDTH(H)) mul2 (
        .clk(clk), .rst(rst), .start(start2),
        .a(a_H), .b(b_H), .product(z2), .done(done2)
    );

    MultShiftAdd #(.WIDTH(SW)) mul1 (
        .clk(clk), .rst(rst), .start(start1),
        .a(sumA), .b(sumB), .product(z1_raw), .done(done1)
    );

    // Compute z1 result combinatorially
    assign z1_result = z1_raw - z2 - z0;

    // FSM transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            product <= 0;
            done <= 0;
        end else begin
            state <= next;
        end
    end

    // FSM logic
    always @(*) begin
        // Defaults
        start0 = 0;
        start1 = 0;
        start2 = 0;
        done = 0;
        next = state;

        case (state)
            S_IDLE:
                if (start) next = S_DO_Z0;

            S_DO_Z0: begin
                start0 = 1;
                if (done0) next = S_DO_Z2;
            end

            S_DO_Z2: begin
                start2 = 1;
                if (done2) next = S_COMP_SUMS;  // Go to sum computation
            end
            
            // NEW STATE: Compute sums
            S_COMP_SUMS: begin
                next = S_DO_Z1;
            end

            S_DO_Z1: begin
                start1 = 1;
                if (done1) next = S_COMBINE;
            end

            S_COMBINE: begin
                next = S_FINISH;
            end

            S_FINISH: begin
                done = 1;
                if (!start) next = S_IDLE;
            end
        endcase
    end

    // Compute sumA and sumB - NOW IN CORRECT STATE
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sumA <= 0;
            sumB <= 0;
        end else if (state == S_DO_Z2 && done2) begin  // Compute when z2 is done
            sumA <= a_L + a_H;
            sumB <= b_L + b_H;
        end
    end

    // Compute final product in COMBINE state
    always @(posedge clk) begin
        if (state == S_COMBINE) begin
            // Proper shifts and combination:
            // product = z2 * 2^(2H) + z1 * 2^H + z0
            product <= (z2 << (2*H)) + 
                       (z1_result << H) + 
                       z0;
        end
    end

endmodule