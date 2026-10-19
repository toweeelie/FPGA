`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 04.09.2026 14:19:11
// Design Name: 
// Module Name: counter
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


module counter(
    input wire clk,
    input wire rst,
    input wire load,
    input wire [3:0] data_in,
    input wire en,
    input wire up_down,
    output reg [3:0] count
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) 
            count <= 0;
        else begin
            if (load)
                count <= data_in;
            else if (en) begin
                if (up_down)
                    count <= count+1;   
                else                
                    count <= count-1; 
            end
        end
    end
    
endmodule
