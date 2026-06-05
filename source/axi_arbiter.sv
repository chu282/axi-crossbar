`timescale 1ns / 10ps

module axi_arbiter #(
    parameter NUM_DEVICES = 2
) (
    input  logic clk, n_rst, tf_finished,
    input  logic [NUM_DEVICES-1:0] request,
    output logic [NUM_DEVICES-1:0] grant
);

    logic tf_started, lock, next_lock;
    logic [NUM_DEVICES-1:0] next_grant, locked_grant, next_locked_grant, last_grant, next_last_grant, upper_mask, masked_req;

    always_comb begin : rr_logic
        tf_started = 0;
        next_grant = 0;
        next_lock = lock;
        upper_mask = ~(last_grant | (last_grant-1)); // mask of valid devices above last device 
        masked_req = upper_mask & request; // devices above last device that are currently requesting  

        if (request != 0) begin // new request
            tf_started = 0;
            if (lock && ~tf_finished) // check if locked (prev transaction hasnt finished)
                next_grant = locked_grant;
            else begin // unlocked, calculate new grant
                if (masked_req != 0) next_grant = masked_req & ~(masked_req-1);
                else next_grant = request & ~(request-1);
                tf_started = 1;
            end
        end

        if (tf_started)
            next_locked_grant = next_grant;
        else 
            next_locked_grant = locked_grant;

        // keep track of previous grant for rr
        if (tf_started)
            next_last_grant = next_grant;
        else
            next_last_grant = last_grant;

        if (tf_started) begin
            if (grant != next_grant)
                next_lock = 1;
            else 
                next_lock = 0;
        end
        else if (tf_finished) begin
            next_lock = 0;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : grant_lock_ff
        if (~n_rst) begin
            lock <= 0;
            locked_grant <= 0;
            last_grant <= 0;
            grant <= 0;
        end
        else begin
            lock <= next_lock;
            locked_grant <= next_locked_grant;
            last_grant <= next_last_grant;
            grant <= next_grant;
        end
    end

endmodule
