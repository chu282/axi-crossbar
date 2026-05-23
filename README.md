# NxM AXI4-Crossbar
## Introduction
This project implements an in-order AXI4-Crossbar in SystemVerilog using **FuseSoC for package management, Verilator for linting/simulation, cocotb for verification, Surfer for waveform viewing, and Synopsys Design Compiler for synthesis**.

## Features

* **Parameterizability**: Configurable with NxM Masters/Slaves and supports full address/data/queue customizability.
* **In-Order Execution**: Transactions are completed in the order they were requested.
* **Skid Buffer Pipelining**: Pipelining done with skid buffers to eliminate handshake signal latency.
* **Round-Robin Arbitration**: Multiple device arbitration is done with round-robin granting.

#### Critical Path: *TBD*.

#### Max Clock Speed: *TBD*.

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
* `n_rst`: Active-low asynchronous reset.
* `m`: Array of AXI interfaces configured as slaves (`axi_if.slave`), representing connections to Masters.
* `s`: Array of AXI interfaces configured as masters (`axi_if.master`), representing connections to Slaves.

## Verification

This project uses **cocotb** with **Verilator** for simulation-based verification, and **Surfer** for waveform visualization.

### Prerequisites
Ensure you have the following installed in your environment:
* Verilator 5.0+
* Python 3.6.2+
* GNU Make 3+
* cocotb 2.0.x
* Surfer (for waveform viewing)

### Details

### Running Simulations
To run a simulation for a specific module (e.g., the address decoder or the mux), run:
```bash
# Run axi_addr_decoder.sv module verification
make sim_axi_addr_decoder

# Run axi_mux.sv module verification
make sim_axi_mux
```

## Implementation
![High level crossbar RTL diagram](images/axi.drawio.png)

You can view the diagram on drawio [here](https://drive.google.com/file/d/1dBV1LzKK90WF5i-RrpE6lwYEfy03LkbD/view?usp=sharing).

## Directory Structure
* `source/` — Core Verilog modules.
* `testbench/` — Simulation testbenches.
* `tb_wrappers/` — Wrapper modules for testbenches.
* `scripts/` — TCL scripts for synthesis.
* `cores/` — FuseSoC core files.
* `waves/` — Waveforms and their config files.
