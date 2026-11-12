`timescale 1ns / 1ps

module uart_rx (
    input clk,
    input rst,
    input rx_en,
    input rx,

    output reg [7:0] data_out,
    output reg rx_done
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] sample_count;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;

    reg rx_sync1, rx_sync2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            sample_count <= 0;
            bit_count    <= 0;
            shift_reg    <= 0;
            data_out     <= 0;
            rx_done      <= 0;
        end
        else begin
            rx_done <= 0;

            case (state)

                IDLE: begin
                    sample_count <= 0;
                    bit_count    <= 0;
                    if (!rx_sync2)
                        state <= START;
                end

                START: begin
                    if (rx_en) begin
                        if (sample_count == 7) begin
                            sample_count <= 0;
                            if (!rx_sync2)
                                state <= DATA;
                            else
                                state <= IDLE;
                        end else
                            sample_count <= sample_count + 1;
                    end
                end

                DATA: begin
                    if (rx_en) begin
                        if (sample_count == 15) begin
                            sample_count <= 0;
                            shift_reg <= {rx_sync2, shift_reg[7:1]};
                            if (bit_count == 7)
                                state <= STOP;
                            else
                                bit_count <= bit_count + 1;
                        end else
                            sample_count <= sample_count + 1;
                    end
                end

                STOP: begin
                    if (rx_en) begin
                        if (sample_count == 15) begin
                            sample_count <= 0;
                            data_out     <= shift_reg;
                            rx_done      <= 1;
                            state        <= IDLE;
                        end else
                            sample_count <= sample_count + 1;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule