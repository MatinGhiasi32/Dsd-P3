module RegisterFile (
    input  wire [1:0] readRegister1,
    input  wire [1:0] readRegister2,
    input  wire [1:0] writeRegister,
    input  wire        writeEnable,
    input  wire [15:0] writeData,
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] readData1,
    output wire [15:0] readData2
);
    wire [15:0] out0, out1, out2, out3;


    wire we0 = writeEnable && (writeRegister == 2'b00);
    wire we1 = writeEnable && (writeRegister == 2'b01);
    wire we2 = writeEnable && (writeRegister == 2'b10);
    wire we3 = writeEnable && (writeRegister == 2'b11);

    wire [15:0] d0 = we0 ? writeData : out0;
    wire [15:0] d1 = we1 ? writeData : out1;
    wire [15:0] d2 = we2 ? writeData : out2;
    wire [15:0] d3 = we3 ? writeData : out3;


    Register #(.WIDTH(16)) x0 (
        .clk(clk), .rst(rst),
        .d(d0),    .q(out0)
    );

    Register #(.WIDTH(16)) x1 (
        .clk(clk), .rst(rst),
        .d(d1),    .q(out1)
    );

    Register #(.WIDTH(16)) x2 (
        .clk(clk), .rst(rst),
        .d(d2),    .q(out2)
    );

    Register #(.WIDTH(16)) x3 (
        .clk(clk), .rst(rst),
        .d(d3),    .q(out3)
    );

    assign readData1 = (readRegister1 == 2'b00) ? out0 :
                       (readRegister1 == 2'b01) ? out1 :
                       (readRegister1 == 2'b10) ? out2 :
                                                  out3;

    assign readData2 = (readRegister2 == 2'b00) ? out0 :
                       (readRegister2 == 2'b01) ? out1 :
                       (readRegister2 == 2'b10) ? out2 :
                                                  out3;

endmodule
