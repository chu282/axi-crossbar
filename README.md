# NxM AXI4-Crossbar
## Introduction
This project implements an in-order AXI4-Crossbar in SystemVerilog using **FuseSoC for package management, Verilator and ModelSim for linting/simulation, and Synopsys Design Compiler for synthesis**.
## Specifications

### Parameters
* `NUM_MASTERS`: Number of AXI master ports (default: `2`).
* `NUM_SLAVES`: Number of AXI slave ports (default: `2`).
* `ADDR_WIDTH`: Address bus width (default: `32`).
* `DATA_WIDTH`: Data bus width (default: `32`).
* `ID_WIDTH`: Transaction ID width (default: `4`).
* `MAX_OUTSTANDING_TX`: Maximum number of outstanding transactions supported by the grant trackers (default: `8`).

### Port List
The top-level module [axi_crossbar.sv](file:///c:/Users/dylan/Documents/vscode/axi-crossbar/source/axi_crossbar.sv) has the following ports:
* `clk`: System clock.
* `n_rst`: Active-low synchronous reset.
* `m`: Array of AXI interfaces configured as slaves (`axi_if.slave`), representing connections to Masters.
* `s`: Array of AXI interfaces configured as masters (`axi_if.master`), representing connections to Slaves.

### Critical Path
* *TBD*.

### Max Clock Speed
* *TBD*.

## Implementation
![High level crossbar RTL diagram](https://github.com/chu282/axi-crossbar/tree/main/images/axi.drawio.png)

You can view the diagram on drawio [here](https://drive.google.com/file/d/1dBV1LzKK90WF5i-RrpE6lwYEfy03LkbD/view?usp=sharing).

## Directory Structure
* `source/` — Core Verilog modules.
* `testbench/` — Simulation testbenches.
* `scripts/` — TCL scripts for synthesis.
* `waves/` — Waveform config files.
