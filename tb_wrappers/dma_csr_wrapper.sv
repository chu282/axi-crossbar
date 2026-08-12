`timescale 1ns / 10ps

module dma_csr_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter DATA_WIDTH = 32
) (
    input  logic clk, n_rst,

    input  logic [1:0] status,
    output logic start, ack_done, ack_err,
    output logic [31:0] length,
    output logic [ADDR_WIDTH-1:0] from_addr, to_addr,

    input  logic [ADDR_WIDTH-1:0] awaddr,
    input  logic [ID_WIDTH-1:0]   awid,
    input  logic [7:0]            awlen,
    input  logic [2:0]            awsize,
    input  logic [1:0]            awburst,
    input  logic                  awlock,
    input  logic                  awvalid,
    output logic                  awready,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [STRB_WIDTH-1:0] wstrb,
    input  logic                  wlast,
    input  logic                  wvalid,
    output logic                  wready,
    output logic [ID_WIDTH-1:0]   bid,
    output logic [1:0]            bresp,
    output logic                  bvalid,
    input  logic                  bready,
    input  logic [ADDR_WIDTH-1:0] araddr,
    input  logic [ID_WIDTH-1:0]   arid,
    input  logic [7:0]            arlen,
    input  logic [2:0]            arsize,
    input  logic [1:0]            arburst,
    input  logic                  arlock,
    input  logic                  arvalid,
    output logic                  arready,
    output logic [ID_WIDTH-1:0]   rid,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rlast,
    output logic                  rvalid,
    input  logic                  rready
);

    localparam STRB_WIDTH = DATA_WIDTH / 8;

    int test;

    axi_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) s ();

    assign s.awaddr = awaddr;
    assign s.awid = awid;
    assign s.awlen = awlen;
    assign s.awsize = awsize;
    assign s.awburst = awburst;
    assign s.awlock = awlock;
    assign s.awvalid = awvalid;
    assign awready = s.awready;

    assign s.wdata = wdata;
    assign s.wstrb = wstrb;
    assign s.wlast = wlast;
    assign s.wvalid = wvalid;
    assign wready = s.wready;

    assign bid = s.bid;
    assign bresp = s.bresp;
    assign bvalid = s.bvalid;
    assign s.bready = bready;
    
    assign s.araddr = araddr;
    assign s.arid = arid;
    assign s.arlen = arlen;
    assign s.arsize = arsize;
    assign s.arburst = arburst;
    assign s.arlock = arlock;
    assign s.arvalid = arvalid;
    assign arready = s.arready;
    
    assign rid = s.rid;
    assign rdata = s.rdata;
    assign rresp = s.rresp;
    assign rlast = s.rlast;
    assign rvalid = s.rvalid;
    assign s.rready = rready;

    dma_csr #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (.*);

endmodule
