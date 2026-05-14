`timescale 1ns / 10ps

module axi_arbiter #(
) (
    input  logic clk, n_rst, trans_finished
    input  logic [1:0] master_select
);

    typedef enum logic { 
        IDLE, BUSY
    } state_e;

    state_e state, next_state;
    logic trans_finished;

    always_ff @(posedge clk, negedge n_rst) begin : fsm
        if (~n_rst) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: if (master_select != 0) next_state = BUSY;
            BUSY: if (trans_finished) next_state = IDLE;
        endcase
    end

    always_comb begin : fsm_output
        case (state)
            IDLE: begin
                
            end
            BUSY: if (trans_finished) next_state = IDLE;
        endcase
    end

endmodule

