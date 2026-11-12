`timescale 1ns / 1ps

module uart_tx (
    input clk,
    input rst,
    input tx_en,
    input wr_enb,
    input [7:0] data_in,

    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_count;

    always @(posedge clk or posedge rst)
    begin
        if(rst) begin
            state     <= IDLE;
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            shift_reg <= 8'd0;
            bit_count <= 4'd0;
        end
        else begin
            tx_done <= 1'b0;

            case(state)

                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                    if(wr_enb) begin
                        shift_reg <= data_in;
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    if(tx_en) begin
                        tx        <= 1'b0;
                        state     <= DATA;
                        bit_count <= 4'd0;
                    end
                end

                DATA: begin
                    if(tx_en) begin
                        tx        <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;

                        if(bit_count == 7)
                            state <= STOP;
                        else
                            bit_count <= bit_count + 1'b1;
                    end
                end

                STOP: begin
                    if(tx_en) begin
                        tx      <= 1'b1;
                        tx_done <= 1'b1;
                        tx_busy <= 1'b0;
                        state   <= IDLE;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule