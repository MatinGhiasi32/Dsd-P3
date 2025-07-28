module Karatsuba (
    input               clk,
    input               rst,
    input               start,
    input      [15:0]   a,
    input      [15:0]   b,
    output reg [31:0]   product,
    output reg          done
);

    // Split parameters
    parameter W  = 16;          // input width
    parameter H  = 8;           // half width
    parameter SW = H + 1;       // sum width = H+1 bits

    // Split a and b into high/low halves
    wire [H-1:0] a_L = a[H-1:0];
    wire [H-1:0] a_H = a[W-1:H];
    wire [H-1:0] b_L = b[H-1:0];
    wire [H-1:0] b_H = b[W-1:H];

    // Combinational sums for the "middle" product
    wire [SW-1:0] sumA = a_L + a_H;
    wire [SW-1:0] sumB = b_L + b_H;

    // Partial products
    wire [2*H-1:0]    z0;
    wire [2*H-1:0]    z2;
    wire [2*SW-1:0]   z1_raw;
    reg  [2*SW+W-1:0] z1;  // enough bits to hold z1_raw - z2 - z0 without overflow

    // FSM states
    localparam S_IDLE    = 3'd0;
    localparam S_DO_Z0   = 3'd1;
    localparam S_DO_Z2   = 3'd2;
    localparam S_DO_Z1   = 3'd3;
    localparam S_COMBINE = 3'd4;
    localparam S_FINISH  = 3'd5;

    reg [2:0] state, next;

    // Multiplier control signals
    reg  start0, start1, start2;
    wire done0, done1, done2;

    // Instantiate three shift‑and‑add multipliers
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

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next;
    end

    // Next‑state logic & start‑signals
    always @(*) begin
        // defaults
        next   = state;
        start0 = 1'b0;
        start1 = 1'b0;
        start2 = 1'b0;
        done   = 1'b0;

        case (state)
            S_IDLE:
                if (start) next = S_DO_Z0;

            S_DO_Z0: begin
                start0 = 1'b1;
                if (done0) next = S_DO_Z2;
            end

            S_DO_Z2: begin
                start2 = 1'b1;
                if (done2) next = S_DO_Z1;
            end

            S_DO_Z1: begin
                start1 = 1'b1;
                if (done1) next = S_COMBINE;
            end

            S_COMBINE:
                next = S_FINISH;

            S_FINISH: begin
                done = 1'b1;
                if (!start)
                    next = S_IDLE;
            end
        endcase
    end

    // Combine partial products once all three are done
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            z1      <= 0;
            product <= 0;
        end else if (state == S_COMBINE) begin
            // z1 = (a_L + a_H)*(b_L + b_H) - z2 - z0
            z1      <= z1_raw - z2 - z0;
            // product = z2*2^W + z1*2^H + z0
            product <= (z2 << W) | (z1 << H) | z0;
        end
    end

endmodule
