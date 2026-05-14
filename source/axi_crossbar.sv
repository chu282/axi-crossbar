`timescale 1ns / 10ps

module axi_crossbar #(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter ID_WIDTH    = 4,
    parameter STRB_WIDTH  = (DATA_WIDTH/8),
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES  = 2,
) (
    input logic clk, n_rst,
);



endmodule

