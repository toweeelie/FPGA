`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 04.09.2026 14:34:42
// Design Name: 
// Module Name: tb_counter
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


module tb_counter();

    reg clk;
    reg rst;
    reg load;
    reg [3:0] data_in;
    reg en;
    reg up_down;
    wire [3:0] count;
    
    counter cnt1 (
        .clk(clk),
        .rst(rst),
        .load(load),
        .data_in(data_in),
        .en(en),
        .up_down(up_down),
        .count(count)
        );
        
    initial clk = 0;
    always #5 clk = ~clk;
    
    task automatic check_count;
        input [15*8-1:0] name;
        input [3:0] expected;
        begin
            $display("Check %s: %s (tst=%d, ref=%d)", name, (count === expected)? "PASS": "FAIL", count, expected);
        end
    endtask
    
    initial begin
        @(posedge clk) #1;
        rst = 1; 
        @(posedge clk) #1;
        rst = 0;
        
        load = 1;
        data_in = 4'd10;
        @(posedge clk) #1;
        load = 0;
        check_count("load",10);
        
        en = 1; up_down = 1;
        @(posedge clk) #1;
        @(posedge clk) #1;
        @(posedge clk) #1;
        check_count("upcnt",13);
        
        @(posedge clk) #1;
        @(posedge clk) #1;
        @(posedge clk) #1;
        check_count("overflow",0);
        
        en = 0;
        @(posedge clk) #1;
        @(posedge clk) #1;
        check_count("en inactive",0);
        
        en = 1; up_down = 0;
        @(posedge clk) #1;
        check_count("downcnt+of",15);
        
        load = 1; data_in = 4'd5; en = 1; up_down = 1;
        @(posedge clk) #1;
        check_count("load priority",5);
        
        load = 0; en = 1; up_down = 0;
        @(posedge clk) #1;
        @(posedge clk) #1;
        check_count("downcnt",3);
        
        
    end 
endmodule
