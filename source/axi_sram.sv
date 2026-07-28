`timescale 1ns / 10ps

module axi_sram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter DEPTH = 1024
) (
    input  logic clk, n_rst, 
    axi_if.slave s
);

    localparam OKAY = 2'b00;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    typedef enum logic [1:0] {
        W_IDLE,
        W_WRITE,
        W_RESP
    } write_state_e;

    typedef enum logic {
        R_IDLE,
        R_READ
    } read_state_e;

    write_state_e write_state, next_write_state;
    read_state_e read_state, next_read_state;

    logic rlast;
    logic [DATA_WIDTH-1:0] rdata;

    logic [ADDR_WIDTH-1:0] reg_awaddr, reg_araddr;
    logic [ID_WIDTH-1:0] reg_awid, reg_arid;
    logic [7:0] reg_awlen, reg_arlen;
    logic [2:0] reg_awsize, reg_arsize;
    logic [1:0] reg_awburst, reg_arburst;

    logic [ADDR_WIDTH-1:0] rbeat_count, next_rbeat_count, wbeat_count, next_wbeat_count;
    logic [$clog2(DEPTH)-1:0] read_idx, write_idx;

    always_ff @(posedge clk, negedge n_rst) begin : state_ff
        if (~n_rst) begin
            write_state <= W_IDLE;
            read_state <= R_IDLE;
        end
        else begin
            write_state <= next_write_state;
            read_state <= next_read_state;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : parameter_ff
        if (~n_rst) begin
            reg_awaddr <= 0;
            reg_awid <= 0;
            reg_awlen <= 0;
            reg_awsize <= 0;
            reg_awburst <= 0;
            
            reg_araddr <= 0;
            reg_arid <= 0;
            reg_arlen <= 0;
            reg_arsize <= 0;
            reg_arburst <= 0;
        end
        else begin
            if (write_state == W_IDLE && s.awvalid) begin
                reg_awaddr <= s.awaddr;
                reg_awid <= s.awid;
                reg_awlen <= s.awlen;
                reg_awsize <= s.awsize;
                reg_awburst <= s.awburst;
            end
            if (read_state == R_IDLE && s.arvalid) begin
                reg_araddr <= s.araddr;
                reg_arid <= s.arid;
                reg_arlen <= s.arlen;
                reg_arsize <= s.arsize;
                reg_arburst <= s.arburst;
            end
        end
    end

    always_comb begin : next_state_logic
        next_write_state = write_state;
        next_read_state = read_state;
        
        case (write_state)
            W_IDLE: begin
                if (s.awvalid) next_write_state = W_WRITE;
            end
            W_WRITE: begin
                if (s.wvalid && s.wlast) next_write_state = W_RESP;
            end
            W_RESP: begin
                if (s.bready) next_write_state = W_IDLE;
            end
            default: next_write_state = W_IDLE;
        endcase

        case (read_state)
            R_IDLE: begin
                if (s.arvalid) next_read_state = R_READ;
            end
            R_READ: begin
                if (s.rready && rlast) next_read_state = R_IDLE;
            end
            default: next_read_state = R_IDLE;
        endcase
    end

    always_comb begin : output_logic
        s.awready = 0;
        s.wready = 0;

        s.arready = 0;
        s.rid = 0;
        s.rdata = 0;
        s.rresp = 0;
        s.rlast = 0;
        s.rvalid = 0;
        
        s.bid = 0;
        s.bresp = 0;
        s.bvalid = 0;

        case (write_state)
            W_IDLE: begin
                s.awready = 1;
            end
            W_WRITE: begin
                s.wready = 1;
            end
            W_RESP: begin
                s.bvalid = 1;
                s.bid = reg_awid;
                s.bresp = OKAY;
            end
            default: s.awready = 0;
        endcase

        case (read_state)
            R_IDLE: begin
                s.arready = 1;
            end
            R_READ: begin
                s.rid = reg_arid;
                s.rlast = rlast;
                s.rvalid = 1;
                s.rdata = rdata;
                s.rresp = OKAY;
            end
        endcase
    end

    always_comb begin : transfer_logic
        // read
        rlast = 0;
        rdata = 0;
        next_rbeat_count = rbeat_count;
        
        if (read_state == R_IDLE) next_rbeat_count = 0;
        else begin
            if (s.rready && s.rvalid) next_rbeat_count = rbeat_count + 1;
            else next_rbeat_count = rbeat_count;
        end

        read_idx = $clog2(DEPTH)'((reg_araddr + (rbeat_count << reg_arsize)) >> 2);
        rdata = mem[read_idx];
        rlast = rbeat_count[7:0] == reg_arlen;

        // write
        next_wbeat_count = wbeat_count;
        if (write_state == W_IDLE) next_wbeat_count = 0;
        else if (write_state == W_WRITE) begin
            if (s.wready && s.wvalid) next_wbeat_count = wbeat_count + 1;
            else next_wbeat_count = wbeat_count;
        end

        write_idx = $clog2(DEPTH)'((reg_awaddr + (wbeat_count << reg_awsize)) >> 2);
    end

    always_ff @(posedge clk) begin : write_ff
        if (write_state == W_WRITE && s.wready && s.wvalid) begin
            for (int i = 0; i < DATA_WIDTH / 8; i++) begin
                if (s.wstrb[i]) mem[write_idx][i*8+:8] <= s.wdata[i*8+:8];
            end
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : beat_count_ff
        if (~n_rst) begin
            rbeat_count <= 0;
            wbeat_count <= 0;
        end
        else begin
            rbeat_count <= next_rbeat_count;
            wbeat_count <= next_wbeat_count;
        end
    end

endmodule
