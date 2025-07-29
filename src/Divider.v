module Divider (
    input               clk,
    input               rst,       
    input               start,     
    input       [31:0]  dividend,  
    input       [15:0]  divisor,   
    output reg  [31:0]  quotient,  
    output reg  [15:0]  remainder, 
    output reg          done       
);

    localparam N = 32;

    reg         busy;
    reg  [5:0]  cnt;
    reg  [48:0] sr;   // { rem[16:0], dv[31:0] }

    always @(posedge clk) begin
        if (rst) begin
            busy      <= 1'b0;
            done      <= 1'b0;
            quotient  <= 0;
            remainder <= 0;
            cnt       <= 0;
            sr        <= 0;
        end else begin
            done <= 1'b0;
            if (!busy && start) begin
                busy     <= 1'b1;
                cnt      <= N-1;            // <-- run 32 cycles: 31 down to 0
                sr       <= {17'b0, dividend};
                quotient <= 0;
            end
            else if (busy) begin
                // 1) shift left {rem,dv}
                sr = sr << 1;

                // 2) subtract trial
                if (sr[48:32] >= {1'b0, divisor}) begin
                    sr[48:32] = sr[48:32] - {1'b0, divisor};
                    quotient   = (quotient << 1) | 1'b1;
                end else begin
                    quotient   = (quotient << 1);
                end

                // 3) finish after the 0th iteration
                if (cnt == 0) begin
                    busy      <= 1'b0;
                    done      <= 1'b1;
                    remainder <= sr[48:32];
                end else begin
                    cnt = cnt - 1;
                end
            end
        end
    end
endmodule
