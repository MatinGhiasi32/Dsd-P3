module ControlUnit (
    input            clk,
    input            rst,
    input      [2:0] opcode,    // 000=ADD, 001=SUB, 100=LOAD, 101=STR
    input            noop,
    output reg       regwrite,
    output reg       memwrite,
    output reg       memread,
    output reg       alusrc,
    output reg       memtoreg,
    output reg       regread,
    output reg [1:0] state      // State output
);

    // States remain same but transitions are simpler
    localparam FETCH  = 2'b00;
    localparam DEEX   = 2'b01;
    localparam MEMACC = 2'b10;
    localparam WB     = 2'b11;

    reg [1:0] next;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= FETCH;
        else     state <= next;
    end


    // Combinational logic - all operations complete in DEEX state
    always @(*) begin
        // Default outputs
        next      = FETCH;
        regwrite  = 1'b0;
        memwrite  = 1'b0;
        memread   = 1'b0;
        alusrc    = 1'b0;
        memtoreg  = 1'b0;
        regread   = 1'b0;

        case (state)
            FETCH: begin
                memread = 1'b1;
                next = DEEX;
            end

            DEEX: begin
                // treat 16'h0000 as a 1‑cycle NOP
                if (opcode == 3'b100 || opcode == 3'b101) // LOAD/STR
                    alusrc = 1'b1;

                if (opcode == 3'b101)
                    regread = 1'b1;
                next = MEMACC;
                if (noop) begin
                    next = FETCH;      
                end
            end

            MEMACC: begin
                case (opcode)
                    3'b100: begin  // LOAD
                        memread = 1'b1;
                        next = WB;
                    end
                    3'b101: begin  // STR
                        memwrite = 1'b1;
                        next = FETCH;
                    end
                    default: next = WB;  // ADD/SUB
                endcase
            end

            WB: begin
                regwrite = (opcode != 3'b101);  // Not for STR
                memtoreg = (opcode == 3'b100);  // Only for LOAD
                next = FETCH;
            end
        endcase
    end
endmodule