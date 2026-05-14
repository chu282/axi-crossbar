interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) axi_if (
    input logic clk, n_rst
);

    // AW Channel
    logic [ID_WIDTH-1:0] awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic awvalid, awready;

    // W Channel
    logic [DATA_WIDTH-1:0] wdata;
    logic [STRB_WIDTH-1:0] wstrb;
    logic wvalid, wready, wlast;

    // B Channel
    logic [ID_WIDTH-1:0] bid;
    logic [1:0] bresp;
    logic bvalid, bready;

    // AR Channel
    logic [ID_WIDTH-1:0] arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic arvalid, arready;

    // R Channel
    logic [ID_WIDTH-1:0] rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid, rready, rlast;

    modport master (
        // outputs
        output awid, awaddr, awlen, awsize, awburst, awvalid,
        output wdata, wstrb, wlast, wvalid,
        output arid, araddr, arlen, arsize, arburst, arvalid,
        output bready, rready,
        // inputs
        input  awready, wready, arready,
        input  bid, bresp, bvalid,
        input  rid, rdata, rresp, rvalid, rlast
    );

    modport slave (
        // inputs
        input  awid, awaddr, awlen, awsize, awburst, awvalid,
        input  wdata, wstrb, wlast, wvalid,
        input  arid, araddr, arlen, arsize, arburst, arvalid,
        input  bready, rready,
        // outputs
        output awready, wready, arready,
        output bid, bresp, bvalid,
        output rid, rdata, rresp, rlast, rvalid
    );

endinterface