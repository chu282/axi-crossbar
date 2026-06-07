`timescale 1ns / 10ps

module axi_crossbar_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES = 2,
    parameter MAX_OUTSTANDING_TX = 8
) (
    input  logic clk, n_rst,

    // Master 0
    input  logic [ADDR_WIDTH-1:0] m0_awaddr,
    input  logic [ID_WIDTH-1:0]   m0_awid,
    input  logic [7:0]            m0_awlen,
    input  logic [2:0]            m0_awsize,
    input  logic [1:0]            m0_awburst,
    input  logic                  m0_awlock,
    input  logic                  m0_awvalid,
    output logic                  m0_awready,
    input  logic [DATA_WIDTH-1:0] m0_wdata,
    input  logic [STRB_WIDTH-1:0] m0_wstrb,
    input  logic                  m0_wlast,
    input  logic                  m0_wvalid,
    output logic                  m0_wready,
    output logic [ID_WIDTH-1:0]   m0_bid,
    output logic [1:0]            m0_bresp,
    output logic                  m0_bvalid,
    input  logic                  m0_bready,
    input  logic [ADDR_WIDTH-1:0] m0_araddr,
    input  logic [ID_WIDTH-1:0]   m0_arid,
    input  logic [7:0]            m0_arlen,
    input  logic [2:0]            m0_arsize,
    input  logic [1:0]            m0_arburst,
    input  logic                  m0_arlock,
    input  logic                  m0_arvalid,
    output logic                  m0_arready,
    output logic [ID_WIDTH-1:0]   m0_rid,
    output logic [DATA_WIDTH-1:0] m0_rdata,
    output logic [1:0]            m0_rresp,
    output logic                  m0_rlast,
    output logic                  m0_rvalid,
    input  logic                  m0_rready,

    // Master 1
    input  logic [ADDR_WIDTH-1:0] m1_awaddr,
    input  logic [ID_WIDTH-1:0]   m1_awid,
    input  logic [7:0]            m1_awlen,
    input  logic [2:0]            m1_awsize,
    input  logic [1:0]            m1_awburst,
    input  logic                  m1_awlock,
    input  logic                  m1_awvalid,
    output logic                  m1_awready,
    input  logic [DATA_WIDTH-1:0] m1_wdata,
    input  logic [STRB_WIDTH-1:0] m1_wstrb,
    input  logic                  m1_wlast,
    input  logic                  m1_wvalid,
    output logic                  m1_wready,
    output logic [ID_WIDTH-1:0]   m1_bid,
    output logic [1:0]            m1_bresp,
    output logic                  m1_bvalid,
    input  logic                  m1_bready,
    input  logic [ADDR_WIDTH-1:0] m1_araddr,
    input  logic [ID_WIDTH-1:0]   m1_arid,
    input  logic [7:0]            m1_arlen,
    input  logic [2:0]            m1_arsize,
    input  logic [1:0]            m1_arburst,
    input  logic                  m1_arlock,
    input  logic                  m1_arvalid,
    output logic                  m1_arready,
    output logic [ID_WIDTH-1:0]   m1_rid,
    output logic [DATA_WIDTH-1:0] m1_rdata,
    output logic [1:0]            m1_rresp,
    output logic                  m1_rlast,
    output logic                  m1_rvalid,
    input  logic                  m1_rready,

    // Slave 0
    output logic [ADDR_WIDTH-1:0] s0_awaddr,
    output logic [ID_WIDTH-1:0]   s0_awid,
    output logic [7:0]            s0_awlen,
    output logic [2:0]            s0_awsize,
    output logic [1:0]            s0_awburst,
    output logic                  s0_awlock,
    output logic                  s0_awvalid,
    input  logic                  s0_awready,
    output logic [DATA_WIDTH-1:0] s0_wdata,
    output logic [STRB_WIDTH-1:0] s0_wstrb,
    output logic                  s0_wlast,
    output logic                  s0_wvalid,
    input  logic                  s0_wready,
    input  logic [ID_WIDTH-1:0]   s0_bid,
    input  logic [1:0]            s0_bresp,
    input  logic                  s0_bvalid,
    output logic                  s0_bready,
    output logic [ADDR_WIDTH-1:0] s0_araddr,
    output logic [ID_WIDTH-1:0]   s0_arid,
    output logic [7:0]            s0_arlen,
    output logic [2:0]            s0_arsize,
    output logic [1:0]            s0_arburst,
    output logic                  s0_arlock,
    output logic                  s0_arvalid,
    input  logic                  s0_arready,
    input  logic [ID_WIDTH-1:0]   s0_rid,
    input  logic [DATA_WIDTH-1:0] s0_rdata,
    input  logic [1:0]            s0_rresp,
    input  logic                  s0_rlast,
    input  logic                  s0_rvalid,
    output logic                  s0_rready,

    // Slave 1
    output logic [ADDR_WIDTH-1:0] s1_awaddr,
    output logic [ID_WIDTH-1:0]   s1_awid,
    output logic [7:0]            s1_awlen,
    output logic [2:0]            s1_awsize,
    output logic [1:0]            s1_awburst,
    output logic                  s1_awlock,
    output logic                  s1_awvalid,
    input  logic                  s1_awready,
    output logic [DATA_WIDTH-1:0] s1_wdata,
    output logic [STRB_WIDTH-1:0] s1_wstrb,
    output logic                  s1_wlast,
    output logic                  s1_wvalid,
    input  logic                  s1_wready,
    input  logic [ID_WIDTH-1:0]   s1_bid,
    input  logic [1:0]            s1_bresp,
    input  logic                  s1_bvalid,
    output logic                  s1_bready,
    output logic [ADDR_WIDTH-1:0] s1_araddr,
    output logic [ID_WIDTH-1:0]   s1_arid,
    output logic [7:0]            s1_arlen,
    output logic [2:0]            s1_arsize,
    output logic [1:0]            s1_arburst,
    output logic                  s1_arlock,
    output logic                  s1_arvalid,
    input  logic                  s1_arready,
    input  logic [ID_WIDTH-1:0]   s1_rid,
    input  logic [DATA_WIDTH-1:0] s1_rdata,
    input  logic [1:0]            s1_rresp,
    input  logic                  s1_rlast,
    input  logic                  s1_rvalid,
    output logic                  s1_rready
);

    // Interfaces
    axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .STRB_WIDTH(STRB_WIDTH))
            m[NUM_MASTERS-1:0] (clk, n_rst);
    axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .STRB_WIDTH(STRB_WIDTH))
            s[NUM_SLAVES-1:0] (clk, n_rst);

    // m0 if ports
    assign m[0].awaddr  = m0_awaddr;
    assign m[0].awid    = m0_awid;
    assign m[0].awlen   = m0_awlen;
    assign m[0].awsize  = m0_awsize;
    assign m[0].awburst = m0_awburst;
    assign m[0].awlock  = m0_awlock;
    assign m[0].awvalid = m0_awvalid;
    assign m0_awready      = m[0].awready;
    assign m[0].wdata   = m0_wdata;
    assign m[0].wstrb   = m0_wstrb;
    assign m[0].wlast   = m0_wlast;
    assign m[0].wvalid  = m0_wvalid;
    assign m0_wready       = m[0].wready;
    assign m0_bid          = m[0].bid;
    assign m0_bresp        = m[0].bresp;
    assign m0_bvalid       = m[0].bvalid;
    assign m[0].bready  = m0_bready;
    assign m[0].araddr  = m0_araddr;
    assign m[0].arid    = m0_arid;
    assign m[0].arlen   = m0_arlen;
    assign m[0].arsize  = m0_arsize;
    assign m[0].arburst = m0_arburst;
    assign m[0].arlock  = m0_arlock;
    assign m[0].arvalid = m0_arvalid;
    assign m0_arready      = m[0].arready;
    assign m0_rid          = m[0].rid;
    assign m0_rdata        = m[0].rdata;
    assign m0_rresp        = m[0].rresp;
    assign m0_rlast        = m[0].rlast;
    assign m0_rvalid       = m[0].rvalid;
    assign m[0].rready  = m0_rready;

    // m1 if ports
    assign m[1].awaddr  = m1_awaddr;
    assign m[1].awid    = m1_awid;
    assign m[1].awlen   = m1_awlen;
    assign m[1].awsize  = m1_awsize;
    assign m[1].awburst = m1_awburst;
    assign m[1].awlock  = m1_awlock;
    assign m[1].awvalid = m1_awvalid;
    assign m1_awready      = m[1].awready;
    assign m[1].wdata   = m1_wdata;
    assign m[1].wstrb   = m1_wstrb;
    assign m[1].wlast   = m1_wlast;
    assign m[1].wvalid  = m1_wvalid;
    assign m1_wready       = m[1].wready;
    assign m1_bid          = m[1].bid;
    assign m1_bresp        = m[1].bresp;
    assign m1_bvalid       = m[1].bvalid;
    assign m[1].bready  = m1_bready;
    assign m[1].araddr  = m1_araddr;
    assign m[1].arid    = m1_arid;
    assign m[1].arlen   = m1_arlen;
    assign m[1].arsize  = m1_arsize;
    assign m[1].arburst = m1_arburst;
    assign m[1].arlock  = m1_arlock;
    assign m[1].arvalid = m1_arvalid;
    assign m1_arready      = m[1].arready;
    assign m1_rid          = m[1].rid;
    assign m1_rdata        = m[1].rdata;
    assign m1_rresp        = m[1].rresp;
    assign m1_rlast        = m[1].rlast;
    assign m1_rvalid       = m[1].rvalid;
    assign m[1].rready  = m1_rready;

    // s0 if ports
    assign s0_awaddr       = s[0].awaddr;
    assign s0_awid         = s[0].awid;
    assign s0_awlen        = s[0].awlen;
    assign s0_awsize       = s[0].awsize;
    assign s0_awburst      = s[0].awburst;
    assign s0_awlock       = s[0].awlock;
    assign s0_awvalid      = s[0].awvalid;
    assign s[0].awready = s0_awready;
    assign s0_wdata        = s[0].wdata;
    assign s0_wstrb        = s[0].wstrb;
    assign s0_wlast        = s[0].wlast;
    assign s0_wvalid       = s[0].wvalid;
    assign s[0].wready  = s0_wready;
    assign s[0].bid     = s0_bid;
    assign s[0].bresp   = s0_bresp;
    assign s[0].bvalid  = s0_bvalid;
    assign s0_bready       = s[0].bready;
    assign s0_araddr       = s[0].araddr;
    assign s0_arid         = s[0].arid;
    assign s0_arlen        = s[0].arlen;
    assign s0_arsize       = s[0].arsize;
    assign s0_arburst      = s[0].arburst;
    assign s0_arlock       = s[0].arlock;
    assign s0_arvalid      = s[0].arvalid;
    assign s[0].arready = s0_arready;
    assign s[0].rid     = s0_rid;
    assign s[0].rdata   = s0_rdata;
    assign s[0].rresp   = s0_rresp;
    assign s[0].rlast   = s0_rlast;
    assign s[0].rvalid  = s0_rvalid;
    assign s0_rready       = s[0].rready;

    // s1 if ports
    assign s1_awaddr       = s[1].awaddr;
    assign s1_awid         = s[1].awid;
    assign s1_awlen        = s[1].awlen;
    assign s1_awsize       = s[1].awsize;
    assign s1_awburst      = s[1].awburst;
    assign s1_awlock       = s[1].awlock;
    assign s1_awvalid      = s[1].awvalid;
    assign s[1].awready = s1_awready;
    assign s1_wdata        = s[1].wdata;
    assign s1_wstrb        = s[1].wstrb;
    assign s1_wlast        = s[1].wlast;
    assign s1_wvalid       = s[1].wvalid;
    assign s[1].wready  = s1_wready;
    assign s[1].bid     = s1_bid;
    assign s[1].bresp   = s1_bresp;
    assign s[1].bvalid  = s1_bvalid;
    assign s1_bready       = s[1].bready;
    assign s1_araddr       = s[1].araddr;
    assign s1_arid         = s[1].arid;
    assign s1_arlen        = s[1].arlen;
    assign s1_arsize       = s[1].arsize;
    assign s1_arburst      = s[1].arburst;
    assign s1_arlock       = s[1].arlock;
    assign s1_arvalid      = s[1].arvalid;
    assign s[1].arready = s1_arready;
    assign s[1].rid     = s1_rid;
    assign s[1].rdata   = s1_rdata;
    assign s[1].rresp   = s1_rresp;
    assign s[1].rlast   = s1_rlast;
    assign s[1].rvalid  = s1_rvalid;
    assign s1_rready    = s[1].rready;
    

    axi_crossbar #(
        .NUM_MASTERS(NUM_MASTERS),
        .NUM_SLAVES(NUM_SLAVES),
        .MAX_OUTSTANDING_TX(MAX_OUTSTANDING_TX),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) dut (.*);

endmodule
