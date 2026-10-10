//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sat Oct 10 11:29:18 2026
//Host        : iz-wb945156 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (btn_tri_i,
    clk_100MHz,
    led_tri_o,
    reset_rtl_0,
    sw_tri_i);
  input [2:0]btn_tri_i;
  input clk_100MHz;
  output [3:0]led_tri_o;
  input reset_rtl_0;
  input [0:0]sw_tri_i;

  wire [2:0]btn_tri_i;
  wire clk_100MHz;
  wire [3:0]led_tri_o;
  wire reset_rtl_0;
  wire [0:0]sw_tri_i;

  design_1 design_1_i
       (.btn_tri_i(btn_tri_i),
        .clk_100MHz(clk_100MHz),
        .led_tri_o(led_tri_o),
        .reset_rtl_0(reset_rtl_0),
        .sw_tri_i(sw_tri_i));
endmodule
