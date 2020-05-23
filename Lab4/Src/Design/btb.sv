`timescale 1ns / 1ps

module BTB #(
    parameter TAG_ADDR_LEN = 1,
    parameter SET_ADDR_LEN = 12
)(
    input clk,
    input rst,
    input wire [31:0] rd_pc, wr_pc,
    input wire taken,
    input wire wr_en,
    input wire pred_take_EX,
    input wire [31:0] br_target,
    output wire [31:0] pred_pc,
    output wire pred_take
);

localparam UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - SET_ADDR_LEN - 2;

localparam SET_SIZE = 1 << SET_ADDR_LEN;

reg [31:0] buffer[SET_SIZE];
reg [TAG_ADDR_LEN-1:0] buffer_tags[SET_SIZE];
reg valid[SET_SIZE];

reg [1:0] bht[SET_SIZE];

wire [              2-1:0]   rd_word_addr;
wire [   SET_ADDR_LEN-1:0]    rd_set_addr;
wire [   TAG_ADDR_LEN-1:0]    rd_tag_addr;
wire [UNUSED_ADDR_LEN-1:0] rd_unused_addr;

wire [              2-1:0]   wr_word_addr;
wire [   SET_ADDR_LEN-1:0]    wr_set_addr;
wire [   TAG_ADDR_LEN-1:0]    wr_tag_addr;
wire [UNUSED_ADDR_LEN-1:0] wr_unused_addr;

assign {rd_unused_addr, rd_tag_addr, rd_set_addr, rd_word_addr} = rd_pc;
assign {wr_unused_addr, wr_tag_addr, wr_set_addr, wr_word_addr} = wr_pc;

assign pred_take = valid[rd_set_addr] & (rd_tag_addr == buffer_tags[rd_set_addr]) & bht[1];
assign pred_pc = buffer[rd_set_addr];

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < SET_SIZE; i++) begin
            valid[i] <= 0;
            buffer_tags[i] <= 0;
            buffer[i] <= 0;
        end
    end else if (wr_en) begin
        if (taken & !pred_take_EX) begin
            valid[wr_set_addr] <= 1;
            buffer_tags[wr_set_addr] <= wr_tag_addr;
            buffer[wr_set_addr] <= br_target;
        end else if (!taken & pred_take_EX) begin
            valid[wr_set_addr] <= 0;
        end
    end
end

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < SET_SIZE; i++) begin
            bht[i] <= 2'b11;
        end
    end else if (wr_en) begin
        if (taken) begin
            case (bht[wr_set_addr])
                2'b00: bht[wr_set_addr] <= 2'b01;
                2'b01: bht[wr_set_addr] <= 2'b11;
                2'b10: bht[wr_set_addr] <= 2'b11;
                2'b11: bht[wr_set_addr] <= 2'b11;
            endcase
        end else begin
            case (bht[wr_set_addr])
                2'b00: bht[wr_set_addr] <= 2'b00;
                2'b01: bht[wr_set_addr] <= 2'b00;
                2'b10: bht[wr_set_addr] <= 2'b00;
                2'b11: bht[wr_set_addr] <= 2'b10;
            endcase
        end
    end
end

endmodule
