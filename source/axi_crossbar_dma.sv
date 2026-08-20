`timescale 1ns / 10ps

module axi_crossbar_dma #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES = 2,
    parameter FIFO_DEPTH = 16,
    parameter MAX_OUTSTANDING_TX = 8,

    // Slave 0 (SRAM): 0x0000_0000 -> 0x0000_0FFF
    // Slave 1 (DMA CSR): 0x8000_0000 -> 0x8000_0FFF
    parameter [ADDR_WIDTH-1:0] SLAVE_BASE_ADDR [NUM_SLAVES-1:0] = '{32'h8000_0000, 32'h0000_0000},
    parameter [ADDR_WIDTH-1:0] SLAVE_ADDR_MASK [NUM_SLAVES-1:0] = '{32'hFFFF_F000, 32'hFFFF_F000}
) (
    input  logic clk, n_rst,

    axi_if.slave cpu_m,
    axi_if.master sram_s
);

    axi_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) m [NUM_MASTERS-1:0] ();

    axi_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) s [NUM_SLAVES-1:0] ();

    logic [1:0] dma_status;
    logic dma_start, dma_ack_done, dma_ack_err;
    logic [31:0] dma_length;
    logic [ADDR_WIDTH-1:0] dma_from_addr, dma_to_addr;

    assign m[0].awaddr   = cpu_m.awaddr;
    assign m[0].awid     = cpu_m.awid;
    assign m[0].awlen    = cpu_m.awlen;
    assign m[0].awsize   = cpu_m.awsize;
    assign m[0].awburst  = cpu_m.awburst;
    assign m[0].awlock   = cpu_m.awlock;
    assign m[0].awvalid  = cpu_m.awvalid;
    assign cpu_m.awready = m[0].awready;

    assign m[0].wdata    = cpu_m.wdata;
    assign m[0].wstrb    = cpu_m.wstrb;
    assign m[0].wlast    = cpu_m.wlast;
    assign m[0].wvalid   = cpu_m.wvalid;
    assign cpu_m.wready  = m[0].wready;

    assign cpu_m.bid     = m[0].bid;
    assign cpu_m.bresp   = m[0].bresp;
    assign cpu_m.bvalid  = m[0].bvalid;
    assign m[0].bready   = cpu_m.bready;

    assign m[0].araddr   = cpu_m.araddr;
    assign m[0].arid     = cpu_m.arid;
    assign m[0].arlen    = cpu_m.arlen;
    assign m[0].arsize   = cpu_m.arsize;
    assign m[0].arburst  = cpu_m.arburst;
    assign m[0].arlock   = cpu_m.arlock;
    assign m[0].arvalid  = cpu_m.arvalid;
    assign cpu_m.arready = m[0].arready;

    assign cpu_m.rid     = m[0].rid;
    assign cpu_m.rdata   = m[0].rdata;
    assign cpu_m.rresp   = m[0].rresp;
    assign cpu_m.rlast   = m[0].rlast;
    assign cpu_m.rvalid  = m[0].rvalid;
    assign m[0].rready   = cpu_m.rready;

    assign sram_s.awaddr  = s[0].awaddr;
    assign sram_s.awid    = s[0].awid;
    assign sram_s.awlen   = s[0].awlen;
    assign sram_s.awsize  = s[0].awsize;
    assign sram_s.awburst = s[0].awburst;
    assign sram_s.awlock  = s[0].awlock;
    assign sram_s.awvalid = s[0].awvalid;
    assign s[0].awready   = sram_s.awready;

    assign sram_s.wdata   = s[0].wdata;
    assign sram_s.wstrb   = s[0].wstrb;
    assign sram_s.wlast   = s[0].wlast;
    assign sram_s.wvalid  = s[0].wvalid;
    assign s[0].wready    = sram_s.wready;

    assign s[0].bid       = sram_s.bid;
    assign s[0].bresp     = sram_s.bresp;
    assign s[0].bvalid    = sram_s.bvalid;
    assign sram_s.bready  = s[0].bready;

    assign sram_s.araddr  = s[0].araddr;
    assign sram_s.arid    = s[0].arid;
    assign sram_s.arlen   = s[0].arlen;
    assign sram_s.arsize  = s[0].arsize;
    assign sram_s.arburst = s[0].arburst;
    assign sram_s.arlock  = s[0].arlock;
    assign sram_s.arvalid = s[0].arvalid;
    assign s[0].arready   = sram_s.arready;

    assign s[0].rid       = sram_s.rid;
    assign s[0].rdata     = sram_s.rdata;
    assign s[0].rresp     = sram_s.rresp;
    assign s[0].rlast     = sram_s.rlast;
    assign s[0].rvalid    = sram_s.rvalid;
    assign sram_s.rready  = s[0].rready;

    axi_crossbar #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .NUM_MASTERS(NUM_MASTERS),
        .NUM_SLAVES(NUM_SLAVES),
        .MAX_OUTSTANDING_TX(MAX_OUTSTANDING_TX),
        .SLAVE_BASE_ADDR(SLAVE_BASE_ADDR),
        .SLAVE_ADDR_MASK(SLAVE_ADDR_MASK)
    ) u_axi_crossbar (
        .clk(clk),
        .n_rst(n_rst),
        .s(s),
        .m(m)
    );

    dma_csr #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_dma_csr (
        .clk(clk),
        .n_rst(n_rst),
        .s(s[1]),
        .status(dma_status),
        .start(dma_start),
        .ack_done(dma_ack_done),
        .ack_err(dma_ack_err),
        .length(dma_length),
        .from_addr(dma_from_addr),
        .to_addr(dma_to_addr)
    );

    dma_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_dma_engine (
        .clk(clk),
        .n_rst(n_rst),
        .m(m[1]),
        .start(dma_start),
        .ack_done(dma_ack_done),
        .ack_err(dma_ack_err),
        .length(dma_length),
        .from_addr(dma_from_addr),
        .to_addr(dma_to_addr),
        .status(dma_status)
    );

endmodule
