`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.10.2026 13:54:29
// Design Name: 
// Module Name: tb_led_mb
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


module tb_led_mb();

    logic clk;
    logic rst;
    logic [3:0] led;
    logic [2:0] btn;
    logic sw;

    design_1_wrapper dut (
        .clk_100MHz(clk),
        .reset_rtl_0(rst),
        .btn_tri_i(btn),
        .sw_tri_i(sw),
        .led_tri_o(led)
    );
    
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial begin
        rst = 1'b1;
        btn = 3'b000;
        sw = 1'b0;
        
        // Keep MicroBlaze in reset for several clock cycles.
        repeat (10) @(posedge clk);
        rst = 1'b0;

        // Press start/stop after the application has initialized.
        repeat (100) @(posedge clk);
        btn = 3'b001;
        repeat (100) @(posedge clk);
        btn = 3'b000;

        // Run long enough to observe startup AXI reads and writes.
        #20us;
        $finish;
    end
endmodule
