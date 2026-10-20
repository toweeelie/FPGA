`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 18:31:01
// Design Name: 
// Module Name: digital_echo_tb
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

import digital_echo_p::*;

module digital_echo_tb();
    localparam int ADDR_WIDTH = 5;
    localparam int DATA_WIDTH = 32;

    logic aclk = 1'b0;
    logic aresetn = 1'b0;

    // AXI write address channel
    logic [ADDR_WIDTH-1:0] awaddr = '0;
    logic                  awvalid = 0;
    wire                   awready;

    // AXI write data channel
    logic [DATA_WIDTH-1:0] wdata = '0;
    logic [DATA_WIDTH/8-1:0] wstrb = '0;
    logic                  wvalid = 0;
    wire                   wready;

    // AXI write response channel
    wire [1:0] bresp;
    wire       bvalid;
    logic      bready = 1;

    // AXI read address channel
    logic [ADDR_WIDTH-1:0] araddr = '0;
    logic                  arvalid = 0;
    wire                   arready;

    // AXI read data channel
    wire [DATA_WIDTH-1:0] rdata;
    wire [1:0]            rresp;
    wire                  rvalid;
    logic                 rready = 1;

    // Clock: 100 MHz
    always #5 aclk = ~aclk;

    // Replace my_axi_ip with your actual DUT module.
    digital_echo #(
        .AXI_ADDR_WIDTH(ADDR_WIDTH),
        .AXI_DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .s_axi_aclk    (aclk),
        .s_axi_aresetn (aresetn),

        .s_axi_awaddr  (awaddr),
        .s_axi_awvalid (awvalid),
        .s_axi_awready (awready),

        .s_axi_wdata   (wdata),
        .s_axi_wstrb   (wstrb),
        .s_axi_wvalid  (wvalid),
        .s_axi_wready  (wready),

        .s_axi_bresp   (bresp),
        .s_axi_bvalid  (bvalid),
        .s_axi_bready  (bready),

        .s_axi_araddr  (araddr),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),

        .s_axi_rdata   (rdata),
        .s_axi_rresp   (rresp),
        .s_axi_rvalid  (rvalid),
        .s_axi_rready  (rready)
    );

    // -----------------------------------------
    // AXI4-Lite write transaction
    // -----------------------------------------
    task automatic axi_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
        bit aw_done, w_done;

        aw_done = 0;
        w_done  = 0;

        // Drive requests away from the active clock edge.
        @(negedge aclk);
        awaddr  = addr;
        awvalid = 1;
        wdata   = data;
        wstrb   = '1;
        wvalid  = 1;

        // AW and W can handshake independently.
        while (!aw_done || !w_done) begin
            @(posedge aclk);

            if (awvalid && awready)
                aw_done = 1;

            if (wvalid && wready)
                w_done = 1;

            @(negedge aclk);

            if (aw_done)
                awvalid = 0;

            if (w_done)
                wvalid = 0;
        end

        // Wait for write response.
        do @(posedge aclk); while (!bvalid);

        if (bresp != 2'b00)
            $fatal(1, "AXI write error: addr=%h BRESP=%b",
                   addr, bresp);

        $display("[%0t] WRITE addr=%h data=%h",
                 $time, addr, data);

    endtask

    // -----------------------------------------
    // AXI4-Lite read transaction
    // -----------------------------------------
    task automatic axi_read(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data
    );

        @(negedge aclk);
        araddr  = addr;
        arvalid = 1;

        do @(posedge aclk); while (!arready);

        @(negedge aclk);
        arvalid = 0;

        // Wait for read response.
        do @(posedge aclk); while (!rvalid);

        data = rdata;

        if (rresp != 2'b00)
            $fatal(1, "AXI read error: addr=%h RRESP=%b",
                   addr, rresp);

        $display("[%0t] READ  addr=%h data=%h",
                 $time, addr, data);

    endtask


    // -----------------------------------------
    // Test environment
    // -----------------------------------------
    logic signed [DATA_WIDTH-1:0] write_values [23:0];
    logic signed [DATA_WIDTH-1:0] read_values [23:0];
    logic signed [DATA_WIDTH-1:0] expected_values [23:0];
    logic result = 1'b1;


    // -----------------------------------------
    // Single test
    // -----------------------------------------
    task automatic single_test(
        input int d,
        input int shift,
        input int len
    );
        
        axi_write(4*AXI_REG_IDX_D, d);
        axi_write(4*AXI_REG_IDX_SHIFT, shift);
        axi_write(4*AXI_REG_IDX_CTRL, 1);
        
        for(int i = 0; i < len; i++) begin
            axi_write(4*AXI_REG_IDX_IN, write_values[i]);
            axi_read (4*AXI_REG_IDX_OUT, read_values[i]);
            
            expected_values[i] = (i < d)? write_values[i] : write_values[i] + expected_values[i-d] >>> shift;
            if (expected_values[i] > 32'sd32767) begin expected_values[i] = 32'h00007fff; end
            if (expected_values[i] < -32'sd32768) begin expected_values[i] = 32'hFFFF8000; end
            
            if (read_values[i] !== expected_values[i]) begin
                $display("mismatch: idx %02d tst %08h, ref %08h", i, read_values[i], expected_values[i]);
                result = 1'b0;   
            end 
        end
        
    endtask

    // -----------------------------------------
    // Test sequence
    // -----------------------------------------

    initial begin
        $display("Starting Digital Echo module test");
    
        // Reset
        repeat (5) @(negedge aclk);
        aresetn = 1;

        repeat (2) @(negedge aclk);

        // case 1: D=4, SHIFT=1, in[0]=1000, in[1:23]={0}
        $display("Running test1");
        foreach(write_values[i])
            write_values[i] = 0;
        write_values[0] = 1000;
        single_test(4,1,24);
        
        // case 2: D=4, SHIFT=1, in[0]=-1000, in[1:23]={0}
        $display("Running test2");
        write_values[0] = -1000;
        single_test(4,1,24);

        // case 3: D=2, SHIFT=1, in={30000, 0, 30000, 0, 0, 0}
        $display("Running test3");
        write_values[0] = 30000;
        write_values[2] = 30000;
        single_test(2,1,6);

        $display("Digital Echo module test completed: %s", (result)? "PASS": "FAIL");
        $finish;
    end

    // Simulation timeout
    initial begin
        #100000;
        $fatal(1, "Testbench timeout");
    end

endmodule
