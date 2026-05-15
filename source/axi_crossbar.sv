`timescale 1ns / 10ps

module axi_crossbar #(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter ID_WIDTH    = 4,
    parameter STRB_WIDTH  = (DATA_WIDTH/8),
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES  = 2
) (
    input  logic clk, n_rst,

    // interface acts as a master to the slaves, and as a slave to the masters
    axi_if.master s [NUM_SLAVES],
    axi_if.slave m [NUM_MASTERS]
);

    // widths
    localparam LEN_WIDTH = 8;
    localparam SIZE_WIDTH = 3;
    localparam BURST_WIDTH = 2;
    localparam LAST_WIDTH = 1;
    localparam RESP_WIDTH = 2;

    localparam PAYLOAD_WIDTH_AW = ADDR_WIDTH + ID_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_WIDTH;
    localparam PAYLOAD_WIDTH_W  = DATA_WIDTH + STRB_WIDTH + LAST_WIDTH;
    localparam PAYLOAD_WIDTH_B  = ID_WIDTH + RESP_WIDTH;
    localparam PAYLOAD_WIDTH_AR = ADDR_WIDTH + ID_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_WIDTH;
    localparam PAYLOAD_WIDTH_R  = ID_WIDTH + DATA_WIDTH + RESP_WIDTH + LAST_WIDTH;

    // AW Channel
    logic [NUM_MASTERS-1:0] aw_valid_skid;
    logic [NUM_MASTERS-1:0] aw_ready_skid;
    logic [ADDR_WIDTH-1:0] aw_addr_skid [NUM_MASTERS-1:0];
    logic [PAYLOAD_WIDTH_AW-1:0] aw_payload_skid [NUM_MASTERS-1:0];

    // W Channel
    logic [NUM_MASTERS-1:0] w_valid_skid;
    logic [NUM_MASTERS-1:0] w_ready_skid;
    logic [PAYLOAD_WIDTH_W-1:0] w_payload_skid [NUM_MASTERS-1:0];

    // AR Channel
    logic [NUM_MASTERS-1:0] ar_valid_skid;
    logic [NUM_MASTERS-1:0] ar_ready_skid;
    logic [ADDR_WIDTH-1:0] ar_addr_skid [NUM_MASTERS-1:0];
    logic [PAYLOAD_WIDTH_AR-1:0] ar_payload_skid [NUM_MASTERS-1:0];

    // B Channel
    logic [NUM_SLAVES-1:0] b_valid_skid;
    logic [NUM_SLAVES-1:0] b_ready_skid;
    logic [ID_WIDTH-1:0] b_id_skid [NUM_SLAVES-1:0];
    logic [PAYLOAD_WIDTH_B-1:0] b_payload_skid [NUM_SLAVES-1:0];

    // R Channel
    logic [NUM_SLAVES-1:0] r_valid_skid;
    logic [NUM_SLAVES-1:0] r_ready_skid;
    logic [ID_WIDTH-1:0] r_id_skid [NUM_SLAVES-1:0];
    logic [PAYLOAD_WIDTH_R-1:0] r_payload_skid [NUM_SLAVES-1:0];

    // ========== SKID BUFFERS ========== //
    genvar m_idx;
    generate
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // AW Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AW)) sb_aw (
                .master_valid(m[m_idx].awvalid), 
                .slave_valid(aw_valid_skid[m_idx]), 
                .master_ready(m[m_idx].awready), 
                .slave_ready(aw_ready_skid[m_idx]), 
                .master_payload({m[m_idx].awaddr, m[m_idx].awid, m[m_idx].awlen, m[m_idx].awsize, m[m_idx].awburst}), 
                .slave_payload(aw_payload_skid[m_idx]), .*
                );
            assign aw_addr_skid[m_idx] = aw_payload_skid[m_idx][PAYLOAD_WIDTH_AW-1:PAYLOAD_WIDTH_AW-ADDR_WIDTH];

            // W Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_W)) sb_w (
                .master_valid(m[m_idx].wvalid), 
                .slave_valid(w_valid_skid[m_idx]), 
                .master_ready(m[m_idx].wready), 
                .slave_ready(w_ready_skid[m_idx]), 
                .master_payload({m[m_idx].wdata, m[m_idx].wstrb, m[m_idx].wlast}), 
                .slave_payload(w_payload_skid[m_idx]), .*
                );

            // AR Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AR)) sb_ar (
                .master_valid(m[m_idx].arvalid), 
                .slave_valid(ar_valid_skid[m_idx]), 
                .master_ready(m[m_idx].arready), 
                .slave_ready(ar_ready_skid[m_idx]), 
                .master_payload({m[m_idx].araddr, m[m_idx].arid, m[m_idx].arlen, m[m_idx].arsize, m[m_idx].arburst}), 
                .slave_payload(ar_payload_skid[m_idx]), .*
                );
            assign ar_addr_skid[m_idx] = ar_payload_skid[m_idx][PAYLOAD_WIDTH_AR-1:PAYLOAD_WIDTH_AR-ADDR_WIDTH];
        end
    endgenerate

    genvar s_idx;
    generate
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            // B Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_B)) sb_b (
                .master_valid(s[s_idx].bvalid), 
                .slave_valid(b_valid_skid[s_idx]), 
                .master_ready(s[s_idx].bready), 
                .slave_ready(b_ready_skid[s_idx]), 
                .master_payload({s[s_idx].bid, s[s_idx].bresp}), 
                .slave_payload(b_payload_skid[s_idx]), .*
                );
            assign b_id_skid[s_idx] = b_payload_skid[s_idx][PAYLOAD_WIDTH_B-1:PAYLOAD_WIDTH_B-ID_WIDTH];

            // R Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_R)) sb_r (
                .master_valid(s[s_idx].rvalid), 
                .slave_valid(r_valid_skid[s_idx]), 
                .master_ready(s[s_idx].rready), 
                .slave_ready(r_ready_skid[s_idx]), 
                .master_payload({s[s_idx].rid, s[s_idx].rdata, s[s_idx].rresp, s[s_idx].rlast}), 
                .slave_payload(r_payload_skid[s_idx]), .*
                );
            assign r_id_skid[s_idx] = r_payload_skid[s_idx][PAYLOAD_WIDTH_R-1:PAYLOAD_WIDTH_R-ID_WIDTH];
        end
    endgenerate

    // ========== ADDRESS DECODERS ========== //
    

    // ========== ARBITERS ========== //

    // ========== MUXES ========== //


endmodule

