`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
//
// Design Name: RV32I Core
// Module Name: Controller Decoder
// Tool Versions: Vivado 2017.4.1
// Description: Controller Decoder Module
//
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  对指令进行译码，将其翻译成控制信号，传输给各个部件
// 输入
    // Inst              待译码指令
// 输出
    // jal               jal跳转指令
    // jalr              jalr跳转指令
    // op2_src           ALU的第二个操作数来源。为1时，op2选择imm，为0时，op2选择reg2
    // ALU_func          ALU执行的运算类型
    // br_type           branch的判断条件，可以是不进行branch
    // load_npc          写回寄存器的值的来源（PC或者ALU计算结果）, load_npc == 1时选择PC
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果），wb_select == 1时选择cache内容
    // load_type         load类型
    // src_reg_en        指令中src reg的地址是否有效，src_reg_en[1] == 1表示reg1被使用到了，src_reg_en[0]==1表示reg2被使用到了
    // reg_write_en      通用寄存器写使能，reg_write_en == 1表示需要写回reg
    // cache_write_en    按字节写入data cache
    // imm_type          指令中立即数类型
    // alu_src1          alu操作数1来源，alu_src1 == 0表示来自reg1，alu_src1 == 1表示来自PC
    // alu_src2          alu操作数2来源，alu_src2 == 2’b00表示来自reg2，alu_src2 == 2'b01表示来自reg2地址，alu_src2 == 2'b10表示来自立即数
    // csr_op            csr 操作类型
    // csr_write_en      csr 写使能
    // csr_read_en       csr 读使能
    // load_csr          写回寄存器的值的来源 (CSR 或者 ALU 计算结果），load_csr == 1 时选择 CSR
    // csr_src           csr 数据来源，csr_src == 0 表示来自 reg1，csr_src == 1 表示来自 zimm
// 实验要求
    // 补全模块


`include "Parameters.v"
module ControllerDecoder(
    input wire [31:0] inst,
    output wire jal,
    output wire jalr,
    output wire op2_src,
    output reg [3:0] ALU_func,
    output reg [2:0] br_type,
    output wire load_npc,
    output wire wb_select,
    output reg [2:0] load_type,
    output reg [1:0] src_reg_en,
    output reg reg_write_en,
    output reg [3:0] cache_write_en,
    output wire alu_src1,
    output wire [1:0] alu_src2,
    output reg [2:0] imm_type,
    output reg [1:0] csr_op,
    output wire csr_write_en,
    output wire csr_read_en,
    output wire load_csr,
    output wire csr_src
    );

    // TODO: Complete this module

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rd, rs1;

    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign rd = inst[11:7];
    assign rs1 = inst[19:15];

    assign jal = opcode == `OP_JAL;
    assign jalr = opcode == `OP_JALR;
    assign op2_src = imm_type == `RTYPE ? 0 : 1;
    assign load_npc = opcode == `OP_JAL || opcode == `OP_JALR;
    assign wb_select = opcode == `OP_LOAD;
    assign alu_src1 = opcode == `OP_AUIPC;
    assign alu_src2 = op2_src ? 2'b10 : 2'b00;

    assign csr_src = funct3[2];
    assign load_csr = opcode == `OP_CSR;
    assign csr_write_en = opcode == `OP_CSR && (rs1 != 5'd0 || funct3[1:0] == 2'b01);
    assign csr_read_en = opcode == `OP_CSR && rd != 5'd0;
    always @(*) begin
        case (funct3)
            3'b001, 3'b101 : csr_op = `CSRRW;
            3'b010, 3'b110 : csr_op = `CSRRS;
            3'b011, 3'b111 : csr_op = `CSRRC;
        endcase
    end

    always @(*) begin
        if (opcode == `OP_AUIPC || opcode == `OP_STORE || opcode == `OP_LOAD)
            ALU_func = `ADD;
        else if (opcode == `OP_LUI)
            ALU_func = `LUI;
        else if (opcode == `OP_JALR)
            ALU_func = `ADD;
        else begin
            case (funct3)
                3'b000 : ALU_func = opcode[5] & inst[30] ? `SUB : `ADD;
                3'b001 : ALU_func = `SLL;
                3'b010 : ALU_func = `SLT;
                3'b011 : ALU_func = `SLTU;
                3'b100 : ALU_func = `XOR;
                3'b101 : ALU_func = inst[30] ? `SRA : `SRL;
                3'b110 : ALU_func = `OR;
                3'b111 : ALU_func = `AND;
            endcase
        end
    end

    always @(*) begin
        if (opcode == `OP_BR) begin
            case (funct3)
                3'b000 : br_type = `BEQ;
                3'b001 : br_type = `BNE;
                3'b100 : br_type = `BLT;
                3'b101 : br_type = `BGE;
                3'b110 : br_type = `BLTU;
                3'b111 : br_type = `BGEU;
                default: br_type = `NOBRANCH;
            endcase
        end else
            br_type = `NOBRANCH;
    end

    always @(*) begin
        case (funct3)
            3'b000 : load_type = `LB;
            3'b001 : load_type = `LH;
            3'b010 : load_type = `LW;
            3'b100 : load_type = `LBU;
            3'b101 : load_type = `LHU;
            default: load_type = `NOREGWRITE;
        endcase
    end

    always @(*) begin
        if (opcode == `OP_STORE)
            case (funct3)
                3'b000 : cache_write_en = 4'b0001;
                3'b001 : cache_write_en = 4'b0011;
                3'b010 : cache_write_en = 4'b1111;
                default: cache_write_en = 4'b0000;
            endcase
        else
            cache_write_en = 0;
    end

    always @(*) begin
        case (opcode)
            `OP_LUI    : begin
                imm_type = `UTYPE;
                src_reg_en = 2'b00;
                reg_write_en = 1;
            end
            `OP_AUIPC  : begin
                imm_type = `UTYPE;
                src_reg_en = 2'b00;
                reg_write_en = 1;
            end
            `OP_JAL    : begin
                imm_type = `JTYPE;
                src_reg_en = 2'b00;
                reg_write_en = 1;
            end
            `OP_JALR   : begin
                imm_type = `ITYPE;
                src_reg_en = 2'b10;
                reg_write_en = 1;
            end
            `OP_BR     : begin
                imm_type = `BTYPE;
                src_reg_en = 2'b11;
                reg_write_en = 0;
            end
            `OP_LOAD   : begin
                imm_type = `ITYPE;
                src_reg_en = 2'b10;
                reg_write_en = 1;
            end
            `OP_STORE  : begin
                imm_type = `STYPE;
                src_reg_en = 2'b11;
                reg_write_en = 0;
            end
            `OP_IMM    : begin
                imm_type = `ITYPE;
                src_reg_en = 2'b10;
                reg_write_en = 1;
            end
            `OP_ALU    : begin
                imm_type = `RTYPE;
                src_reg_en = 2'b11;
                reg_write_en = 1;
            end
            `OP_CSR    : begin
                imm_type = `ITYPE;
                src_reg_en = csr_src ? 2'b00 : 2'b10;
                reg_write_en = 1;
            end
            default    : begin
                imm_type = `RTYPE;
                src_reg_en = 2'b00;
                reg_write_en = 0;
            end
        endcase
    end

endmodule
