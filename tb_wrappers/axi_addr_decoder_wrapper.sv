`timescale 1ns / 10ps

module axi_addr_decoder_wrapper #(
    parameter ADDR_WIDTH = 16,
    parameter NUM_SLAVES = 4,
    parameter NUM_TOTAL_SLAVES = NUM_SLAVES + 1
) (
    input  logic valid,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [NUM_TOTAL_SLAVES-1:0] slave_select
);

    localparam [ADDR_WIDTH-1:0] BASE_ADDRS [NUM_SLAVES-1:0] = '{
        16'h8000, 16'h2000, 16'h0080, 16'h0000
    };
    localparam [ADDR_WIDTH-1:0] ADDR_MASKS [NUM_SLAVES-1:0] = '{
        16'h8000, 16'hE000, 16'hFF80, 16'hFFF0
    };

    // 0000 to 000F
    // 0080 to 00FF
    // 2000 to 3FFF
    // 8000 to FFFF
    axi_addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SLAVES(NUM_SLAVES),
        .NUM_TOTAL_SLAVES(NUM_TOTAL_SLAVES),
        .BASE_ADDRS(BASE_ADDRS),
        .ADDR_MASKS(ADDR_MASKS)
    ) dut (.*);

endmodule
