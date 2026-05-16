`timescale 1ns / 10ps

module axi_mux #(
    parameter PAYLOAD_WIDTH = 49,
    parameter NUM_DEVICES   = 2
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

    always_comb begin
        dst_valid = |(src_valid & grant);
        src_ready = dst_ready ? grant : 0;
        dst_payload = 0;
        for (int i = 0; i < NUM_DEVICES; i++) begin
            if (grant[i]) begin
                dst_payload = src_payload[i];
            end
        end
    end

endmodule
