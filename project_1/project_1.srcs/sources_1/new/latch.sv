`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 02.09.2026 15:47:03
// Design Name: 
// Module Name: latch
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

//`define FIX_LATCH

module latch(
    input logic linp0,
    input logic linp1,
    output logic lout
    );
    
    always_comb begin
        if (linp0)
            lout = linp1;
`ifdef FIX_LATCH
        else
            lout = 0;
`endif
    end
    
endmodule
