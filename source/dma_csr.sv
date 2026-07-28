`timescale 1ns / 10ps

module dma_csr (
    parameter ADDR_WIDTH = 32,
) (
    input  logic clk, n_rst,
    axi_if.slave s,

    output logic [1:0] status,
    output logic [1:0] err,
    output logic start, stop,
    output logic [31:0] length,
    output logic [ADDR_WIDTH-1:0] from_addr, to_addr
);

    typedef enum logic {
        IDLE,
        BUSY,
        DONE,
        ERR
    } state_e;

    state_e state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always_comb begin : next_state_logic
        case (state)
            IDLE: begin
                if (s.awvalid) next_state = BUSY;
            end
            BUSY: begin
                if (s.wvalid && s.wlast) next_state = DONE;
            end
            DONE: begin
                if (s.bready) next_state = IDLE;
            end
            ERR: begin
                if (s.bready) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end    

    always_comb begin : fsm_output_logic
        s.arready = 0;
        s.wready = 0;
        s.bvalid = 0;
        s.bresp = 0;
        s.bid = 0;

        status = 0;
        err = 0;
        start = 0;
        stop = 0;
        length = 0;
        from_addr = 0;
        to_addr = 0;

        case (state)
            IDLE: begin
                s.arready = 1;
            end
            BUSY: begin
                s.wready = 1;
            end
            DONE: begin
                s.bvalid = 1;
                s.bresp = 2'b00;
                s.bid = s.awid;
            end
            ERR: begin
                s.bvalid = 1;
                s.bresp = 2'b10;
                s.bid = s.awid;
            end
            default: s.arready = 0;
        endcase
    end    

endmodule
