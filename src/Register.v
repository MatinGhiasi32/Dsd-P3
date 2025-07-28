module Register #(parameter WIDTH = 16) (
    input  clk,
    input  rst,
    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else begin
            q <= d;
        end
    end
endmodule