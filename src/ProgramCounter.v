module ProgramCounter #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire inc,   
    output wire [WIDTH-1:0]  pc
);

    wire [WIDTH-1:0] next_pc = inc 
                               ? (pc + {{WIDTH-1{1'b0}}, 1'b1}) 
                               : pc;

    Register #(.WIDTH(WIDTH)) pc_reg (
        .clk(clk),
        .rst(rst),
        .d(next_pc),
        .q(pc)
    );

endmodule
