`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.10.2026 21:51:45
// Design Name: 
// Module Name: mb_dma_tb
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


module mb_dma_tb();
    logic clk;
    logic rst;
    logic [7:0] data_in;
    logic btn;


    design_1_wrapper dut (
        .clk_100MHz(clk),
        .reset_rtl_0(rst),
        .btn_tri_i(btn),
        .data_in_0(data_in)
    );
    
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial begin
        rst = 1'b0;
        btn = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1;
        
        // wait microblaze to enter polling loop 
        #60us;
        btn = 1'b1;
        
        for (int i = 0; i < 320*200; i = i + 1) begin
            @(negedge clk);
            data_in = i[7:0];
            if (i == 100) begin
                btn = 1'b0;
            end
        end
    
        #5us;
        
        $finish;
    end
endmodule