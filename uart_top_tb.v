`timescale 1ns / 1ps

module uart_top_tb;

    localparam CLK_FREQ   = 50_000_000;
    localparam BAUD_RATE  = 115200;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;  // 20 ns

    reg clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    reg        rst;
    reg        wr_enb;
    reg  [7:0] data_in;
    wire       tx;
    wire [7:0] data_out;
    wire       tx_busy;
    wire       tx_done;
    wire       rx_done;

    reg  use_loopback;
    reg  rx_manual;
    wire rx = use_loopback ? tx : rx_manual;

    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_enb(wr_enb),
        .data_in(data_in),
        .rx(rx),
        .tx(tx),
        .data_out(data_out),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx_done(rx_done)
    );

    integer pass_count = 0;
    integer fail_count = 0;


    task reset_dut;
        begin
            rst          = 1;
            wr_enb       = 0;
            data_in      = 0;
            rx_manual    = 1;
            use_loopback = 1;
            #(CLK_PERIOD * 10);
            rst = 0;
            #(CLK_PERIOD * 5);
        end
    endtask


    task test_loopback(input [7:0] send_byte);
        begin
            use_loopback = 1;
            @(posedge clk);
            data_in = send_byte;
            wr_enb  = 1;
            @(posedge clk);
            wr_enb  = 0;

            wait(rx_done == 1);
            @(posedge clk);

            if (data_out === send_byte) begin
                $display("[PASS] Sent 0x%02X, Received 0x%02X", send_byte, data_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Sent 0x%02X, Got 0x%02X", send_byte, data_out);
                fail_count = fail_count + 1;
            end

            repeat(32) @(posedge dut.rx_en); 
        end
    endtask


    task inject_rx_byte(input [7:0] byte_val);
        integer i;
        begin
            use_loopback = 0;
            rx_manual    = 1;
            repeat(32) @(posedge dut.rx_en);  

            // Start bit
            @(posedge clk);
            rx_manual = 0;
            repeat(16) @(posedge dut.rx_en);  

            // 8 Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_manual = byte_val[i];
                repeat(16) @(posedge dut.rx_en);
            end

            // Stop bit
            rx_manual = 1;
            repeat(16) @(posedge dut.rx_en);

            // Idle
            repeat(32) @(posedge dut.rx_en);
        end
    endtask


    initial begin
        $display("         UART TESTBENCH");
        $display("  CLK = %0d MHz  |  BAUD = %0d", CLK_FREQ/1_000_000, BAUD_RATE);

        reset_dut();


        $display("---> CASE 1: Idle Check");
        if (tx == 1 && tx_busy == 0) begin
            $display("[PASS] TX HIGH, not busy.\n");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Bad idle state!\n");
            fail_count = fail_count + 1;
        end

        $display("---> CASE 2: Loopback 0xA5 ");
        test_loopback(8'hA5);

 
        $display("\n---> CASE 3: Corner Cases ");
        test_loopback(8'h00);
        test_loopback(8'hFF);
        test_loopback(8'h5A);


        $display("\n---> CASE 4: Manual RX Injection 0xD2");
        inject_rx_byte(8'hD2);


        if (data_out === 8'hD2) begin
            $display("[PASS] Received 0x%02X correctly.\n", data_out);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected 0xD2, got 0x%02X\n", data_out);
            fail_count = fail_count + 1;
        end

        $finish;
    end


endmodule