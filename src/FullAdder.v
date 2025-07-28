module FullAdder (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin; // Sum is the XOR of a, b, and cin
    assign cout = (a & b) | (cin & (a ^ b)); // Carry out is generated if any two inputs are high

endmodule