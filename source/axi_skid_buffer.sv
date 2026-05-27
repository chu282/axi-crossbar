`timescale 1ns / 10ps

module skid_buffer #(
    parameter PAYLOAD_WIDTH = 49
) (
    input logic clk, n_rst, src_valid, dst_ready, 
    input logic [PAYLOAD_WIDTH-1:0] src_payload,
    output logic dst_valid, src_ready,
    output logic [PAYLOAD_WIDTH-1:0] dst_payload
);

    typedef enum logic [1:0] {
        IDLE, BUSY, SKID
    } state_e;

    logic [PAYLOAD_WIDTH-1:0] main_reg, skid_reg;

    state_e state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin : reg_ffs
        if (~n_rst) begin
            main_reg <= 0;
            skid_reg <= 0;
            state <= IDLE;
        end
        else begin
            if (state != SKID && next_state == BUSY)
                main_reg <= src_payload;
            if (next_state == SKID)
                skid_reg <= src_payload;
            if (state == SKID && next_state == BUSY)
                main_reg <= skid_reg;
            state <= next_state;
        end
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: begin
                if (src_valid)
                    next_state = BUSY;
            end
            BUSY: begin 
                if (src_valid && ~dst_ready) // new piece of data, output cannot accept
                    next_state = SKID;
                else if (~src_valid && dst_ready) // output accepted data, input doesn't send new data; all data accounted for 
                    next_state = IDLE;
            end
            SKID: begin 
                if (dst_ready) // output accepts 1/2 items stored 
                    next_state = BUSY;
            end
            default: next_state = IDLE;
        endcase
    end

    assign dst_payload = main_reg;
    assign src_ready = state == IDLE || state == BUSY;
    assign dst_valid = state == BUSY || state == SKID;

endmodule
