`timescale 1ns / 10ps

module axi_skid_buffer_wrapper #(
    parameter PAYLOAD_WIDTH = 8
) (
    input logic clk, n_rst, src_valid, dst_ready, 
    input logic [PAYLOAD_WIDTH-1:0] src_payload,
    output logic dst_valid, src_ready,
    output logic [PAYLOAD_WIDTH-1:0] dst_payload
);

    int test;
    axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH)) axi_sb (.*);

endmodule
