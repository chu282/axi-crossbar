`timescale 1ns / 10ps

module axi_decerr_handler_wrapper #(
    parameter ID_WIDTH = 4, 
    parameter PAYLOAD_WIDTH = 6
) (
    input  logic clk, n_rst, 
    input  logic skip_write, decerr, response_ready, write_valid, write_last, 
    input  logic [ID_WIDTH-1:0] address_id, 
    output logic response_valid, address_ready, write_ready, decerr_grant,
    output logic [PAYLOAD_WIDTH-1:0] response_payload
);

    axi_decerr_handler #(
        .ID_WIDTH(ID_WIDTH),
        .PAYLOAD_WIDTH(PAYLOAD_WIDTH)
    ) dut (.*);

endmodule
