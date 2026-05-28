`timescale 1ns / 10ps

module axi_grant_tracker_wrapper #(
    parameter FIFO_DEPTH = 8,
    parameter NUM_MASTERS = 8
) (
    input  logic clk, n_rst, new_tx, tf_finished,
    input  logic [NUM_MASTERS-1:0] i_grant,
    output logic full,
    output logic [NUM_MASTERS-1:0] o_grant
);

    int test;
    axi_grant_tracker #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .NUM_MASTERS(NUM_MASTERS)
    ) dut (.*);

endmodule
