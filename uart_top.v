`timescale 1ns / 1ps

module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,

    input wr_enb,
    input [7:0] data_in,

    input rx,

    output tx,
    output [7:0] data_out,
    output tx_busy,
    output tx_done,
    output rx_done
);

    wire tx_en;
    wire rx_en;

    baud_rate_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .rst(rst),
        .tx_en(tx_en),
        .rx_en(rx_en)
    );

    uart_tx transmitter (
        .clk(clk),
        .rst(rst),
        .tx_en(tx_en),
        .wr_enb(wr_enb),
        .data_in(data_in),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx receiver (
        .clk(clk),
        .rst(rst),
        .rx_en(rx_en),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

endmodule