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


module tb_lock_controller();

    `include "lock_controller.vh"
    
    logic clk;
    logic rst;
    logic [3:0] digit_in;
    logic unlocked_led;
    
    lock_controller dut(
        .clk(clk),
        .rst(rst),
        .digit_in(digit_in),
        .unlocked_led(unlocked_led)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    
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
            digit_in = digits[i];
            @(posedge clk) #1;
            total_res = total_res && (dut.state === expected_states[i]);
            $display("key = %d, tst=%s, ref=%s", digits[i], dut.state, expected_states[i]);
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
