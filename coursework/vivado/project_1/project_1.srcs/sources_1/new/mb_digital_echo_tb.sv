`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 18:31:01
// Design Name: 
// Module Name: mb_digital_echo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_monitor #(
    parameter integer CLK_HZ  = 100_000_000,
    parameter integer BAUD    = 230400
)(
    input wire tx
);

    localparam integer BIT_TIME_NS = 1_000_000_000 / BAUD;

    integer ch;
    integer i;

    initial begin
        $display("UART monitor started (baud=%0d)", BAUD);

        forever begin
            // Wait for UART start bit (falling edge)
            @(negedge tx);

            // Sample near the center of the start bit
            #(BIT_TIME_NS / 2);

            if (tx === 1'b0) begin
                ch = 0;

                // Sample 8 data bits, LSB first
                for (i = 0; i < 8; i = i + 1) begin
                    #(BIT_TIME_NS);
                    ch = ch | (tx << i);
                end

                // Move to the stop-bit center
                #(BIT_TIME_NS);

                if (tx === 1'b1) begin
                    if (ch >= 32 && ch <= 126)
                        $write("%c", ch);
                    else if (ch == 10)
                        $write("\n");
                    else if (ch == 13)
                        $write("");
                    else
                        $write("<0x%02X>", ch);
                end
                else begin
                    $display("\n[UART framing error]");
                end
            end
        end
    end

endmodule

module mb_digital_echo_tb();

    logic clk;
    logic rst;
    
    
    design_1_wrapper dut(
        .reset_rtl_0(rst),
        .clk_100MHz(clk)
    );
    
    uart_monitor uart_console (
        .tx(dut.design_1_i.axi_uartlite_0.tx)
    );
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial begin
        // reset
        rst = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1;
        
        #9ms;
    
        $finish;
    end
endmodule
