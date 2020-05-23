module PredTake_ID (
    input wire clk, bubbleD, flushD,
    input wire pred_take_IF,
    output reg pred_take_ID
);

initial pred_take_ID = 0;

always @ (posedge clk) begin
    if (!bubbleD) begin
        if (flushD) begin
            pred_take_ID <= 0;
        end else begin
            pred_take_ID <= pred_take_IF;
        end
    end
end

endmodule