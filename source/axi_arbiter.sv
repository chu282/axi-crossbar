`timescale 1ns / 10ps

module axi_arbiter #(
    parameter NUM_DEVICES = 2
) (
    input  logic clk, n_rst, tf_finished,
    input  logic [NUM_DEVICES-1:0] request,
    output logic [NUM_DEVICES-1:0] grant
);

    logic tf_started, lock, next_lock;
    logic [NUM_DEVICES-1:0] locked_grant, next_locked_grant, last_grant, next_last_grant, upper_mask, masked_req;

    always_comb begin : rr_logic
        tf_started = 0;
        grant = 0;
        upper_mask = ~(last_grant | (last_grant-1)); // mask of valid devices above last device 
        masked_req = upper_mask & request; // devices above last device that are currently requesting  

        if (request != 0) begin // new request
            tf_started = 0;
            if (lock && ~tf_finished) // check if locked (prev transaction hasnt finished)
                grant = locked_grant;
            else begin // unlocked, calculate new grant
                if (masked_req != 0) grant = masked_req & ~(masked_req-1);
                else grant = request & ~(request-1);
                tf_started = 1;
            end
        end

        if (tf_started)
            next_locked_grant = grant;
        else 
            next_locked_grant = locked_grant;

        // keep track of previous grant for rr
        if (tf_started)
            next_last_grant = grant;
        else
            next_last_grant = last_grant;
    end

    always_ff @(posedge clk, negedge n_rst) begin : lock_ff
        if (~n_rst) begin
            lock <= 0;
            locked_grant <= 0;
            last_grant <= 0;
        end
        else begin
            if (tf_started)
                lock <= 1;
            else if (tf_finished)
                lock <= 0;
            locked_grant <= next_locked_grant;
            last_grant <= next_last_grant;
        end
    end

    // typedef enum logic { 
    //     IDLE, BUSY
    // } state_e;

    // state_e state, next_state;
    // logic [NUM_DEVICES-1:0] last_grant, next_last_grant, upper_mask, masked_req;

    // always_ff @(posedge clk, negedge n_rst) begin : fsm
    //     if (~n_rst) begin 
    //         state <= IDLE;
    //     end
    //     else begin
    //         state <= next_state;
    //     end
    // end

    // always_ff @(posedge clk, negedge n_rst) begin : rr_ff
    //     if (~n_rst) begin 
    //         last_grant <= 0;
    //     end
    //     else begin
    //         last_grant <= next_last_grant;
    //     end
    // end

    // // We lock the grant (state=BUSY) until the transfer finishes so that it is not overwritten by another master
    // // trying to communicate with the same slave. 
    // always_comb begin : next_state_logic
    //     next_state = state;
    //     case (state)
    //         IDLE: if (request != 0) next_state = BUSY;
    //         BUSY: begin
    //             if (tf_finished && request == 0) next_state = IDLE;
    //             else next_state = BUSY;
    //         end
    //     endcase
    // end

    // always_comb begin : rr_logic
    //     upper_mask = ~(last_grant | (last_grant-1)); // mask of valid devices above last device 
    //     masked_req = upper_mask & request; // devices above last device that are currently requesting  

    //     if (state == IDLE) begin
    //         if (masked_req != 0) grant = masked_req & ~(masked_req-1); // valid devices above last, do priority using top part
    //         else grant = request & ~(request-1); // no valid devices above last, do priority using whole request
    //     end
    //     else begin
    //         grant = last_grant;
    //     end

    //     // when receiving a new grant, we need to save it
    //     if (state == IDLE && next_state == BUSY || state == BUSY && tf_finished && next_state == BUSY) next_last_grant = grant;
    //     else next_last_grant = last_grant;
    // end

endmodule

/*
1. two master requests come in
2. grant evaluates which one should be granted
3. next cycle
4. transition to BUSY
5. register last_grant
6. in BUSY, grant = last_grant
7. tf_finished, transition to IDLE
8. grant is now combinational again. last_grant points at last grant
*/
