module CarrySelectAdder #(parameter N = 16, BLOCK = 4) (
    input  [N-1:0] a, b,
    input          cin,
    output [N-1:0] sum,
    output         cout
);
    localparam NUM_BLOCKS = N / BLOCK;

    wire [NUM_BLOCKS:0] carry;
    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin : BLOCKS
            wire [BLOCK-1:0] sum0, sum1;
            wire             cout0, cout1;

            wire [BLOCK-1:0] a_block = a[i*BLOCK +: BLOCK];
            wire [BLOCK-1:0] b_block = b[i*BLOCK +: BLOCK];

            if (i == 0) begin
                RippleCarryAdder #(BLOCK) rca (
                    .a    (a_block),
                    .b    (b_block),
                    .cin  (carry[i]),
                    .sum  (sum[i*BLOCK +: BLOCK]),
                    .cout (carry[i+1])
                );
            end else begin
                RippleCarryAdder #(BLOCK) rca0 (
                    .a    (a_block),
                    .b    (b_block),
                    .cin  (1'b0),
                    .sum  (sum0),
                    .cout (cout0)
                );

                RippleCarryAdder #(BLOCK) rca1 (
                    .a    (a_block),
                    .b    (b_block),
                    .cin  (1'b1),
                    .sum  (sum1),
                    .cout (cout1)
                );

                mux #(BLOCK) sum_mux (
                    .sel   (carry[i]),
                    .a     (sum0),
                    .b     (sum1),
                    .y     (sum[i*BLOCK +: BLOCK])
                );

                mux #(1) cout_mux (
                    .sel   (carry[i]),
                    .a     (cout0),
                    .b     (cout1),
                    .y     (carry[i+1])
                );
            end
        end
    endgenerate

    assign cout = carry[NUM_BLOCKS];
endmodule
