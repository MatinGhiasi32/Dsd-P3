module BorrowSelectSubtractor #(parameter N = 16) (
    input  [N-1:0] a, b,
    input          cin,
    output [N-1:0] diff,
    output         cout
);
    wire [N-1:0] b_complement;
    assign b_complement = ~b + 1;
    CarrySelectAdder #(N) csa (
        .a    (a),
        .b    (b_complement),
        .cin  (cin),
        .sum  (diff),
        .cout (cout)
    );
endmodule 
