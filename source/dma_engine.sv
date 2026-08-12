`timescale 1ns / 10ps
module dma_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = 4,
    parameter FIFO_DEPTH = 16 // words
) (
    input  logic clk, n_rst,
    axi_if.master m,

    input  logic start, ack_done, ack_err,
    input  logic [31:0] length,
    input  logic [ADDR_WIDTH-1:0] from_addr, to_addr,
    output logic [1:0] status
);

    typedef enum logic [2:0] {
        IDLE,
        TRANS,
        DONE,
        ERR
    } dma_state_e;

    // DMA status
    localparam STATUS_IDLE = 2'b00;
    localparam STATUS_BUSY = 2'b01;
    localparam STATUS_DONE = 2'b10;
    localparam STATUS_ERR  = 2'b11;

    localparam OKAY = 2'b00; // AXI response
    localparam INCR = 2'b01; // AXI burst

    localparam MAX_TRANS_SIZE = 4 * 256;

    dma_state_e dma_state, next_dma_state;

    logic trans_err, slave_err, next_slave_err;
    logic transfer_done, last_read_tx;

    logic [7:0] w_bytes_transferred, next_w_bytes_transferred;
    logic [31:0] reg_from_addr, reg_to_addr, reg_length;
    logic [31:0] fifo_buf;

    logic w_first_trans, w_first_byte;
    logic r_first_trans, r_first_byte, next_r_first_byte;

    logic [ADDR_WIDTH-1:0] next_awaddr, next_araddr;
    logic [7:0] next_awlen, next_arlen;
    logic next_awvalid, next_arvalid;
    logic [DATA_WIDTH-1:0] next_wdata;
    logic [STRB_WIDTH-1:0] next_wstrb;
    logic next_wlast, next_wvalid;
    logic next_bready, next_rready;
    logic next_fifo_push;

    logic [DATA_WIDTH-1:0] fifo_in, fifo_out;
    logic fifo_push, fifo_pop, fifo_full, fifo_empty;

    axi_fifo #(
        .DEPTH(FIFO_DEPTH),
        .WIDTH(DATA_WIDTH)
    ) dma_fifo (
        .clk(clk),
        .n_rst(n_rst),
        .push(fifo_push),
        .pop(fifo_pop),
        .in(fifo_in),
        .full(fifo_full),
        .empty(fifo_empty),
        .out(fifo_out)
    );

    always_ff @(posedge clk, negedge n_rst) begin : fsm_regs
        if (~n_rst) begin
            dma_state <= IDLE;

            slave_err <= 0;
        end
        else begin
            dma_state <= next_dma_state;

            slave_err <= next_slave_err;
        end
    end

    always_comb begin : next_state_logic
        next_dma_state = dma_state;

        case (dma_state)
            IDLE: begin
                if (trans_err) next_dma_state = ERR;
                else if (start) next_dma_state = TRANS;
            end
            TRANS: begin
                if (transfer_done) begin
                    if (slave_err) next_dma_state = ERR;
                    else next_dma_state = DONE;
                end
            end
            DONE: begin
                if (ack_done) next_dma_state = IDLE;
            end
            ERR: begin
                if (ack_err) next_dma_state = IDLE;
            end
            default: next_dma_state = IDLE;
        endcase
    end

    always_comb begin : output_logic
        case (dma_state)
            IDLE: status = STATUS_IDLE;
            TRANS: status = STATUS_BUSY;
            DONE: status = STATUS_DONE;
            ERR: status = STATUS_ERR;
            default: status = STATUS_ERR;
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin : axi_regs
        if (~n_rst) begin
            m.awaddr <= 0;
            m.awlen <= 0;
            m.awvalid <= 0;

            m.wdata <= 0;
            m.wstrb <= 0;
            m.wlast <= 0;
            m.wvalid <= 0;

            m.araddr <= 0;
            m.arlen <= 0;
            m.arvalid <= 0;

            m.bready <= 0;
            m.rready <= 0;
        end
        else begin
            m.awaddr <= next_awaddr;
            m.awlen <= next_awlen;
            m.awvalid <= next_awvalid;

            m.wdata <= next_wdata;
            m.wstrb <= next_wstrb;
            m.wlast <= next_wlast;
            m.wvalid <= next_wvalid;

            m.araddr <= next_araddr;
            m.arlen <= next_arlen;
            m.arvalid <= next_arvalid;

            m.bready <= next_bready;
            m.rready <= next_rready;
        end
    end

    logic [1:0] w_last_byte;
    logic [1:0] w_byte_offset;
    logic [1:0] r_byte_offset;

    logic [31:0] w_start_word;
    logic [31:0] w_end_word;
    logic [31:0] r_start_word;
    logic [31:0] r_end_word;

    logic [31:0] w_bytes_left;
    logic [31:0] r_bytes_left;

    logic [5:0] offset_diff;
    logic [31:0] next_fifo_buf;

    logic [7:0] beat_count, next_beat_count;
    logic [STRB_WIDTH-1:0] start_strb, end_strb;

    logic fifo_flush;

    always_comb begin : axi_logic
        // hardcoded signals
        m.awlock = 0;
        m.awburst = INCR;
        m.awsize = 3'b010;
        m.arlock = 0;
        m.arburst = INCR;
        m.arsize = 3'b010;

        next_awaddr = m.awaddr;
        next_awlen = m.awlen;
        next_awvalid = 0;

        next_wdata = 0;
        next_wstrb = 0;
        next_wlast = 0;
        next_wvalid = 0;

        next_araddr = m.araddr;
        next_arlen = m.arlen;
        next_arvalid = m.arvalid;

        next_bready = 0;
        next_rready = 0;

        trans_err = 0;
        next_slave_err = 0;
        last_read_tx = 0;

        fifo_in = 0;
        fifo_push = 0;
        fifo_pop = 0;
        next_fifo_buf = 0;
        next_fifo_push = 0;
        w_last_byte = 0;
        r_bytes_left = 0;
        w_bytes_left = 0;
        r_byte_offset = 0;
        w_byte_offset = 0;
        next_w_bytes_transferred = 0;
        transfer_done = 0;

        r_start_word = 0;
        r_end_word = 0;
        w_start_word = 0;
        w_end_word = 0;

        start_strb = 0;
        end_strb = 0;
        offset_diff = 0;
        next_beat_count = beat_count;

        case (dma_state)
            IDLE: begin
                if (start) begin
                    // check if transaction goes across 4KB boundary
                    if (to_addr[11:0] + length[11:0] > 13'h1000 || from_addr[11:0] + length[11:0] > 13'h1000)
                        trans_err = 1;
                    // check if from/to memory chunks overlap
                    if ((to_addr > from_addr && to_addr < from_addr + length) ||
                        (to_addr < from_addr && from_addr < to_addr + length) ||
                        (to_addr == from_addr))
                        trans_err = 1;
                end
            end
            TRANS: begin
                r_byte_offset = reg_from_addr[1:0];
                w_byte_offset = reg_to_addr[1:0];

                // AW
                w_bytes_left = reg_to_addr + reg_length - m.awaddr;

                if (w_first_trans) begin
                    next_awaddr = reg_to_addr;
                    next_awvalid = 1;
                end
                else if (m.wvalid && m.wready && m.wlast && w_bytes_left > MAX_TRANS_SIZE) begin
                    next_awaddr = m.awaddr + MAX_TRANS_SIZE;
                    next_awvalid = 1;
                end

                if (m.awvalid && m.awready)
                    next_awvalid = 0;

                w_start_word = next_awaddr >> 2;
                if (reg_to_addr + reg_length - next_awaddr < MAX_TRANS_SIZE) // next transfer is the last one
                    w_end_word = (reg_to_addr + reg_length - 1) >> 2;
                else // next transfer is not the last one
                    w_end_word = (next_awaddr + MAX_TRANS_SIZE - 1) >> 2;
                next_awlen = 8'(w_end_word - w_start_word);

                // W
                next_wvalid = ~fifo_empty;
                next_wdata = fifo_out;
                if (m.wready && m.wvalid) begin
                    fifo_pop = 1;
                    if (m.wlast)
                        next_beat_count = 0;
                    else 
                        next_beat_count = beat_count + 1;
                end

                next_wlast = beat_count == m.awlen;
                w_last_byte = m.awaddr[1:0] + ((m.awlen[1:0] + 1'b1) << m.awsize[1:0]) - 1'b1;
                start_strb = {STRB_WIDTH{1'b1}} << w_byte_offset;
                end_strb = {STRB_WIDTH{1'b1}} >> (3 - w_last_byte);

                if (w_first_byte && next_wlast)
                    next_wstrb = start_strb & end_strb;
                else if (w_first_byte)
                    next_wstrb = start_strb;
                else if (next_wlast)
                    next_wstrb = end_strb;
                else
                    next_wstrb = {STRB_WIDTH{1'b1}};

                // B
                next_bready = 1;
                if (m.bvalid && m.bready) begin
                    if (m.bresp != OKAY)
                        next_slave_err = 1;
                    if (w_bytes_left < MAX_TRANS_SIZE)
                        transfer_done = 1;
                end

                // AR
                r_bytes_left = reg_from_addr + reg_length - m.araddr;

                if (r_first_trans) begin
                    next_araddr = reg_from_addr;
                    next_arvalid = 1;
                end
                else if (m.rvalid && m.rready && m.rlast && r_bytes_left > MAX_TRANS_SIZE) begin
                    next_araddr = m.araddr + MAX_TRANS_SIZE;
                    next_arvalid = 1;
                end

                if (m.arvalid && m.arready)
                    next_arvalid = 0;

                r_start_word = next_araddr >> 2;
                if (reg_from_addr + reg_length - next_araddr < MAX_TRANS_SIZE) // next transfer is the last one
                    r_end_word = (reg_from_addr + reg_length - 1) >> 2;
                else // next transfer is not the last one
                    r_end_word = (next_araddr + MAX_TRANS_SIZE - 1) >> 2;
                next_arlen = 8'(r_end_word - r_start_word);

                // R
                next_rready = ~fifo_full;
                if (m.rvalid && m.rready) begin
                    if (r_byte_offset > w_byte_offset) begin // araddr starts at higher byte lane than awaddr
                        offset_diff = 5'(r_byte_offset - w_byte_offset) * 8;
                        next_fifo_buf = m.rdata >> offset_diff;
                        fifo_in = fifo_buf | (m.rdata << (32 - offset_diff));
                        fifo_push = ~r_first_byte;
                    end
                    else if (r_byte_offset < w_byte_offset) begin // araddr starts at lower byte lane than awaddr
                        offset_diff = 5'(w_byte_offset - r_byte_offset) * 8;
                        next_fifo_buf = m.rdata >> (32 - offset_diff);
                        fifo_in = fifo_buf | (m.rdata << offset_diff);
                        fifo_push = 1;
                    end
                    else begin // araddr starts at same byte lane as awaddr
                        fifo_in = m.rdata;
                        fifo_push = 1;
                    end
                end
                if (fifo_flush)
                    fifo_push = 1;
            end
            DONE: begin
            end
            ERR: begin
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin : intermediate_logic_regs
        if (~n_rst) begin
            r_first_trans <= 0;
            w_first_trans <= 0;
            r_first_byte <= 0;
            w_first_byte <= 0;
            reg_from_addr <= 0;
            reg_to_addr <= 0;
            reg_length <= 0;
            fifo_buf <= 0;
            w_bytes_transferred <= 0;
            fifo_flush <= 0;
            beat_count <= 0;
        end 
        else begin
            if (start) begin
                r_first_trans <= 1;
                w_first_trans <= 1;
                reg_from_addr <= from_addr;
                reg_to_addr <= to_addr;
                reg_length <= length;
                r_first_byte <= 1;
                w_first_byte <= 1;
            end
            if (m.arvalid && m.arready) r_first_trans <= 0;
            if (m.awvalid && m.awready) w_first_trans <= 0;

            if (m.rlast && m.rready && m.rvalid)
                r_first_byte <= 1;
            else if (m.rready && m.rvalid)
                r_first_byte <= 0;
                
            if (m.wlast && m.wready && m.wvalid)
                w_first_byte <= 1;
            else if (m.wready && m.wvalid)
                w_first_byte <= 0;

            beat_count <= next_beat_count;

            w_bytes_transferred <= next_w_bytes_transferred;

            if (m.rlast && m.rvalid && m.rready && r_byte_offset != w_byte_offset)
                fifo_flush <= 1;
            else
                fifo_flush <= 0;

            fifo_buf <= next_fifo_buf;
        end
    end

endmodule
