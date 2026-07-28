`timescale 1ns / 10ps

module dma_csr_wrapper (
    input logic clk,
    input logic n_rst
);

    dma_csr dut (.*);

endmodule
