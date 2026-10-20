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


module mb_digital_echo_tb();

    logic clk;
    logic rst;
    
    
    design_1_wrapper dut(
        .reset_rtl_0(rst),
        .clk_100MHz(clk)
    );
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial begin
        // reset
        rst = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1;
        
        #500us;
    
        $finish;
    end
endmodule
