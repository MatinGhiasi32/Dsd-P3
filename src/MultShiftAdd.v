module MultShiftAdd #(
    parameter WIDTH = 8
) (
    input                  clk,
    input                  rst,
    input                  start,
    input  [WIDTH-1:0]     a,
    input  [WIDTH-1:0]     b,
    output reg [2*WIDTH-1:0] product,
    output reg             done
);
    reg [WIDTH-1:0] multiplier;
    reg [2*WIDTH-1:0] multiplicand;
    reg [2*WIDTH-1:0] acc;
    reg [$clog2(WIDTH+1)-1:0] count;
    reg active;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc         <= 0;
            multiplicand<= 0;
            multiplier  <= 0;
            count       <= 0;
            product     <= 0;
            done        <= 0;
            active      <= 0;
        end else begin
            if (start && !active) begin
                acc          <= 0;
                multiplicand <= {{WIDTH{1'b0}}, a};
                multiplier   <= b;
                count        <= 0;
                done         <= 0;
                active       <= 1;
            end else if (active) begin
                if (multiplier[0])
                    acc <= acc + multiplicand;

                multiplicand <= multiplicand << 1;
                multiplier   <= multiplier >> 1;
                count        <= count + 1;
                if (count == WIDTH-1) begin
                    // finish up
                    if (multiplier[0])
                        acc <= acc + multiplicand;
                    product <= acc + (multiplier[0] ? multiplicand : 0);
                    done    <= 1;
                    active  <= 0;
                end
            end else begin
                done <= 0;
            end
        end
    end
endmodule