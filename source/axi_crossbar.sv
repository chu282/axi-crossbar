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

    // Slave Addresses
    localparam [ADDR_WIDTH-1:0] SLAVE_BASE_ADDR [NUM_SLAVES-1:0] = '{
        32'h00000000, 32'h80000000
    };
    localparam [ADDR_WIDTH-1:0] SLAVE_ADDR_MASK [NUM_SLAVES-1:0] = '{
        32'h80000000, 32'h80000000
    };

    // ========== SKID BUFFERS ========== //
    genvar m_idx;
    generate
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // AW Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AW)) sb_aw (
                .src_valid(m[m_idx].awvalid), 
                .dst_valid(aw_valid_skid[m_idx]), 
                .src_ready(m[m_idx].awready), 
                .dst_ready(aw_ready_skid[m_idx]), 
                .src_payload({m[m_idx].awaddr, m[m_idx].awid, m[m_idx].awlen, m[m_idx].awsize, m[m_idx].awburst}), 
                .dst_payload(aw_payload_skid[m_idx]), .*
                );
            assign aw_addr_skid[m_idx] = aw_payload_skid[m_idx][PAYLOAD_WIDTH_AW-1:PAYLOAD_WIDTH_AW-ADDR_WIDTH];

            // W Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_W)) sb_w (
                .src_valid(m[m_idx].wvalid), 
                .dst_valid(w_valid_skid[m_idx]), 
                .src_ready(m[m_idx].wready), 
                .dst_ready(w_ready_skid[m_idx]), 
                .src_payload({m[m_idx].wdata, m[m_idx].wstrb, m[m_idx].wlast}), 
                .dst_payload(w_payload_skid[m_idx]), .*
                );

            // AR Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AR)) sb_ar (
                .src_valid(m[m_idx].arvalid), 
                .dst_valid(ar_valid_skid[m_idx]), 
                .src_ready(m[m_idx].arready), 
                .dst_ready(ar_ready_skid[m_idx]), 
                .src_payload({m[m_idx].araddr, m[m_idx].arid, m[m_idx].arlen, m[m_idx].arsize, m[m_idx].arburst}), 
                .dst_payload(ar_payload_skid[m_idx]), .*
                );
            assign ar_addr_skid[m_idx] = ar_payload_skid[m_idx][PAYLOAD_WIDTH_AR-1:PAYLOAD_WIDTH_AR-ADDR_WIDTH];
        end
    endgenerate

    genvar s_idx;
    generate
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            // B Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_B)) sb_b (
                .src_valid(s[s_idx].bvalid), 
                .dst_valid(b_valid_skid[s_idx]), 
                .src_ready(s[s_idx].bready), 
                .dst_ready(b_ready_skid[s_idx]), 
                .src_payload({s[s_idx].bid, s[s_idx].bresp}), 
                .dst_payload(b_payload_skid[s_idx]), .*
                );
            assign b_id_skid[s_idx] = b_payload_skid[s_idx][PAYLOAD_WIDTH_B-1:PAYLOAD_WIDTH_B-ID_WIDTH];

            // R Channel
            skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_R)) sb_r (
                .src_valid(s[s_idx].rvalid), 
                .dst_valid(r_valid_skid[s_idx]), 
                .src_ready(s[s_idx].rready), 
                .dst_ready(r_ready_skid[s_idx]), 
                .src_payload({s[s_idx].rid, s[s_idx].rdata, s[s_idx].rresp, s[s_idx].rlast}), 
                .dst_payload(r_payload_skid[s_idx]), .*
                );
            assign r_id_skid[s_idx] = r_payload_skid[s_idx][PAYLOAD_WIDTH_R-1:PAYLOAD_WIDTH_R-ID_WIDTH];
        end
    endgenerate

    // ========== ADDRESS DECODERS ========== //
    logic [NUM_SLAVES-1:0] aw_slave_select [NUM_MASTERS-1:0];
    logic [NUM_SLAVES-1:0] ar_slave_select [NUM_MASTERS-1:0];
    logic [NUM_MASTERS-1:0] aw_decerr;
    logic [NUM_MASTERS-1:0] ar_decerr;

    genvar m_idx;
    generate
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // AW Channel
            axi_addr_decoder #(
                .base_addrs(SLAVE_BASE_ADDR),
                .addr_masks(SLAVE_ADDR_MASK), .*
            ) aw_ad (
                .valid(aw_valid_skid[m_idx]),
                .addr(aw_addr_skid[m_idx]), 
                .slave_select(aw_slave_select[m_idx]),
                .decerr(aw_decerr[m_idx])
            );

            // AR Channel
            axi_addr_decoder #(
                .base_addrs(SLAVE_BASE_ADDR),
                .addr_masks(SLAVE_ADDR_MASK), .*
            ) ar_ad (
                .valid(ar_valid_skid[m_idx]),
                .addr(ar_addr_skid[m_idx]), 
                .slave_select(ar_slave_select[m_idx]),
                .decerr(ar_decerr[m_idx])
            );
        end
    endgenerate

    // ========== ARBITERS ========== //
    logic [NUM_SLAVES-1:0] aw_trans_finished;
    logic [NUM_SLAVES-1:0] ar_trans_finished;
    logic [NUM_MASTERS-1:0] aw_master_req [NUM_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] ar_master_req [NUM_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] aw_grant [NUM_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] w_grant [NUM_SLAVES-1:0];
    logic [NUM_SLAVES-1:0] b_grant [NUM_MASTERS-1:0];
    logic [NUM_MASTERS-1:0] ar_grant [NUM_SLAVES-1:0];
    logic [NUM_SLAVES-1:0] r_grant [NUM_MASTERS-1:0];

    genvar s_idx, m_idx;
    generate
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            // AW Channel
            // tranpose 
            for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
                assign aw_master_req[s_idx][m_idx] = aw_slave_select[m_idx][s_idx];
            end

            axi_arbiter #(
                .*
            ) aw_arb (
                .trans_finished(aw_trans_finished[s_idx]),
                .master_req(aw_master_req[s_idx]),
                .grant(aw_grant[s_idx]), .*
            );

            // AR Channel
            // tranpose 
            for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
                assign ar_master_req[s_idx][m_idx] = ar_slave_select[m_idx][s_idx];
            end

            axi_arbiter #(
                .*
            ) ar_arb (
                .trans_finished(ar_trans_finished[s_idx]),
                .master_req(ar_master_req[s_idx]),
                .grant(ar_grant[s_idx]), .*
            );
        end
    endgenerate

    // logic [NUM_MASTERS-1:0] aw_valid_skid;
    // logic [NUM_MASTERS-1:0] aw_ready_skid;
    always_comb begin : trans_finished_logic
        aw_trans_finished = 
    end

    // ========== MUXES ========== //
    logic [NUM_MASTERS-1:0] aw_ready_mux [NUM_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] w_ready_mux [NUM_SLAVES-1:0];
    logic [NUM_SLAVES-1:0] b_ready_mux [NUM_MASTERS-1:0];
    logic [NUM_MASTERS-1:0] ar_ready_mux [NUM_SLAVES-1:0];
    logic [NUM_SLAVES-1:0] r_ready_mux [NUM_MASTERS-1:0];

    genvar s_idx, m_idx;
    generate
        // Loop through all slaves to see which masters are called by each. For ready, 
        // we need to combine all one-hot ready signals from each slave into one array for all the masters.
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            // AW Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_AW),
                .NUM_DEVICES(NUM_MASTERS)
            ) aw_mux (
                .src_valid(aw_valid_skid),
                .dst_valid(s[s_idx].awvalid),
                .dst_ready(s[s_idx].awready),
                .src_ready(aw_ready_mux[s_idx]),
                .grant(aw_grant[s_idx]),
                .src_payload(aw_payload_skid),
                .dst_payload({
                    s[s_idx].awaddr, 
                    s[s_idx].awid, 
                    s[s_idx].awlen, 
                    s[s_idx].awsize, 
                    s[s_idx].awburst
                })
            );

            // W Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_W),
                .NUM_DEVICES(NUM_MASTERS)
            ) w_mux (
                .src_valid(w_valid_skid),
                .dst_valid(s[s_idx].wvalid),
                .dst_ready(s[s_idx].wready),
                .src_ready(w_ready_mux[s_idx]),
                .grant(w_grant[s_idx]),
                .src_payload(w_payload_skid),
                .dst_payload({
                    s[s_idx].wdata, 
                    s[s_idx].wstrb, 
                    s[s_idx].wlast
                })
            );

            // AR Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_AR),
                .NUM_DEVICES(NUM_MASTERS)
            ) ar_mux (
                .src_valid(ar_valid_skid),
                .dst_valid(s[s_idx].arvalid),
                .dst_ready(s[s_idx].arready),
                .src_ready(ar_ready_mux[s_idx]),
                .grant(ar_grant[s_idx]),
                .src_payload(ar_payload_skid),
                .dst_payload({
                    s[s_idx].araddr, 
                    s[s_idx].arid, 
                    s[s_idx].arlen, 
                    s[s_idx].arsize, 
                    s[s_idx].arburst
                })
            );
        end

        // Loop through all masters to see which slaves they call. For valid, 
        // we need to combine all one-hot ready signals from each master into one array for all the slaves.
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // B Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_B),
                .NUM_DEVICES(NUM_SLAVES)
            ) b_mux (
                .src_valid(b_valid_skid),
                .dst_valid(m[m_idx].bvalid),
                .dst_ready(m[m_idx].bready),
                .src_ready(b_ready_mux[m_idx]),
                .grant(b_grant[m_idx]),
                .src_payload(b_payload_skid),
                .dst_payload({
                    m[m_idx].bid, 
                    m[m_idx].bresp
                })
            );

            // R Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_R),
                .NUM_DEVICES(NUM_SLAVES)
            ) r_mux (
                .src_valid(r_valid_skid),
                .dst_valid(m[m_idx].rvalid),
                .dst_ready(m[m_idx].rready),
                .src_ready(r_ready_mux[m_idx]),
                .grant(r_grant[m_idx]),
                .src_payload(r_payload_skid),
                .dst_payload({
                    m[m_idx].rid, 
                    m[m_idx].rdata, 
                    m[m_idx].rresp, 
                    m[m_idx].rlast
                })
            );
        end

    endgenerate

    // Combine the ready arrays into the final output
    always_comb begin
        aw_ready_skid = 0;
        w_ready_skid  = 0;
        ar_ready_skid = 0;
        
        for (int i = 0; i < NUM_SLAVES; i++) begin
            aw_ready_skid |= aw_ready_mux[i];
            w_ready_skid |= w_ready_mux[i];
            ar_ready_skid |= ar_ready_mux[i];
        end
        
        b_ready_skid = 0;
        r_ready_skid = 0;

        for (int i = 0; i < NUM_MASTERS; i++) begin
            b_ready_skid |= b_ready_mux[i];
            r_ready_skid |= r_ready_mux[i];
        end
    end

    // ========== Non-Address Channel Grant Tracker ========== //
    genvar s_idx;
    generate
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            axi_grant_tracker #(

            ) w_gt (

            );
        end
    endgenerate

endmodule

