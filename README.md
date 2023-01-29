# Interrupt Controller
![intr_ctrl_layout](https://user-images.githubusercontent.com/63811852/215342049-737fef1a-bff0-462f-a79d-0cdba16a2542.png)

## Abstract
Constructed interrupt controller with Verilog HDL and implemented with 65nm CMOS technology. Utilized Synopsys tools such as `vcs`, `dc_shell`, and `icc2_shell`. Verilog simulations where generated with `vcs` and `dc_shell` was used for synthesis. Positive slack is achieved for maximum/minimum full path and total number of instances is less than 420. The interrupt controller is functional, working in normal mode and priority/polling mode. Given the synthesized Verilog, `icc2_shell` was used to perform design planning to generate the floorplan with appropriate PG planning. Moreover, placement optimization, clock-tree-synthesis, and routing optimization were conducted. Final layout passes all DRC checks, but has 2 LVS check errors due to VDD/VSS connectivity. 

## Start
Create necessary directories: 
  - `dumpster/`: store `.vcd` waveform files after `vcs`
  - `logs/`: store any log files and command history logs of `dc_shell` and `icc2_shell`
```
make init
```
## Pre-Synthesis Simulation
```
make pre
```

## Post-Synthesis Simulation
```
make post
```

## Layout (`floorplan`, `place_opt`, `clock_opt`, and `route_opt`)
```
make layout
```

## Clean Setup
```
make clean
```
