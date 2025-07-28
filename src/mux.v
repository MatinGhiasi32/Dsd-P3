module mux #(parameter size = 16) (
    input  wire [size-1:0] a,
    input  wire [size-1:0] b,
    input  wire           sel,
    output wire [size-1:0] y
);
    assign y = sel ? b : a;
endmodule