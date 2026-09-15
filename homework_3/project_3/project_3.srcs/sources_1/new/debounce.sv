`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 14.09.2026 18:06:34
// Design Name: 
// Module Name: debounce
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


module debounce #(COUNT_MAX = 200_000)(
    input logic clk,
    input logic btn_raw,
    output logic btn_clean
);
    logic [$clog2(COUNT_MAX)-1:0] counter = 0;
    always_ff@(posedge clk) begin
        if(btn_raw != btn_clean) begin
            counter <= counter + 1;
            if(counter == COUNT_MAX) begin
                btn_clean <= btn_raw;
                counter <= 0;
            end            
        end else counter <= 0;
    end
endmodule
