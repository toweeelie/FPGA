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
        rst = 1'b0;
        btn = 3'b000;
        sw = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1;
        
        // wait microblaze to enter polling loop 
        #25us;
        
        // run same testing procedure for 2 directions
        for (int i=0; i<2; i++) begin
            // start led runs (speed 1)
            sw = i;
            btn = 3'b001;
            repeat (600) @(posedge clk);
            btn = 3'b000;
            #40us;
            
            // speed up led runs (speed 2)
            btn = 3'b010;
            repeat (600) @(posedge clk);
            btn = 3'b000;
            #40us;
      
            // speed down led runs (speed 1)
            btn = 3'b100;
            repeat (600) @(posedge clk);
            btn = 3'b000;
            #40us;      
            
            // stop led runs (speed 0)
            btn = 3'b001;
            repeat (600) @(posedge clk);
            btn = 3'b000;
            #40us;
        end
        $finish;
    end
endmodule
