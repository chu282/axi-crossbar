`timescale 1ns / 10ps

module dma_engine_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = 4,
    parameter ID_WIDTH = 4,
    parameter FIFO_DEPTH = 16 // words
) (
    input  logic clk, n_rst,

    input  logic start, ack_done, ack_err,
    input  logic [31:0] length,
    input  logic [ADDR_WIDTH-1:0] from_addr, to_addr,
    output logic [1:0] status,

    output logic [ADDR_WIDTH-1:0] awaddr,
    output logic [ID_WIDTH-1:0]   awid,
    output logic [7:0]            awlen,
    output logic [2:0]            awsize,
    output logic [1:0]            awburst,
    output logic                  awlock,
    output logic                  awvalid,
    input  logic                  awready,

    output logic [DATA_WIDTH-1:0] wdata,
    output logic [STRB_WIDTH-1:0] wstrb,
    output logic                  wlast,
    output logic                  wvalid,
    input  logic                  wready,

    input  logic [ID_WIDTH-1:0]   bid,
    input  logic [1:0]            bresp,
    input  logic                  bvalid,
    output logic                  bready,

    output logic [ADDR_WIDTH-1:0] araddr,
    output logic [ID_WIDTH-1:0]   arid,
    output logic [7:0]            arlen,
    output logic [2:0]            arsize,
    output logic [1:0]            arburst,
    output logic                  arlock,
    output logic                  arvalid,
    input  logic                  arready,

    input  logic [ID_WIDTH-1:0]   rid,
    input  logic [DATA_WIDTH-1:0] rdata,
    input  logic [1:0]            rresp,
    input  logic                  rlast,
    input  logic                  rvalid,
    output logic                  rready
);

    int test;

    axi_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) m ();

    assign awaddr  = m.awaddr;
    assign awid    = m.awid;
    assign awlen   = m.awlen;
    assign awsize  = m.awsize;
    assign awburst = m.awburst;
    assign awlock  = m.awlock;
    assign awvalid = m.awvalid;
    assign m.awready = awready;

    assign wdata   = m.wdata;
    assign wstrb   = m.wstrb;
    assign wlast   = m.wlast;
    assign wvalid  = m.wvalid;
    assign m.wready  = wready;

    assign m.bid   = bid;
    assign m.bresp = bresp;
    assign m.bvalid = bvalid;
    assign bready  = m.bready;

    assign araddr  = m.araddr;
    assign arid    = m.arid;
    assign arlen   = m.arlen;
    assign arsize  = m.arsize;
    assign arburst = m.arburst;
    assign arlock  = m.arlock;
    assign arvalid = m.arvalid;
    assign m.arready = arready;

    assign m.rid   = rid;
    assign m.rdata = rdata;
    assign m.rresp = rresp;
    assign m.rlast = rlast;
    assign m.rvalid = rvalid;
    assign rready  = m.rready;

    dma_engine #( 
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (.*);

endmodule
