`timescale 1ns / 10ps

module axi_crossbar_dma_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES = 2,
    parameter FIFO_DEPTH = 16,
    parameter MAX_OUTSTANDING_TX = 8,

    // Slave 0 (SRAM): 0x0000_0000 -> 0x7FFF_FFFF (Base: 0x0000_0000, Mask: 0x8000_0000)
    // Slave 1 (DMA CSR): 0x8000_0000 -> 0x8000_0FFF (Base: 0x8000_0000, Mask: 0x7FFF_F000)
    parameter [ADDR_WIDTH-1:0] SLAVE_BASE_ADDR [NUM_SLAVES-1:0] = '{32'h8000_0000, 32'h0000_0000},
    parameter [ADDR_WIDTH-1:0] SLAVE_ADDR_MASK [NUM_SLAVES-1:0] = '{32'hFFFF_F000, 32'h8000_0000}
) (
    input  logic clk, n_rst,

    // cpu_m
    input  logic [ADDR_WIDTH-1:0]    m0_awaddr,
    input  logic [ID_WIDTH-1:0]      m0_awid,
    input  logic [7:0]               m0_awlen,
    input  logic [2:0]               m0_awsize,
    input  logic [1:0]               m0_awburst,
    input  logic                     m0_awlock,
    input  logic                     m0_awvalid,
    output logic                     m0_awready,
    input  logic [DATA_WIDTH-1:0]    m0_wdata,
    input  logic [DATA_WIDTH/8-1:0]  m0_wstrb,
    input  logic                     m0_wlast,
    input  logic                     m0_wvalid,
    output logic                     m0_wready,
    output logic [ID_WIDTH-1:0]      m0_bid,
    output logic [1:0]               m0_bresp,
    output logic                     m0_bvalid,
    input  logic                     m0_bready,
    input  logic [ADDR_WIDTH-1:0]    m0_araddr,
    input  logic [ID_WIDTH-1:0]      m0_arid,
    input  logic [7:0]               m0_arlen,
    input  logic [2:0]               m0_arsize,
    input  logic [1:0]               m0_arburst,
    input  logic                     m0_arlock,
    input  logic                     m0_arvalid,
    output logic                     m0_arready,
    output logic [ID_WIDTH-1:0]      m0_rid,
    output logic [DATA_WIDTH-1:0]    m0_rdata,
    output logic [1:0]               m0_rresp,
    output logic                     m0_rlast,
    output logic                     m0_rvalid,
    input  logic                     m0_rready
);

    int test;

    axi_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) cpu_m ();

    axi_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) sram_s ();

    axi_sram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEPTH(1024)
    ) u_axi_sram (
        .clk(clk),
        .n_rst(n_rst),
        .s(sram_s.slave)
    );

    // cpu_m if ports
    assign cpu_m.awaddr = m0_awaddr;
    assign cpu_m.awid = m0_awid;
    assign cpu_m.awlen = m0_awlen;
    assign cpu_m.awsize = m0_awsize;
    assign cpu_m.awburst = m0_awburst;
    assign cpu_m.awlock = m0_awlock;
    assign cpu_m.awvalid = m0_awvalid;
    assign m0_awready = cpu_m.awready;

    assign cpu_m.wdata = m0_wdata;
    assign cpu_m.wstrb = m0_wstrb;
    assign cpu_m.wlast = m0_wlast;
    assign cpu_m.wvalid = m0_wvalid;
    assign m0_wready = cpu_m.wready;

    assign m0_bid = cpu_m.bid;
    assign m0_bresp = cpu_m.bresp;
    assign m0_bvalid = cpu_m.bvalid;
    assign cpu_m.bready = m0_bready;

    assign cpu_m.araddr = m0_araddr;
    assign cpu_m.arid = m0_arid;
    assign cpu_m.arlen = m0_arlen;
    assign cpu_m.arsize = m0_arsize;
    assign cpu_m.arburst = m0_arburst;
    assign cpu_m.arlock = m0_arlock;
    assign cpu_m.arvalid = m0_arvalid;
    assign m0_arready = cpu_m.arready;

    assign m0_rid = cpu_m.rid;
    assign m0_rdata = cpu_m.rdata;
    assign m0_rresp = cpu_m.rresp;
    assign m0_rlast = cpu_m.rlast;
    assign m0_rvalid = cpu_m.rvalid;
    assign cpu_m.rready = m0_rready;

    axi_crossbar_dma #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .NUM_MASTERS(NUM_MASTERS),
        .NUM_SLAVES(NUM_SLAVES),
        .FIFO_DEPTH(FIFO_DEPTH),
        .MAX_OUTSTANDING_TX(MAX_OUTSTANDING_TX),
        .SLAVE_BASE_ADDR(SLAVE_BASE_ADDR),
        .SLAVE_ADDR_MASK(SLAVE_ADDR_MASK)
    ) dut (.*);

endmodule
