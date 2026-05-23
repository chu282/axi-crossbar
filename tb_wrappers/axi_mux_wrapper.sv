`timescale 1ns / 10ps

module axi_mux_wrapper #(
    parameter PAYLOAD_WIDTH = 49,
    parameter NUM_DEVICES = 8
) (
    // Handshake 
    // Select one valid from sources
    input  logic [NUM_DEVICES-1:0] src_valid, 
    output logic dst_valid, 

    // Update correct src_ready based on dst_ready
    input  logic dst_ready, 
    output logic [NUM_DEVICES-1:0] src_ready, 

    // Payload
    input  logic [NUM_DEVICES-1:0] grant, 
    input  logic [PAYLOAD_WIDTH-1:0] src_payload [NUM_DEVICES-1:0],
    output logic [PAYLOAD_WIDTH-1:0] dst_payload
);

    axi_mux #(
        .PAYLOAD_WIDTH(PAYLOAD_WIDTH),
        .NUM_DEVICES(NUM_DEVICES)
    ) dut (.*);

endmodule
