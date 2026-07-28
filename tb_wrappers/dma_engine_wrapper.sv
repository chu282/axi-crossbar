`timescale 1ns / 10ps

module dma_engine_wrapper (
    input logic clk,
    input logic n_rst
);

    dma_engine dut (.*);

endmodule
