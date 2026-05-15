`timescale 1ns / 10ps

module axi_mux #(
    parameter PAYLOAD_WIDTH = 49,
    parameter NUM_MASTERS   = 2
) (
    // Handshake 
    // Select one valid from masters
    input  logic [NUM_MASTERS-1:0] master_valid, 
    output logic slave_valid, 

    // Update correct master ready based on slave ready
    input  logic slave_ready, 
    output logic [NUM_MASTERS-1:0] master_ready, 

    // Payload
    input  logic [NUM_MASTERS-1:0] grant, 
    input  logic [PAYLOAD_WIDTH-1:0] master_payload [NUM_MASTERS-1:0],
    output logic [PAYLOAD_WIDTH-1:0] slave_payload
);

    always_comb begin
        slave_valid = |(master_valid & grant);
        master_ready = slave_ready ? grant : 0;
        slave_payload = 0;
        for (int i = 0; i < NUM_MASTERS; i++) begin
            if (grant[i]) begin
                slave_payload = master_payload[i];
            end
        end
    end

endmodule
