`timescale 1ns / 10ps

module dma_csr #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = 4,
    parameter ID_WIDTH = 4
) (
    input  logic clk, n_rst,
    axi_if.slave s,

    input  logic [1:0] status,
    input  logic [1:0] err,
    output logic start, stop,
    output logic [31:0] length,
    output logic [ADDR_WIDTH-1:0] from_addr, to_addr
);

    localparam OKAY = 2'b00;
    localparam SLVERR = 2'b10;

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

    logic [11:0] reg_araddr, reg_awaddr;
    logic [ID_WIDTH-1:0] reg_arid, reg_awid;
    logic [STRB_WIDTH-1:0] reg_wstrb;

    logic [1:0] bresp, rresp;
    logic rlast;
    logic [DATA_WIDTH-1:0] rdata;
    
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
                if (s.rready) next_read_state = R_IDLE;
            end
            default: next_read_state = R_IDLE;
        endcase
    end

    always_comb begin : axi_logic
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
                s.bresp = bresp;
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
                s.rresp = rresp;
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin : parameter_ff
        if (~n_rst) begin
            reg_araddr <= 0;
            reg_arid <= 0;

            reg_awaddr <= 0;
            reg_awid <= 0;
            reg_wstrb <= 0;
        end
        else begin
            if (write_state == W_IDLE && s.awvalid) begin
                reg_awaddr <= s.awaddr[11:0];
                reg_awid <= s.awid;
                reg_wstrb <= s.wstrb;
            end
            if (read_state == R_IDLE && s.arvalid) begin
                reg_araddr <= s.araddr[11:0];
                reg_arid <= s.arid;
            end
        end
    end

    logic [31:0] w_mask;
    logic [31:0] masked_data;

    logic [ADDR_WIDTH-1:0] next_from_addr, next_to_addr;
    logic [31:0] next_length;
    logic [1:0] next_control;
    logic [1:0] next_bresp, next_rresp;
    logic next_start, next_stop;
    
    always_comb begin : csr_logic
        w_mask = 0;

        next_from_addr = from_addr;
        next_to_addr = to_addr;
        next_length = length;
        next_control = 0;
        next_bresp = OKAY;
        next_rresp = OKAY;

        // write
        if (write_state == W_WRITE && s.wvalid) begin
            for (int i = 0; i < STRB_WIDTH; i++) begin
                w_mask[i*8+:8] = {8{reg_wstrb[i]}};
            end
            masked_data = s.wdata & w_mask;

            case (reg_awaddr) inside 
                [12'h0:12'h3]: begin
                    next_from_addr = (from_addr & ~w_mask) | masked_data;
                end
                [12'h4:12'h7]: begin
                    next_to_addr = (to_addr & ~w_mask) | masked_data;
                end
                [12'h8:12'hB]: begin
                    next_length = (length & ~w_mask) | masked_data;
                end
                12'hC: begin
                    next_control[0] = ~start & masked_data[0];
                    next_control[1] = ~stop & masked_data[1];
                end
                default: begin
                    next_bresp = SLVERR;
                end
            endcase
        end

        // read
        if (read_state == R_READ && s.arvalid) begin
            case (reg_araddr)
                12'hD: rdata = {30'd0, status};
                default: next_rresp = SLVERR;
            endcase
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : csr_regs
        if (~n_rst) begin
            from_addr <= 0;
            to_addr <= 0;
            length <= 0;
            start <= 0;
            stop <= 0;
            rresp <= OKAY;
            bresp <= OKAY;
        end
        else begin
            from_addr <= next_from_addr;
            to_addr <= next_to_addr;
            length <= next_length;
            start <= next_start;
            stop <= next_stop;
            rresp <= next_rresp;
            bresp <= next_bresp;
        end
    end

endmodule
