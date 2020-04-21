`timescale 1ns / 1ps

`include "Parameters.v"

module ControlStatusRegister (
    input wire clk,
    input wire rst,
    input wire [31:0] in_data,
    input wire [11:0] addr,
    input wire write_en,
    input wire read_en,
    input wire [1:0] op,
    output wire [31:0] out_data
);

    reg [31:0] reg_file[31:0];

    integer i;
    initial begin
        for(i = 0; i < 32; i = i + 1)
            reg_file[i][31:0] <= 32'b0;
    end

    wire [4:0] dealt_addr = addr[4:0];
    reg [31:0] dealt_data;

    assign out_data = reg_file[dealt_addr];

    always @(*) begin
        case (op)
            `CSRRW : dealt_data = in_data;
            `CSRRC : dealt_data = in_data ^ out_data;
            `CSRRS : dealt_data = in_data | out_data;
            default: dealt_data = in_data;
        endcase
    end

    always @(negedge clk or posedge rst) begin
        if (rst)
            for (i = 0; i < 32; i = i + 1)
                reg_file[i][31:0] <= 32'b0;
        else if (write_en)
            reg_file[dealt_addr] <= dealt_data;
    end

    // As there ain't any side effects, so I didn't consider read_en

endmodule