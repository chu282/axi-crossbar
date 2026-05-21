`timescale 1ns / 10ps

module axi_grant_tracker #(
    parameter FIFO_DEPTH = 8,
    parameter NUM_MASTERS = 2,
) (
    input  logic clk, n_rst, new_tx, tf_finished,
    input  logic [NUM_MASTERS-1:0] i_grant,
    output logic full,
    output logic [NUM_MASTERS-1:0] o_grant
);

    /*
    One fifo per non-address channel, controlling grant of each slave.
    Push one on the top every time a new transactions starts,
    pop one off every time a transaction finishes.
    */

    /* verilator lint_off PINCONNECTEMPTY */
    axi_fifo #(.DEPTH(FIFO_DEPTH), .WIDTH(NUM_MASTERS)) fifo (
        .push(new_tx),
        .in(i_grant),
        .pop(tf_finished),
        .out(o_grant),
        .full(full), 
        .empty(), .*
    );

endmodule
