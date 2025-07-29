// CPU.v
// 4‑state, multi‑cycle CPU: ADD, SUB, LOAD, STR
// Instruction formats:
//   R‑type: [15:13]=opcode, [12:11]=rd, [10:9]=rs1, [8:7]=rs2, [6:0]=unused
//   LOAD:   [15:13]=3'b100, [12:11]=rd,  [10:9]=base, [8:0]=imm9 (signed)
//   STR:    [15:13]=3'b101, [12:11]=rs,  [10:9]=base, [8:0]=imm9 (signed)
//   NO-OP: 16'h0000

module CPU #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
)(
    input                    clk,
    input                    rst
);

    // 1) Program Counter & Instruction Register
    reg [ADDR_WIDTH-1:0] PC;
    reg [15:0]           IR;

    // 2) Decode instruction fields
    wire [2:0]        opcode = IR[15:13];
    wire [1:0]        rd_r   = IR[12:11];
    wire [1:0]        rs1_r  = IR[10:9];
    wire [1:0]        rs2_r  = IR[8:7];
    wire [1:0]        rd_i   = IR[12:11];
    wire [1:0]        base   = IR[10:9];
    wire signed [8:0] imm9   = IR[8:0];

    wire [DATA_WIDTH-1:0] imm_ext = {{7{imm9[8]}}, imm9};

    // 3) Control Unit
    wire       cu_regwrite, cu_memwrite, cu_memread;
    wire       cu_alusrc,    cu_memtoreg,   cu_regread;
    wire [1:0] state;

    ControlUnit CU (
        .clk       (clk),
        .rst       (rst),
        .opcode    (opcode),
        .noop      (IR == 16'h0000),
        .regwrite  (cu_regwrite),
        .memwrite  (cu_memwrite),
        .memread   (cu_memread),
        .alusrc    (cu_alusrc),
        .memtoreg  (cu_memtoreg),
        .regread   (cu_regread),
        .state     (state)
    );

    // 4) Pre-declare ALU and memory output wires
    wire [DATA_WIDTH-1:0] alu_out;
    wire [DATA_WIDTH-1:0] memrdata;

    // 5) EX→MEM pipeline registers (EA, SD, MDR)
    reg [ADDR_WIDTH-1:0] EA;
    reg [DATA_WIDTH-1:0] SD;
    reg [DATA_WIDTH-1:0] MDR;

    // 6) Register File
    wire [1:0] rf_read2      = cu_regread ? rd_i : rs2_r;
    wire [1:0] rf_write_addr = cu_memtoreg ? rd_i : rd_r;
    wire [DATA_WIDTH-1:0] wb_data = cu_memtoreg ? MDR : alu_out;

    wire [DATA_WIDTH-1:0] op1, op2;
    RegisterFile RF (
        .clk            (clk),
        .rst            (rst),
        .readRegister1  (rs1_r),
        .readRegister2  (rf_read2),
        .writeRegister  (rf_write_addr),
        .writeEnable    (state == 2'b11 && cu_regwrite),
        .writeData      (wb_data),
        .readData1      (op1),
        .readData2      (op2)
    );

    // 7) ALU (combinational)
    wire [DATA_WIDTH-1:0] alu_in2 = cu_alusrc ? imm_ext : op2;
    ALU ALU0 (
        .opcode (opcode),
        .a      (op1),
        .b      (alu_in2),
        .result (alu_out)
    );

    // 8) Unified RAM
    reg memread_reg, memwrite_reg;
    reg [ADDR_WIDTH-1:0] memaddr_reg;
    reg [DATA_WIDTH-1:0] memwdata_reg;
    RAM ram (
        .clk          (clk),
        .readEnable   (memread_reg),
        .writeEnable  (memwrite_reg),
        .readAddress  (memaddr_reg),
        .writeAddress (memaddr_reg),
        .writeValue   (memwdata_reg),
        .readValue    (memrdata)
    );

    // 9) EX->MEM latches on DEEX
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            EA  <= 0;
            SD  <= 0;
            // MDR <= 0;   // ← حذف شد تا conflict برطرف بشه
        end else if (state == 2'b01) begin  // DEEX
            EA  <= alu_out;
            SD  <= op2;
        end
    end

    // 10) Memory access logic
    always @(*) begin
        memread_reg  = 1'b0;
        memwrite_reg = 1'b0;
        memaddr_reg  = {ADDR_WIDTH{1'bx}};
        memwdata_reg = {DATA_WIDTH{1'bx}};

        case (state)
        2'b00: begin  // FETCH
            memread_reg = cu_memread;
            memaddr_reg = PC;
        end
        2'b10: begin  // MEMACC
            if (cu_memread) begin  // LOAD
                memread_reg = 1'b1;
                memaddr_reg = EA;
            end else if (cu_memwrite) begin  // STR
                memwrite_reg = 1'b1;
                memaddr_reg  = EA;
                memwdata_reg = SD;
            end
        end
        default: ;  // DEEX/WB
        endcase
    end

    // 11) PC, IR, MDR updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC  <= 0;
            IR  <= 0;
            MDR <= 0;
        end else begin
            if (state == 2'b00) begin  // FETCH
                IR <= memrdata;
                PC <= PC + 1;
            end
            if (state == 2'b10 && cu_memread) begin  // MEMACC LOAD
                MDR <= memrdata;
            end
        end
    end

endmodule
