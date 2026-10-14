//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Wed Oct 14 20:28:19 2026
//Host        : iz-wb945156 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (btn_tri_i,
    clk_100MHz,
    data_in_0,
    reset_rtl_0);
  input [0:0]btn_tri_i;
  input clk_100MHz;
  input [7:0]data_in_0;
  input reset_rtl_0;

  wire [0:0]btn_tri_i;
  wire clk_100MHz;
  wire [7:0]data_in_0;
  wire reset_rtl_0;

  design_1 design_1_i
       (.btn_tri_i(btn_tri_i),
        .clk_100MHz(clk_100MHz),
        .data_in_0(data_in_0),
        .reset_rtl_0(reset_rtl_0));
endmodule
