`timescale 1ns / 10ps

module axi_fifo_wrapper #(
    parameter DEPTH = 8,
    parameter WIDTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
) (
    input  logic clk, n_rst, push, pop, 
    input  logic [WIDTH-1:0] in,
    output logic full, empty,
    output logic [WIDTH-1:0] out,
    output logic [PTR_WIDTH:0] count
);

    axi_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) dut (.*);

endmodule
