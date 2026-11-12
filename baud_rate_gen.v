`timescale 1ns / 1ps

module baud_rate_gen #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,
    output reg tx_en,
    output reg rx_en
);

    localparam cycles_tx = CLK_FREQ / BAUD_RATE;
    localparam cycles_rx = CLK_FREQ / (BAUD_RATE * 16);

    localparam tx_max = $clog2(cycles_tx);
    localparam rx_max = $clog2(cycles_rx);

    reg [tx_max-1:0] count_tx;
    reg [rx_max-1:0] count_rx;

    always @(posedge clk or posedge rst)
    begin
        if(rst) begin
            count_tx <= 0;
            count_rx <= 0;
            tx_en    <= 0;
            rx_en    <= 0;
        end
        else begin
            if(count_tx == cycles_tx - 1) begin
                count_tx <= 0;
                tx_en    <= 1;
            end
            else begin
                count_tx <= count_tx + 1'b1;
                tx_en    <= 0;
            end

            if(count_rx == cycles_rx - 1) begin
                count_rx <= 0;
                rx_en    <= 1;
            end
            else begin
                count_rx <= count_rx + 1'b1;
                rx_en    <= 0;
            end
        end
    end

endmodule
