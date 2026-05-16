`timescale 1ns / 10ps

module axi_arbiter #(
    parameter NUM_MASTERS = 2
) (
    input  logic clk, n_rst, trans_finished,
    input  logic [NUM_MASTERS-1:0] master_req,
    output logic [NUM_MASTERS-1:0] grant
);

    typedef enum logic { 
        IDLE, BUSY
    } state_e;

    state_e state, next_state;
    logic [NUM_MASTERS-1:0] last_grant, next_last_grant, upper_mask, masked_req;

    always_ff @(posedge clk, negedge n_rst) begin : fsm
        if (~n_rst) begin 
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : rr_ff
        if (~n_rst) begin 
            last_grant <= 0;
        end
        else begin
            last_grant <= next_last_grant;
        end
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: if (master_req != 0) next_state = BUSY;
            BUSY: if (trans_finished) next_state = IDLE;
        endcase
    end

    always_comb begin : rr_logic
        upper_mask = ~(last_grant | (last_grant-1)); // mask of valid masters above last master 
        masked_req = upper_mask & master_req; // masters above last master that are currently requesting  

        if (state == IDLE) begin
            if (masked_req != 0) grant = masked_req & ~(masked_req-1); // valid masters above last, do priority using top part
            else grant = master_req & ~(master_req-1); // no valid masters above last, do priority using whole request
        end
        else begin
            grant = last_grant;
        end

        if (state == IDLE && next_state == BUSY) next_last_grant = grant;
        else next_last_grant = last_grant;
    end

endmodule

/*
1. two master requests come in
2. grant evaluates which one should be granted
3. next cycle
4. transition to BUSY
5. register last_grant
6. in BUSY, grant = last_grant
7. trans_finished, transition to IDLE
8. grant is now combinational again. last_grant points at last grant
*/
