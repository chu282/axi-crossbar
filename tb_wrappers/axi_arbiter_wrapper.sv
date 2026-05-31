`timescale 1ns / 10ps

module axi_arbiter_wrapper #(
    parameter NUM_DEVICES = 8
) (
    input  logic clk, n_rst, tf_finished,
    input  logic [NUM_DEVICES-1:0] request,
    output logic [NUM_DEVICES-1:0] grant
);

    int test;
    axi_arbiter #(
        .NUM_DEVICES(NUM_DEVICES)
    ) dut (.*);

endmodule
