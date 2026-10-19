`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 09/02/2026 12:34:08 AM
// Design Name: 
// Module Name: decoder
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


module decoder #(WIDTH=4)(
    input  logic [$clog2(WIDTH)-1:0] addr,
    input  logic [WIDTH-1:0]idat,
    output logic odat
    );
    
    always_comb begin
        odat = idat[addr];
    end
    
endmodule


module decoder_wrapper(
    input  logic [2:0] addr,
    input  logic [7:0]idat,
    output logic [1:0] odat
    );
    
    decoder dec4(
        .addr(addr[1:0]),
        .idat(idat[3:0]),
        .odat(odat[0])
    );
    
    decoder #(.WIDTH(8)) dec8(
        .addr(addr),
        .idat(idat),
        .odat(odat[1])
    );
    
endmodule
