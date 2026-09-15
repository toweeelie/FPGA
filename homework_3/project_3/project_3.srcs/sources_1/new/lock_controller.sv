`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 14.09.2026 14:59:35
// Design Name: 
// Module Name: lock_controller
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

import lock_controller_pkg::*;

module lock_controller(
    input logic clk,
    input logic rst,
    input logic [3:0] digit_in,
    output logic unlocked_led
    );

    state_t state = LOCKED, next_state = LOCKED;
    
    always_ff @(posedge clk or posedge rst) begin
        state <= (rst)? LOCKED : next_state;
    end
    
    always_comb begin
        next_state = state;
        case (state)
            LOCKED: 
                next_state = (digit_in == 4'd4)? WAIT_D2 : LOCKED;  
            WAIT_D2: 
                next_state = (digit_in == 4'd6)? WAIT_D3 : LOCKED;
            WAIT_D3: 
                next_state = (digit_in == 4'd8)? UNLOCKED : LOCKED;
            UNLOCKED: 
                next_state = UNLOCKED;
            default: 
                next_state = LOCKED;
        endcase
    end
    
    always_comb begin
        unlocked_led = (state == UNLOCKED)? 1 : 0;
    end
    
endmodule
