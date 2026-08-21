`timescale 1ns / 10ps

module axi_crossbar #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES = 2,
    parameter MAX_OUTSTANDING_TX = 8,

    // Slave addresses
    parameter [ADDR_WIDTH-1:0] SLAVE_BASE_ADDR [NUM_SLAVES-1:0] = '{32'h80000000, 32'h00000000},
    parameter [ADDR_WIDTH-1:0] SLAVE_ADDR_MASK [NUM_SLAVES-1:0] = '{32'hF0000000, 32'h80000000}
) (
    input  logic clk, n_rst,

    // interface acts as a master to the slaves, and as a slave to the masters
    axi_if.master s [NUM_SLAVES-1:0],
    axi_if.slave m [NUM_MASTERS-1:0]
);

    localparam STRB_WIDTH = DATA_WIDTH / 8;
    localparam NUM_TOTAL_SLAVES = NUM_SLAVES + 1;
    localparam DECERR_SLAVE = NUM_SLAVES;

    // widths
    localparam LEN_WIDTH   = 8;
    localparam SIZE_WIDTH  = 3;
    localparam BURST_WIDTH = 2;
    localparam LAST_WIDTH  = 1;
    localparam RESP_WIDTH  = 2;
    localparam LOCK_WIDTH  = 1;

    localparam PAYLOAD_WIDTH_AW = ADDR_WIDTH + ID_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_WIDTH + LOCK_WIDTH;
    localparam PAYLOAD_WIDTH_W  = DATA_WIDTH + STRB_WIDTH + LAST_WIDTH;
    localparam PAYLOAD_WIDTH_B  = ID_WIDTH + RESP_WIDTH;
    localparam PAYLOAD_WIDTH_AR = ADDR_WIDTH + ID_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_WIDTH + LOCK_WIDTH;
    localparam PAYLOAD_WIDTH_R  = ID_WIDTH + DATA_WIDTH + RESP_WIDTH + LAST_WIDTH;

    // AW Channel
    logic [NUM_MASTERS-1:0] aw_m_valid_skid;
    logic [NUM_MASTERS-1:0] aw_m_ready_skid;
    logic [ADDR_WIDTH-1:0] aw_m_addr_skid [NUM_MASTERS-1:0];
    logic [ID_WIDTH-1:0] aw_m_id_skid [NUM_MASTERS-1:0];
    logic [PAYLOAD_WIDTH_AW-1:0] aw_m_payload_skid [NUM_MASTERS-1:0];

    logic [NUM_TOTAL_SLAVES-1:0] aw_s_valid_mux;
    logic [NUM_TOTAL_SLAVES-1:0] aw_s_ready_mux;
    logic [ADDR_WIDTH-1:0] aw_s_addr_mux [NUM_TOTAL_SLAVES-1:0];
    logic [PAYLOAD_WIDTH_AW-1:0] aw_s_payload_mux [NUM_TOTAL_SLAVES-1:0];

    // W Channel
    logic [NUM_MASTERS-1:0] w_m_valid_skid;
    logic [NUM_MASTERS-1:0] w_m_ready_skid;
    logic [PAYLOAD_WIDTH_W-1:0] w_m_payload_skid [NUM_MASTERS-1:0];

    logic [NUM_TOTAL_SLAVES-1:0] w_s_valid_mux;
    logic [NUM_TOTAL_SLAVES-1:0] w_s_ready_mux;
    logic [PAYLOAD_WIDTH_W-1:0] w_s_payload_mux [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] w_s_last_mux;

    // AR Channel
    logic [NUM_MASTERS-1:0] ar_m_valid_skid;
    logic [NUM_MASTERS-1:0] ar_m_ready_skid;
    logic [ADDR_WIDTH-1:0] ar_m_addr_skid [NUM_MASTERS-1:0];
    logic [ID_WIDTH-1:0] ar_m_id_skid [NUM_MASTERS-1:0];
    logic [PAYLOAD_WIDTH_AR-1:0] ar_m_payload_skid [NUM_MASTERS-1:0];

    logic [NUM_TOTAL_SLAVES-1:0] ar_s_valid_mux;
    logic [NUM_TOTAL_SLAVES-1:0] ar_s_ready_mux;
    logic [ADDR_WIDTH-1:0] ar_s_addr_mux [NUM_TOTAL_SLAVES-1:0];
    logic [PAYLOAD_WIDTH_AR-1:0] ar_s_payload_mux [NUM_TOTAL_SLAVES-1:0];

    // B Channel
    logic [NUM_TOTAL_SLAVES-1:0] b_s_valid_skid;
    logic [NUM_TOTAL_SLAVES-1:0] b_s_ready_skid;
    logic [ID_WIDTH-1:0] b_s_id_skid [NUM_TOTAL_SLAVES-1:0];
    logic [PAYLOAD_WIDTH_B-1:0] b_s_payload_skid [NUM_TOTAL_SLAVES-1:0];

    logic [NUM_MASTERS-1:0] b_m_valid_mux;
    logic [NUM_MASTERS-1:0] b_m_ready_mux;
    logic [ID_WIDTH-1:0] b_m_id_mux [NUM_MASTERS-1:0];
    logic [PAYLOAD_WIDTH_B-1:0] b_m_payload_mux [NUM_MASTERS-1:0];

    // R Channel
    logic [NUM_TOTAL_SLAVES-1:0] r_s_valid_skid;
    logic [NUM_TOTAL_SLAVES-1:0] r_s_ready_skid;
    logic [ID_WIDTH-1:0] r_s_id_skid [NUM_TOTAL_SLAVES-1:0];
    logic [PAYLOAD_WIDTH_R-1:0] r_s_payload_skid [NUM_TOTAL_SLAVES-1:0];

    logic [NUM_MASTERS-1:0] r_m_valid_mux;
    logic [NUM_MASTERS-1:0] r_m_ready_mux;
    logic [ID_WIDTH-1:0] r_m_id_mux [NUM_MASTERS-1:0];
    logic [PAYLOAD_WIDTH_R-1:0] r_m_payload_mux [NUM_MASTERS-1:0];
    logic [NUM_MASTERS-1:0] r_m_last_mux;

    // ========== SKID BUFFERS ========== //
    genvar m_idx, s_idx;
    generate
        // Master side
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // AW Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AW)) u_sb_aw_master (
                .src_valid(m[m_idx].awvalid), 
                .dst_valid(aw_m_valid_skid[m_idx]), 
                .src_ready(m[m_idx].awready), 
                .dst_ready(aw_m_ready_skid[m_idx]), 
                .src_payload({m[m_idx].awaddr, m[m_idx].awid, m[m_idx].awlen, m[m_idx].awsize, m[m_idx].awburst, m[m_idx].awlock}), 
                .dst_payload(aw_m_payload_skid[m_idx]), .*
            );
            assign aw_m_addr_skid[m_idx] = aw_m_payload_skid[m_idx][PAYLOAD_WIDTH_AW-1:PAYLOAD_WIDTH_AW-ADDR_WIDTH];

            // W Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_W)) u_sb_w_master (
                .src_valid(m[m_idx].wvalid), 
                .dst_valid(w_m_valid_skid[m_idx]), 
                .src_ready(m[m_idx].wready), 
                .dst_ready(w_m_ready_skid[m_idx]), 
                .src_payload({m[m_idx].wdata, m[m_idx].wstrb, m[m_idx].wlast}), 
                .dst_payload(w_m_payload_skid[m_idx]), .*
            );

            // AR Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AR)) u_sb_ar_master (
                .src_valid(m[m_idx].arvalid), 
                .dst_valid(ar_m_valid_skid[m_idx]), 
                .src_ready(m[m_idx].arready), 
                .dst_ready(ar_m_ready_skid[m_idx]), 
                .src_payload({m[m_idx].araddr, m[m_idx].arid, m[m_idx].arlen, m[m_idx].arsize, m[m_idx].arburst, m[m_idx].arlock}), 
                .dst_payload(ar_m_payload_skid[m_idx]), .*
            );
            assign ar_m_addr_skid[m_idx] = ar_m_payload_skid[m_idx][PAYLOAD_WIDTH_AR-1:PAYLOAD_WIDTH_AR-ADDR_WIDTH];
        end
        
        // Slave side
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            // AW Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AW)) u_sb_aw_slave (
                .src_valid(aw_s_valid_mux[s_idx]), 
                .dst_valid(s[s_idx].awvalid), 
                .src_ready(aw_s_ready_mux[s_idx]), 
                .dst_ready(s[s_idx].awready), 
                .src_payload(aw_s_payload_mux[s_idx]), 
                .dst_payload({s[s_idx].awaddr, s[s_idx].awid, s[s_idx].awlen, s[s_idx].awsize, s[s_idx].awburst, s[s_idx].awlock}), .*
            );

            // W Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_W)) u_sb_w_slave (
                .src_valid(w_s_valid_mux[s_idx]), 
                .dst_valid(s[s_idx].wvalid), 
                .src_ready(w_s_ready_mux[s_idx]), 
                .dst_ready(s[s_idx].wready), 
                .src_payload(w_s_payload_mux[s_idx]), 
                .dst_payload({s[s_idx].wdata, s[s_idx].wstrb, s[s_idx].wlast}), .*
            );

            // AR Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_AR)) u_sb_ar_slave (
                .src_valid(ar_s_valid_mux[s_idx]), 
                .dst_valid(s[s_idx].arvalid), 
                .src_ready(ar_s_ready_mux[s_idx]), 
                .dst_ready(s[s_idx].arready), 
                .src_payload(ar_s_payload_mux[s_idx]), 
                .dst_payload({s[s_idx].araddr, s[s_idx].arid, s[s_idx].arlen, s[s_idx].arsize, s[s_idx].arburst, s[s_idx].arlock}), .*
            );
        end
    endgenerate

    // Reverse path
    generate
        // Slave side
        for (s_idx = 0; s_idx < NUM_SLAVES; s_idx++) begin
            // B Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_B)) u_sb_b_slave (
                .src_valid(s[s_idx].bvalid), 
                .dst_valid(b_s_valid_skid[s_idx]), 
                .src_ready(s[s_idx].bready), 
                .dst_ready(b_s_ready_skid[s_idx]), 
                .src_payload({s[s_idx].bid, s[s_idx].bresp}), 
                .dst_payload(b_s_payload_skid[s_idx]), .*
            );
            assign b_s_id_skid[s_idx] = b_s_payload_skid[s_idx][PAYLOAD_WIDTH_B-1:PAYLOAD_WIDTH_B-ID_WIDTH];

            // R Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_R)) u_sb_r_slave (
                .src_valid(s[s_idx].rvalid), 
                .dst_valid(r_s_valid_skid[s_idx]), 
                .src_ready(s[s_idx].rready), 
                .dst_ready(r_s_ready_skid[s_idx]), 
                .src_payload({s[s_idx].rid, s[s_idx].rdata, s[s_idx].rresp, s[s_idx].rlast}), 
                .dst_payload(r_s_payload_skid[s_idx]), .*
            );
            assign r_s_id_skid[s_idx] = r_s_payload_skid[s_idx][PAYLOAD_WIDTH_R-1:PAYLOAD_WIDTH_R-ID_WIDTH];
        end

        // Master side
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // B Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_B)) u_sb_b_master (
                .src_valid(b_m_valid_mux[m_idx]), 
                .dst_valid(m[m_idx].bvalid), 
                .src_ready(b_m_ready_mux[m_idx]), 
                .dst_ready(m[m_idx].bready), 
                .src_payload(b_m_payload_mux[m_idx]), 
                .dst_payload({m[m_idx].bid, m[m_idx].bresp}), .*
            );

            // R Channel
            axi_skid_buffer #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH_R)) u_sb_r_master (
                .src_valid(r_m_valid_mux[m_idx]), 
                .dst_valid(m[m_idx].rvalid), 
                .src_ready(r_m_ready_mux[m_idx]), 
                .dst_ready(m[m_idx].rready), 
                .src_payload(r_m_payload_mux[m_idx]), 
                .dst_payload({m[m_idx].rid, m[m_idx].rdata, m[m_idx].rresp, m[m_idx].rlast}), .*
            );
        end
    endgenerate

    // ========== ADDRESS DECODERS ========== //
    logic [NUM_TOTAL_SLAVES-1:0] aw_slave_select [NUM_MASTERS-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] ar_slave_select [NUM_MASTERS-1:0];

    generate
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // AW Channel
            axi_addr_decoder #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .NUM_SLAVES(NUM_SLAVES),
                .NUM_TOTAL_SLAVES(NUM_TOTAL_SLAVES),
                .BASE_ADDRS(SLAVE_BASE_ADDR),
                .ADDR_MASKS(SLAVE_ADDR_MASK)
            ) u_aw_ad (
                .valid(aw_m_valid_skid[m_idx]),
                .addr(aw_m_addr_skid[m_idx]), 
                .slave_select(aw_slave_select[m_idx])
            );

            // AR Channel
            axi_addr_decoder #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .NUM_SLAVES(NUM_SLAVES),
                .NUM_TOTAL_SLAVES(NUM_TOTAL_SLAVES),
                .BASE_ADDRS(SLAVE_BASE_ADDR),
                .ADDR_MASKS(SLAVE_ADDR_MASK)
            ) u_ar_ad (
                .valid(ar_m_valid_skid[m_idx]),
                .addr(ar_m_addr_skid[m_idx]), 
                .slave_select(ar_slave_select[m_idx])
            );
        end
    endgenerate

    // ========== ARBITERS ========== //
    logic [NUM_TOTAL_SLAVES-1:0] aw_tx_started;
    logic [NUM_TOTAL_SLAVES-1:0] ar_tx_started;

    logic [NUM_TOTAL_SLAVES-1:0] aw_s_tf_finished;
    logic [NUM_TOTAL_SLAVES-1:0] w_s_tf_finished;
    logic [NUM_TOTAL_SLAVES-1:0] b_s_tf_finished;
    logic [NUM_TOTAL_SLAVES-1:0] ar_s_tf_finished;
    logic [NUM_TOTAL_SLAVES-1:0] r_s_tf_finished;

    logic [NUM_MASTERS-1:0] b_m_tf_finished;
    logic [NUM_MASTERS-1:0] r_m_tf_finished;

    logic [NUM_TOTAL_SLAVES-1:0] w_full;
    logic [NUM_TOTAL_SLAVES-1:0] b_full;
    logic [NUM_TOTAL_SLAVES-1:0] ar_full;

    logic [NUM_MASTERS-1:0] aw_master_req [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] ar_master_req [NUM_TOTAL_SLAVES-1:0];

    logic [NUM_MASTERS-1:0] b_master_req [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] r_master_req [NUM_TOTAL_SLAVES-1:0];

    logic [NUM_TOTAL_SLAVES-1:0] b_slave_select [NUM_MASTERS-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] r_slave_select [NUM_MASTERS-1:0];

    logic [NUM_TOTAL_SLAVES-1:0] b_slave_req [NUM_MASTERS-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] r_slave_req [NUM_MASTERS-1:0];

    logic [NUM_MASTERS-1:0] aw_grant [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] w_grant [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] b_grant [NUM_MASTERS-1:0];
    logic [NUM_MASTERS-1:0] ar_grant [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] r_grant [NUM_MASTERS-1:0];

    // Forward path
    generate
        for (s_idx = 0; s_idx < NUM_TOTAL_SLAVES; s_idx++) begin
            /* 
            We need to tranpose from the master's selected slaves to the slave's requests from the masters. 
            Slave_select: for each master, which slave is being selected?
            Master_req: for each slave, which master(s) are requesting?

            We do not need arbiters for the W channel because write data must come in the same order as
            the addresses. 
            */
            for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
                assign aw_master_req[s_idx][m_idx] = aw_slave_select[m_idx][s_idx];
                assign ar_master_req[s_idx][m_idx] = ar_slave_select[m_idx][s_idx];
            end

            // AW Channel
            axi_arbiter #(
                .NUM_DEVICES(NUM_MASTERS)
            ) u_aw_arb_slave (
                .tf_finished(aw_s_tf_finished[s_idx]),
                .request(aw_master_req[s_idx]),
                .grant(aw_grant[s_idx]), .*
            );

            // AR Channel
            axi_arbiter #(
                .NUM_DEVICES(NUM_MASTERS)
            ) u_ar_arb_slave (
                .tf_finished(ar_s_tf_finished[s_idx]),
                .request(ar_master_req[s_idx]),
                .grant(ar_grant[s_idx]), .*
            );
        end
    endgenerate

    // Reverse path
    generate
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // tranpose (this time in reverse)
            for (s_idx = 0; s_idx < NUM_TOTAL_SLAVES; s_idx++) begin
                assign b_slave_select[m_idx][s_idx] = b_master_req[s_idx][m_idx];
                assign r_slave_select[m_idx][s_idx] = r_master_req[s_idx][m_idx];
                
                assign b_slave_req[m_idx][s_idx] = b_slave_select[m_idx][s_idx] & b_s_valid_skid[s_idx];
                assign r_slave_req[m_idx][s_idx] = r_slave_select[m_idx][s_idx] & r_s_valid_skid[s_idx];
            end

            // B Channel
            axi_arbiter #(
                .NUM_DEVICES(NUM_TOTAL_SLAVES)
            ) u_b_arb_master (
                .tf_finished(b_m_tf_finished[m_idx]),
                .request(b_slave_req[m_idx]),
                .grant(b_grant[m_idx]), .*
            );

            // R Channel
            axi_arbiter #(
                .NUM_DEVICES(NUM_TOTAL_SLAVES)
            ) u_r_arb_master (
                .tf_finished(r_m_tf_finished[m_idx]),
                .request(r_slave_req[m_idx]),
                .grant(r_grant[m_idx]), .*
            );
        end
    endgenerate

    // Transfer (tf): one channel operation
    // Transaction (tx): entire multi-channel operation
    logic [NUM_TOTAL_SLAVES-1:0] r_s_last_skid;

    always_comb begin : trans_start_end_logic
        for (int slave = 0; slave < NUM_TOTAL_SLAVES; slave++) begin
            w_s_last_mux[slave] = w_s_payload_mux[slave][0];
            r_s_last_skid[slave] = r_s_payload_skid[slave][0];
        end
        for (int master = 0; master < NUM_MASTERS; master++) begin
            r_m_last_mux[master] = r_m_payload_mux[master][0];
        end

        b_s_tf_finished = b_s_valid_skid & b_s_ready_skid;
        r_s_tf_finished = r_s_valid_skid & r_s_ready_skid & r_s_last_skid;

        aw_s_tf_finished = aw_s_valid_mux & aw_s_ready_mux;
        w_s_tf_finished = w_s_valid_mux & w_s_ready_mux & w_s_last_mux;
        ar_s_tf_finished = ar_s_valid_mux & ar_s_ready_mux;

        b_m_tf_finished = b_m_valid_mux & b_m_ready_mux;
        r_m_tf_finished = r_m_valid_mux & r_m_ready_mux & r_m_last_mux;

        aw_tx_started = aw_s_tf_finished;
        ar_tx_started = ar_s_tf_finished;
    end

    // ========== MUXES ========== //
    logic [NUM_MASTERS-1:0] aw_ready_mux [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_MASTERS-1:0] w_ready_mux [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] b_ready_mux [NUM_MASTERS-1:0];
    logic [NUM_MASTERS-1:0] ar_ready_mux [NUM_TOTAL_SLAVES-1:0];
    logic [NUM_TOTAL_SLAVES-1:0] r_ready_mux [NUM_MASTERS-1:0];

    generate
        for (s_idx = 0; s_idx < NUM_TOTAL_SLAVES; s_idx++) begin
            // AW Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_AW),
                .NUM_DEVICES(NUM_MASTERS)
            ) u_aw_mux (
                .src_valid(aw_m_valid_skid),
                .dst_valid(aw_s_valid_mux[s_idx]),
                .dst_ready(aw_s_ready_mux[s_idx]),
                .src_ready(aw_ready_mux[s_idx]),
                .grant(aw_grant[s_idx] & {NUM_MASTERS{~(w_full[s_idx] | b_full[s_idx])}}),
                .src_payload(aw_m_payload_skid),
                .dst_payload(aw_s_payload_mux[s_idx])
            );

            // W Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_W),
                .NUM_DEVICES(NUM_MASTERS)
            ) u_w_mux (
                .src_valid(w_m_valid_skid),
                .dst_valid(w_s_valid_mux[s_idx]),
                .dst_ready(w_s_ready_mux[s_idx]),
                .src_ready(w_ready_mux[s_idx]),
                .grant(w_grant[s_idx]),
                .src_payload(w_m_payload_skid),
                .dst_payload(w_s_payload_mux[s_idx])
            );

            // AR Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_AR),
                .NUM_DEVICES(NUM_MASTERS)
            ) u_ar_mux (
                .src_valid(ar_m_valid_skid),
                .dst_valid(ar_s_valid_mux[s_idx]),
                .dst_ready(ar_s_ready_mux[s_idx]),
                .src_ready(ar_ready_mux[s_idx]),
                .grant(ar_grant[s_idx] & {NUM_MASTERS{~ar_full[s_idx]}}),
                .src_payload(ar_m_payload_skid),
                .dst_payload(ar_s_payload_mux[s_idx])
            );
        end

        // Loop through all masters to see which slaves they call. For valid, we need to combine 
        // all one-hot ready signals from each master into one array for all the slaves.
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx++) begin
            // B Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_B),
                .NUM_DEVICES(NUM_TOTAL_SLAVES)
            ) u_b_mux (
                .src_valid(b_s_valid_skid),
                .dst_valid(b_m_valid_mux[m_idx]),
                .dst_ready(b_m_ready_mux[m_idx]),
                .src_ready(b_ready_mux[m_idx]),
                .grant(b_grant[m_idx] & b_slave_req[m_idx]),
                .src_payload(b_s_payload_skid),
                .dst_payload(b_m_payload_mux[m_idx])
            );

            // R Channel
            axi_mux #(
                .PAYLOAD_WIDTH(PAYLOAD_WIDTH_R),
                .NUM_DEVICES(NUM_TOTAL_SLAVES)
            ) u_r_mux (
                .src_valid(r_s_valid_skid),
                .dst_valid(r_m_valid_mux[m_idx]),
                .dst_ready(r_m_ready_mux[m_idx]),
                .src_ready(r_ready_mux[m_idx]),
                .grant(r_grant[m_idx] & r_slave_req[m_idx]),
                .src_payload(r_s_payload_skid),
                .dst_payload(r_m_payload_mux[m_idx])
            );
        end
    endgenerate

    // Combine the ready arrays into the final output
    always_comb begin
        aw_m_ready_skid = 0;
        w_m_ready_skid  = 0;
        ar_m_ready_skid = 0;
        
        for (int i = 0; i < NUM_TOTAL_SLAVES; i++) begin
            aw_m_ready_skid |= aw_ready_mux[i];
            w_m_ready_skid |= w_ready_mux[i];
            ar_m_ready_skid |= ar_ready_mux[i];
        end
        
        b_s_ready_skid = 0;
        r_s_ready_skid = 0;

        for (int i = 0; i < NUM_MASTERS; i++) begin
            b_s_ready_skid |= b_ready_mux[i];
            r_s_ready_skid |= r_ready_mux[i];
        end
    end

    // ========== GRANT TRACKERS ========== //
    generate
        for (s_idx = 0; s_idx < NUM_TOTAL_SLAVES; s_idx++) begin
            // W Channel
            axi_grant_tracker #(
                .FIFO_DEPTH(MAX_OUTSTANDING_TX),
                .NUM_MASTERS(NUM_MASTERS)
            ) u_w_gt (
                .new_tx(aw_tx_started[s_idx]), 
                .tf_finished(w_s_tf_finished[s_idx]),
                .i_grant(aw_grant[s_idx]), 
                .full(w_full[s_idx]), 
                .o_grant(w_grant[s_idx]), .*
            );

            // B Channel
            axi_grant_tracker #(
                .FIFO_DEPTH(MAX_OUTSTANDING_TX),
                .NUM_MASTERS(NUM_MASTERS)
            ) u_b_gt (
                .new_tx(aw_tx_started[s_idx]), 
                .tf_finished(b_s_tf_finished[s_idx]),
                .i_grant(aw_grant[s_idx]), 
                .full(b_full[s_idx]), 
                .o_grant(b_master_req[s_idx]), .*
            );

            // R Channel
            axi_grant_tracker #(
                .FIFO_DEPTH(MAX_OUTSTANDING_TX),
                .NUM_MASTERS(NUM_MASTERS)
            ) u_r_gt (
                .new_tx(ar_tx_started[s_idx]), 
                .tf_finished(r_s_tf_finished[s_idx]),
                .i_grant(ar_grant[s_idx]), 
                .full(ar_full[s_idx]), 
                .o_grant(r_master_req[s_idx]), .*
            );
        end
    endgenerate

    // ========== DECERR HANDLERS ========== //
    logic [ID_WIDTH-1:0] decerr_b_id;
    logic [RESP_WIDTH-1:0] decerr_b_resp;
    logic [ID_WIDTH-1:0] decerr_r_id;
    logic [RESP_WIDTH-1:0] decerr_r_resp;
    logic decerr_r_last;

    assign b_s_payload_skid[DECERR_SLAVE] = {decerr_b_id, decerr_b_resp};
    assign b_s_id_skid[DECERR_SLAVE] = decerr_b_id;

    assign r_s_payload_skid[DECERR_SLAVE] = {decerr_r_id, {DATA_WIDTH{1'b0}}, decerr_r_resp, decerr_r_last};
    assign r_s_id_skid[DECERR_SLAVE] = decerr_r_id;

    /* verilator lint_off PINCONNECTEMPTY */
    axi_decerr_handler #(
        .ID_WIDTH(ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) u_dh_aw (
        .clk(clk),
        .n_rst(n_rst),
        .write(1'b1),
        .decerr(aw_s_valid_mux[DECERR_SLAVE]), 
        .address_id(aw_s_payload_mux[DECERR_SLAVE][14+:ID_WIDTH]),
        .read_len('0),
        .write_valid(w_s_valid_mux[DECERR_SLAVE]),
        .write_last(w_s_last_mux[DECERR_SLAVE]),
        .response_ready(b_s_ready_skid[DECERR_SLAVE]),
        .address_ready(aw_s_ready_mux[DECERR_SLAVE]),
        .write_ready(w_s_ready_mux[DECERR_SLAVE]), 
        .response_valid(b_s_valid_skid[DECERR_SLAVE]),
        .response_id(decerr_b_id),
        .response_resp(decerr_b_resp), 
        .response_last(),
        .decerr_grant()
    );

    axi_decerr_handler #( 
        .ID_WIDTH(ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) u_dh_ar (
        .clk(clk),
        .n_rst(n_rst),
        .write(1'b0),
        .decerr(ar_s_valid_mux[DECERR_SLAVE]), 
        .address_id(ar_s_payload_mux[DECERR_SLAVE][14+:ID_WIDTH]),
        .read_len(ar_s_payload_mux[DECERR_SLAVE][6+:LEN_WIDTH]),
        .write_valid(1'b0),
        .write_last(1'b0),
        .response_ready(r_s_ready_skid[DECERR_SLAVE]),
        .address_ready(ar_s_ready_mux[DECERR_SLAVE]),
        .write_ready(),
        .response_valid(r_s_valid_skid[DECERR_SLAVE]), 
        .response_id(decerr_r_id),
        .response_resp(decerr_r_resp), 
        .response_last(decerr_r_last),
        .decerr_grant()
    );
    /* verilator lint_on PINCONNECTEMPTY */

endmodule
