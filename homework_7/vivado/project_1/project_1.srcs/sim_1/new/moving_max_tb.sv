`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2026 14:50:27
// Design Name: 
// Module Name: moving_max_tb
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


module moving_max_tb();

    localparam N_SAMPLES = 64;
    localparam WINDOW    = 8;
    // RAM latency
    localparam RD_LAT    = 1;

    reg clk = 1'b0;
    reg rst = 1'b1;          // ap_rst high level active
    reg ap_start = 1'b0;
    wire ap_done, ap_idle, ap_ready;

    wire [4:0]  in_data_address0;
    wire        in_data_ce0;
    wire [31:0] in_data_q0;
    wire [4:0]  out_data_address0;
    wire        out_data_ce0;
    wire        out_data_we0;
    wire [31:0] out_data_d0;

    always #5 clk = ~clk;    // 100 MHz

    // ---------- DUT ----------
    moving_max_0 dut (
        .ap_clk            (clk),
        .ap_rst            (rst),
        .ap_start          (ap_start),
        .ap_done           (ap_done),
        .ap_idle           (ap_idle),
        .ap_ready          (ap_ready),
        .in_data_address0  (in_data_address0),
        .in_data_ce0       (in_data_ce0),
        .in_data_q0        (in_data_q0),
        .out_data_address0 (out_data_address0),
        .out_data_ce0      (out_data_ce0),
        .out_data_we0      (out_data_we0),
        .out_data_d0       (out_data_d0)
    );

    // ---------- external RAM models ----------
    reg [31:0] mem_in  [0:N_SAMPLES-1];
    reg [31:0] mem_out [0:N_SAMPLES-1];
    reg [31:0] q_a, q_b;

    always @(posedge clk) begin
        if (in_data_ce0) q_a <= mem_in[in_data_address0];
        q_b <= q_a;
        if (out_data_ce0 && out_data_we0) mem_out[out_data_address0] <= out_data_d0;
    end
    assign in_data_q0 = (RD_LAT == 1) ? q_a : q_b;

    // ---------- Reference ----------
    reg [31:0] ref_data [0:N_SAMPLES-1];

    task make_ref_data;
        integer n, k, max_val;
        begin
            for (n = 0; n < N_SAMPLES; n = n + 1) begin
                max_val = mem_in[n];
                for (k = n - 1; k > n - WINDOW; k = k - 1) begin
                    if (k < 0) begin
                        continue;
                    end
                    if ($signed(max_val) < $signed(mem_in[k])) begin
                        max_val = mem_in[k];
                    end
                end
                ref_data[n] = max_val;
            end
        end
    endtask

    // ---------- single ap_ctrl_hs call ----------
    integer errors;

    task run_once;
        integer cnt;
        begin
            @(negedge clk);
            ap_start = 1'b1;
            @(negedge clk);
            cnt = 0;
            while (!ap_ready && cnt < 2000) begin
                @(negedge clk);
                cnt = cnt + 1;
            end
            if (!ap_ready) begin
                $display("TIMEOUT: ap_ready never came");
                errors = errors + 1;
            end
            ap_start = 1'b0;
            cnt = 0;
            while (!ap_idle && cnt < 100) begin
                @(negedge clk);
                cnt = cnt + 1;
            end
        end
    endtask

    // main case
    reg [31:0] seed;

    initial begin
        errors = 0;
        seed   = 32'd12345;
        repeat (5) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);

        for (int t = 0; t < 5; t = t + 1) begin
            for (int n = 0; n < N_SAMPLES; n = n + 1) begin
                seed = seed * 32'd1103515245 + 32'd12345;
                mem_in[n]  = (seed >> 16) % 1000;
                mem_out[n] = 32'hDEADBEEF;
            end
            make_ref_data;
            run_once;
            repeat (3) @(negedge clk);
            for (int n = 0; n < N_SAMPLES; n = n + 1) begin
                if (mem_out[n] !== ref_data[n]) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("MISMATCH: call %0d, sample %0d: DUT=%0d, ref=%0d",
                                 t, n, mem_out[n], ref_data[n]);
                end
            end
        end

        if (errors == 0) $display("Test passed !");
        else             $display("Test FAILED: %0d errors", errors);
        $finish;
    end

    // hang up handling
    initial begin
        #200000;
        $display("TIMEOUT: simulation too long");
        $finish;
    end

endmodule
