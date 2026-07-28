interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4
) ();

    localparam STRB_WIDTH = DATA_WIDTH / 8;

    // AW Channel
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [ID_WIDTH-1:0] awid;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic awlock;
    logic awvalid, awready;

    // W Channel
    logic [DATA_WIDTH-1:0] wdata;
    logic [STRB_WIDTH-1:0] wstrb;
    logic wlast;
    logic wvalid, wready;

    // B Channel
    logic [ID_WIDTH-1:0] bid;
    logic [1:0] bresp;
    logic bvalid, bready;

    // AR Channel
    logic [ADDR_WIDTH-1:0] araddr;
    logic [ID_WIDTH-1:0] arid;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic arlock;
    logic arvalid, arready;

    // R Channel
    logic [ID_WIDTH-1:0] rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rlast;
    logic rvalid, rready;

    modport master (
        // outputs
        output awaddr, awid, awlen, awsize, awburst, awlock, awvalid,
        output wdata, wstrb, wlast, wvalid,
        output araddr, arid, arlen, arsize, arburst, arlock, arvalid,
        output bready, rready,
        // inputs
        input  awready, wready, arready,
        input  bid, bresp, bvalid,
        input  rid, rdata, rresp, rlast, rvalid
    );

    modport slave (
        // inputs
        input  awaddr, awid, awlen, awsize, awburst, awlock, awvalid,
        input  wdata, wstrb, wlast, wvalid,
        input  araddr, arid, arlen, arsize, arburst, arlock, arvalid,
        input  bready, rready,
        // outputs
        output awready, wready, arready,
        output bid, bresp, bvalid,
        output rid, rdata, rresp, rlast, rvalid
    );

endinterface
