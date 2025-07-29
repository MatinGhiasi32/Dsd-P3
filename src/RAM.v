module RAM (
    input wire [15:0] readAddress,
    input wire [15:0] writeAddress,
    input wire [15:0] writeValue,
    input wire clk, 
    input wire readEnable,
    input wire writeEnable,
    output reg [15:0] readValue
);

    reg [15:0] mem [0:255];

    always @(*) begin
        if (readEnable) begin
            readValue = mem[readAddress];
        end
    end
    
    always @(posedge clk) begin
        if (writeEnable) begin
            mem[writeAddress] <= writeValue;
        end
    end
endmodule
