`timescale 1ns / 10ps

module axi_fifo_wrapper #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
) (
    input  logic clk, n_rst, push, pop, 
    input  logic [WIDTH-1:0] in,
    output logic full, empty,
    output logic [WIDTH-1:0] out
);

    axi_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) dut (.*);

endmodule
