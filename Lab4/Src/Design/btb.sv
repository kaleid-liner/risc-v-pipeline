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
    output wire [31:0] pred_pc,
    output wire pred_take
);

localparam UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - SET_ADDR_LEN - 2;

localparam SET_SIZE = 1 << SET_ADDR_LEN;

reg [TAG_ADDR_LEN-1:0] tag_addr;
reg [SET_ADDR_LEN-1:0] set_addr;

reg [31:0] buffer[SET_SIZE];
reg [TAG_ADDR_LEN-1:0] buffer_tags[SET_SIZE];
reg valid[SET_SIZE];

wire [              2-1:0]   rd_word_addr;
wire [   SET_ADDR_LEN-1:0]    rd_set_addr;
wire [   TAG_ADDR_LEN-1:0]    rd_tag_addr;
wire [UNUSED_ADDR_LEN-1:0] rd_unused_addr;

wire [              2-1:0]   wr_word_addr;
wire [   SET_ADDR_LEN-1:0]    wr_set_addr;
wire [   TAG_ADDR_LEN-1:0]    wr_tag_addr;
wire [UNUSED_ADDR_LEN-1:0] wr_unused_addr;

assign {rd_unused_addr, rd_tag_addr, rd_set_addr, rd_word_addr} = rd_pc;
assign {wr_unused_addr, wr_tag_addr, wr_set_addr, wr_wowr_addr} = wr_pc;

assign pred_take = valid[set_addr] & (tag_addr == buffer_tags[set_addr]);
assign pred_pc = buffer[set_addr];

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < SET_SIZE; i++) begin
            valid[i] <= 0;
            buffer_tags[i] <= 0;
            buffer[i] <= 0;
        end
        for (integer i = 0; i < TAG_SIZE)
    end else if (wr_en) begin
        if (taken & !pred_take) begin
            valid[wr_set_addr] <= 1;
            buffer_tags[wr_set_addr] <= tag_addr;
            buffer[wr_set_addr] <= wr_pc;
        end else if (!taken & pred_take)
            valid[wr_set_addr] <= 0;
        end
    end
end
