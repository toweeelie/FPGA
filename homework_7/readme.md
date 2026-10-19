# High-Level Synthesis

## Reproduction Steps

- Open Vitis IDE and import (`File -> Import`) [archive.zip](vitis/archive.zip) into the same folder similar to the way described in [homework_4](../homework_4/readme.md)
- Comment out line 19 (with pragma) of [moving_max.cpp](vitis/src/moving_max.cpp)
- Run `C Simulation` and `C Synthesis` and observe the following results
    ![synth_without_pragma](synth_without_pragma.png)
- Run `C/RTL Cosimulation` and observe the following results:
    ![cosim_without_pragma](cosim_without_pragma.png)
- Revert back all changes in [moving_max.cpp](vitis/src/moving_max.cpp)
- Run `C Simulation` and `C Synthesis` and observe the following results
    ![synth_with_pragma](synth_with_pragma.png)
- Run `C/RTL Cosimulation` and observe the following results:
    ![cosim_with_pragma](cosim_with_pragma.png)
- Run `Package`
- Open [project_1.xpr](vivado/project_1/project_1.xpr) with Vivado
- Run `Reports -> Report IP status` and update outdated IP
- Find `moving_max_0` IP in `Design Sources` and run `Reset Output Products`/`Generate Output Products` on it
- Run behavioral simulation and observe the following results:
    ![sim](sim.png)

## Description

Moving Max algo was implemented in C with HLS feature. 

Feature allows to build IP's written in C language and connect it to HDL projects.

Algo was tested in 2 enviroments (C and HDL):
- C testbench [moving_max_tb.cpp](vitis/src/moving_max_tb.cpp)
- System Verilog testbench [moving_max_tb.sv](vivado/project_1/project_1.srcs/sim_1/new/moving_max_tb.sv)
