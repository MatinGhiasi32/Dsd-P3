module ALU #(
    parameter WIDTH = 16
) (
    input  [2:0]           opcode,    // 000 = ADD, 001 = SUB, 100 = LOAD, 101 = STR
    input  [WIDTH-1:0]     a,
    input  [WIDTH-1:0]     b,
    output reg [WIDTH-1:0] result    
);

    wire [WIDTH-1:0] result_sum;
    wire [WIDTH-1:0] result_sub;

    // ADD, LOAD, STR
    CarrySelectAdder csa (
        .a    (a),
        .b    (b),
        .cin  (1'b0),
        .sum  (result_sum),
        .cout ()
    );

    // SUB
    BorrowSelectSubtractor bss (
        .a     (a),
        .b     (b),
        .cin   (1'b0),
        .diff  (result_sub),
        .cout  ()
    );

    // ALU operation selection
    always @(*) begin
        case (opcode)
            3'b000, 3'b100, 3'b101: result = result_sum;  // ADD / LOAD / STR
            3'b001:                result = result_sub;   // SUB
            default:               result = {WIDTH{1'b0}};
        endcase
    end

endmodule
