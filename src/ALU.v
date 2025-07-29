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

    reg [31:0] mul_result; 

    // ALU operation selection
    always @(*) begin
        mul_result = a * b;
        case (opcode)
            3'b000, 3'b100, 3'b101: result = result_sum;  // ADD / LOAD / STR
            3'b001:                result = result_sub;   // SUB
            3'b010:                result = mul_result[15:0]; // MUL
            3'b011:                 result = (b != 0) ? (a / b) : {WIDTH{1'b0}}; // DIV
            default:               result = {WIDTH{1'b0}};
        endcase
    end

endmodule
