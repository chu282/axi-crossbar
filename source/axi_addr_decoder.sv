`timescale 1ns / 10ps

module axi_addr_decoder #(
    // parameters
    parameter ADDR_WIDTH = 32,
    parameter NUM_SLAVES = 2,
    parameter NUM_TOTAL_SLAVES = NUM_SLAVES + 1,
    parameter [ADDR_WIDTH-1:0] BASE_ADDRS [NUM_SLAVES-1:0],
    parameter [ADDR_WIDTH-1:0] ADDR_MASKS [NUM_SLAVES-1:0]
) (
    input  logic valid,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [NUM_TOTAL_SLAVES-1:0] slave_select
);

    always_comb begin
        slave_select = 0;
        for (int i = 0; i < NUM_SLAVES; i++) begin
            // Mask represents fixed bits in the address. 
            // If the current addr doesn't have the exact same bits in that location, 
            // then it isn't in the current slave.
            if (valid && (addr & ADDR_MASKS[i]) == BASE_ADDRS[i]) slave_select[i] = 1;
        end

        if (valid && slave_select[NUM_SLAVES-1:0] == 0) slave_select[NUM_SLAVES] = 1;
    end

endmodule
