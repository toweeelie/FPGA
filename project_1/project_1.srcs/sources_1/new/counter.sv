`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 02.09.2026 17:11:21
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
    input logic clock,
    input logic reset,
    output logic [3:0] cout = 0
    );
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset)
            cout <= 0;
        else
            cout <= cout + 1;
    end
    
endmodule
