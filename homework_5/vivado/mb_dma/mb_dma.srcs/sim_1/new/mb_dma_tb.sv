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
    logic btn;
    logic [7:0] data_in;
    logic [7:0] stored_start;
    logic [31:0] ref_word;
    logic [31:0] tst_word;
    logic pass = 1;
    
    design_1_wrapper dut (
        .clk_100MHz(clk),
        .reset_rtl_0(rst),
        .btn_tri_i(btn),
        .data_in_0(data_in)
    );  
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial data_in = 8'd0;
    always @(posedge clk) data_in <= data_in + 8'd1;
    
    initial begin
        // reset
        rst = 1'b0;
        btn = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1;
        
        // wait MicroBlaze to enter polling loop 
        #60us;
        
        // generate start
        btn = 1'b1;
        repeat (100) @(posedge clk);
        btn = 1'b0;
        
        // wait untill start comes from MicroBlaze
        @(posedge dut.design_1_i.axi_gpio_1.gpio_io_o);
        stored_start = data_in + 1;
        
        #60us
      
        for (int i = 0; i < 1000; i = i + 1) begin
            ref_word[7:0] = stored_start + (4*i+0);
            ref_word[15:8] = stored_start + (4*i+1);
            ref_word[23:16] = stored_start + (4*i+2);
            ref_word[31:24] = stored_start + (4*i+3);
            
            tst_word = dut.design_1_i.axi4_full_ram_0.inst.mem[i];

            if(ref_word !== tst_word) begin
                $display("MISMATCH mem[%d]: ref = 0x%08h, tst = 0x%08h", i, ref_word, tst_word);
                pass = 0;
            end
        end

        $display("Testing finished: %s", (pass)? "PASS" : "FAIL");    
        
        $finish;
    end
endmodule