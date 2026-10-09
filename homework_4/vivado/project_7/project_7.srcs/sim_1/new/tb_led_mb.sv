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
    
    
    initial clk = 0;
    always #2 clk = ~clk;
    
    initial begin
        
        btn = 0;
        sw = 0;
        
        // reset system
        @(posedge clk) #1;
        rst = 1; 
        @(posedge clk) #1;
        rst = 0;  
    
    
        // check start/stop btn
        @(posedge clk) #100;
        btn = 1;
        @(posedge clk) #1000;
        btn = 0;
        
        // check speed up button
        
        // check speed down button
    

    
        $finish;
    end
endmodule
