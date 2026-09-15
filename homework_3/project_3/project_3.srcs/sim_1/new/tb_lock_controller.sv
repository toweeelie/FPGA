`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tnovokhatko
// 
// Create Date: 14.09.2026 15:26:27
// Design Name: 
// Module Name: tb_lock_controller
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
`define BTN_BOUNCE 3
import lock_controller_pkg::*;

module tb_lock_controller();

    logic clk;
    logic rst;
    logic [3:0] digit_raw;
    logic [3:0] digit_clean;
    logic unlocked_led;
    
    debounce #(.COUNT_MAX(`BTN_BOUNCE)) dbn [3:0] (
        .clk(clk), 
        .btn_raw(digit_raw[3:0]),
        .btn_clean(digit_clean[3:0])
    );

    lock_controller dut(
        .clk(clk),
        .rst(rst),
        .digit_in(digit_clean),
        .unlocked_led(unlocked_led)
    );
    
    initial clk = 0;
    always #2 clk = ~clk;
    
    task automatic check_states(
        input logic [20*8-1:0] name,
        input logic [3:0] digits[],
        input state_t expected_states[]
    );
        logic total_res = 1;
        
        $display("Check %s:", name);
        
        // reset controller
        @(posedge clk) #1;
        rst = 1; 
        @(posedge clk) #1;
        rst = 0;  
        
        // iterate over number of inputs and check state
        for (int i = 0; i < digits.size(); i++) begin
            // button bounce 
            for (int j = 0; j < `BTN_BOUNCE; j++) begin
                digit_raw = 0;
                @(posedge clk) #1;
                digit_raw = digits[i];
                @(posedge clk) #1;
            end
            // button steady state "pressed"
            for (int j = 0; j < `BTN_BOUNCE; j++) begin
                @(posedge clk) #1;
                @(posedge clk) #1;
            end
            
            // check DUT state
            total_res = total_res && (dut.state === expected_states[i]);
            $display("key = %d, tst=%s, ref=%s", digits[i], dut.state, expected_states[i]);
            
            // button bounce 
            for (int j = 0; j < `BTN_BOUNCE; j++) begin
                digit_raw = 0;
                @(posedge clk) #1;
                digit_raw = digits[i];
                @(posedge clk) #1;
            end
            // buttons steady state "released"
            digit_raw = 0;
            for (int j = 0; j < `BTN_BOUNCE; j++) begin
                @(posedge clk) #1;
                @(posedge clk) #1;
            end
        end
        
        // display total result
        $display("Result %s\n",(total_res)? "PASS": "FAIL");

    endtask
    
    initial begin
        check_states(
            "right sequence",
            '{4,6,8},
            '{WAIT_D2,WAIT_D3,UNLOCKED}
        );
        
        check_states(
            "1st digit wrong",
            '{5},
            '{LOCKED}
        );
        
        check_states(
            "2nd digit wrong",
            '{4,5},
            '{WAIT_D2,LOCKED}
        );
        
        check_states(
            "3rd digit wrong",
            '{4,6,5},
            '{WAIT_D2,WAIT_D3,LOCKED}
        );
        
        $finish;
    end
endmodule
