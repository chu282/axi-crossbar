`timescale 1ns / 10ps

module axi_addr_decoder #(
    // parameters
    parameter ADDR_WIDTH = 32,
    parameter NUM_SLAVES = 2,
    parameter [ADDR_WIDTH-1:0] base_addrs [NUM_SLAVES-1:0],
    parameter [ADDR_WIDTH-1:0] addr_masks [NUM_SLAVES-1:0]
) (
    input  logic valid,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [NUM_SLAVES-1:0] slave_select,
    output logic decerr
);

    always_comb begin
        slave_select = 0;
        for (int i = 0; i < NUM_SLAVES; i++) begin
            if (valid && (addr & addr_masks[i]) == base_addrs[i]) slave_select[i] = 1;
        end

        if (valid && slave_select == 0) decerr = 1;
        else decerr = 0;
    end

endmodule
