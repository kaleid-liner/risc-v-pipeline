`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
//
// Design Name: RV32I Core
// Module Name: Hazard Module
// Tool Versions: Vivado 2017.4.1
// Description: Hazard Module is used to control flush, bubble and bypass
//
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  识别流水线中的数据冲突，控制数据转发，和flush、bubble信号
// 输入
    // rst               CPU的rst信号
    // reg1_srcD         ID阶段的源reg1地址
    // reg2_srcD         ID阶段的源reg2地址
    // reg1_srcE         EX阶段的源reg1地址
    // reg2_srcE         EX阶段的源reg2地址
    // reg_dstE          EX阶段的目的reg地址
    // reg_dstM          MEM阶段的目的reg地址
    // reg_dstW          WB阶段的目的reg地址
    // br                是否branch
    // jalr              是否jalr
    // jal               是否jal
    // src_reg_en        指令中的源reg1和源reg2地址是否有效
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果）
    // reg_write_en_MEM  MEM阶段的寄存器写使能信号
    // reg_write_en_WB   WB阶段的寄存器写使能信号
    // alu_src1          ALU操作数1来源：0表示来自reg1，1表示来自PC
    // alu_src2          ALU操作数2来源：2’b00表示来自reg2，2'b01表示来自reg2地址，2'b10表示来自立即数
// 输出
    // flushF            IF阶段的flush信号
    // bubbleF           IF阶段的bubble信号
    // flushD            ID阶段的flush信号
    // bubbleD           ID阶段的bubble信号
    // flushE            EX阶段的flush信号
    // bubbleE           EX阶段的bubble信号
    // flushM            MEM阶段的flush信号
    // bubbleM           MEM阶段的bubble信号
    // flushW            WB阶段的flush信号
    // bubbleW           WB阶段的bubble信号
    // op1_sel           ALU的操作数1来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自PC，2'b11表示来自reg1
    // op2_sel           ALU的操作数2来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自reg2地址，2'b11表示来自reg2或立即数
    // reg2_sel          reg2的来源
// 实验要求
    // 补全模块


module HarzardUnit(
    input wire rst,
    input wire [4:0] reg1_srcD, reg2_srcD, reg1_srcE, reg2_srcE, reg_dstE, reg_dstM, reg_dstW,
    input wire br, jalr, jal,
    input wire [1:0] src_reg_en,
    input wire wb_select,
    input wire reg_write_en_MEM,
    input wire reg_write_en_WB,
    input wire alu_src1,
    input wire [1:0] alu_src2,
    input wire rd_req,
    input wire wr_req,
    input wire miss,
    input wire pred_take,
    output reg flushF, bubbleF, flushD, bubbleD, flushE, bubbleE, flushM, bubbleM, flushW, bubbleW,
    output reg [1:0] op1_sel, op2_sel, reg2_sel
    );

    // TODO: Complete this module

    reg reg1_flushM, reg1_bubbleE, reg1_bubbleF, reg1_bubbleD;
    reg reg2_flushM, reg2_bubbleE, reg2_bubbleF, reg2_bubbleD;
    reg jump_flushD, jump_flushE;
    reg mem_bubbleW, mem_bubbleF, mem_bubbleD, mem_bubbleE, mem_bubbleM;

    always @(*) begin
        flushF = rst;
        flushD = jump_flushD | rst;
        flushE = jump_flushE | rst;
        flushM = reg1_flushM | reg2_flushM | rst;
        flushW = rst;

        bubbleF = reg1_bubbleF | reg2_bubbleF | mem_bubbleF;
        bubbleD = reg1_bubbleD | reg2_bubbleD | mem_bubbleD;
        bubbleE = reg1_bubbleE | reg2_bubbleE | mem_bubbleE;
        bubbleM = mem_bubbleM;
        bubbleW = mem_bubbleW;
    end

    always @(*) begin
        if ((rd_req | wr_req) & miss) begin
            mem_bubbleF = 1;
            mem_bubbleD = 1;
            mem_bubbleE = 1;
            mem_bubbleM = 1;
            mem_bubbleW = 1;
        end else begin
            mem_bubbleF = 0;
            mem_bubbleD = 0;
            mem_bubbleE = 0;
            mem_bubbleM = 0;
            mem_bubbleW = 0;
        end
    end

    always @(*) begin
        if (src_reg_en[0] && reg2_srcE != 5'b0 && reg_write_en_MEM && reg2_srcE == reg_dstM) begin
            if (!wb_select) begin
                op2_sel = alu_src2 == 2'b00 ? 2'b00 : 2'b11;
                reg2_sel = 2'b00;
                reg2_bubbleF = 0;
                reg2_bubbleD = 0;
                reg2_bubbleE = 0;
                reg2_flushM = 0;
            end else begin
                op2_sel = alu_src2 == 2'b00 ? 2'b01 : 2'b11;
                reg2_sel = 2'b01;
                reg2_bubbleF = 1;
                reg2_bubbleD = 1;
                reg2_bubbleE = 1;
                reg2_flushM = 1;
            end
        end else if (src_reg_en[0] && reg2_srcE != 5'b0 && reg_write_en_WB && reg2_srcE == reg_dstW) begin
            op2_sel = alu_src2 == 2'b00 ? 2'b01 : 2'b11;
            reg2_sel = 2'b01;
            reg2_bubbleF = 0;
            reg2_bubbleD = 0;
            reg2_bubbleE = 0;
            reg2_flushM = 0;
        end else begin
            op2_sel = 2'b11;
            reg2_sel = 2'b11;
            reg2_bubbleF = 0;
            reg2_bubbleD = 0;
            reg2_bubbleE = 0;
            reg2_flushM = 0;
        end

        if (src_reg_en[1] && reg1_srcE != 5'b0) begin
            if (reg_write_en_MEM && reg1_srcE == reg_dstM) begin
                if (!wb_select) begin
                    op1_sel = 2'b00;
                    reg1_bubbleF = 0;
                    reg1_bubbleD = 0;
                    reg1_bubbleE = 0;
                    reg1_flushM = 0;
                end else begin
                    op1_sel = 2'b01;
                    reg1_bubbleF = 1;
                    reg1_bubbleD = 1;
                    reg1_bubbleE = 1;
                    reg1_flushM = 1;
                end
            end else if (reg_write_en_WB && reg1_srcE == reg_dstW) begin
                op1_sel = 2'b01;
                reg1_bubbleF = 0;
                reg1_bubbleD = 0;
                reg1_bubbleE = 0;
                reg1_flushM = 0;
            end else begin
                op1_sel = alu_src1 ? 2'b10 : 2'b11;
                reg1_bubbleF = 0;
                reg1_bubbleD = 0;
                reg1_bubbleE = 0;
                reg1_flushM = 0;
            end
        end else begin
            op1_sel = alu_src1 ? 2'b10 : 2'b11;
            reg1_bubbleF = 0;
            reg1_bubbleD = 0;
            reg1_bubbleE = 0;
            reg1_flushM = 0;
        end
    end

    always @(*) begin
        if (jalr) begin
            jump_flushD = 1;
            jump_flushE = 1;
        end else if (br != pred_take) begin
            jump_flushD = 1;
            jump_flushE = 1;
        end else if (jal) begin
            jump_flushD = 1;
            jump_flushE = 0;
        end else begin
            jump_flushD = 0;
            jump_flushE = 0;
        end
    end

endmodule