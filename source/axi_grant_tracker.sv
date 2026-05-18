`timescale 1ns / 10ps

module axi_grant_tracker #(
    parameter FIFO_DEPTH = 8
) (
    input  logic clk, n_rst, new_trans,
    input  logic [NUM_SLAVES-1:0] trans_finished,
    output logic full,
    output logic [NUM_MASTERS-1:0] grant
);

    /*
    One fifo per non-address channel, controlling grant of each slave

    Push one on the top every time a new transactions starts

    Pop one off every time a transaction finishes
    */
    axi_fifo #(.DEPTH(FIFO_DEPTH), .WIDTH(NUM_MASTERS)) fifo (
        .push(new_trans),
        .pop(trans_finished),
        .top(grant),
        .full(full), .*
    );

endmodule
