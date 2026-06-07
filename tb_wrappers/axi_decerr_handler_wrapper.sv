`timescale 1ns / 10ps

module axi_decerr_handler_wrapper #(
    parameter ID_WIDTH = 4,
    parameter LEN_WIDTH = 8
) (
    input  logic clk, n_rst, 
    input  logic write, decerr, response_ready, write_valid, write_last, 
    input  logic [ID_WIDTH-1:0] address_id, 
    input  logic [LEN_WIDTH-1:0] read_len,
    output logic response_valid, response_last, address_ready, write_ready, decerr_grant,
    output logic [ID_WIDTH-1:0] response_id,
    output logic [1:0] response_resp
);

    axi_decerr_handler #(
        .ID_WIDTH(ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) dut (.*);

endmodule
