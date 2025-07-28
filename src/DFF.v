module DFF #(parameter size = 16) (
    input wire clk,
    input wire reset,
    input wire [size-1:0] d,
    output reg [size-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end

endmodule