`timescale 1ns / 10ps

module skid_buffer #(
    parameter DATA_WIDTH = 32
) (
    input logic clk, n_rst, i_valid, i_ready, 
    input logic [DATA_WIDTH-1:0] i_data,
    output logic o_valid, o_ready,
    output logic [DATA_WIDTH-1:0] o_data
);

    typedef enum logic [1:0] {
        IDLE, BUSY, SKID
    } state_e;

    logic [DATA_WIDTH-1:0] main_reg, skid_reg;

    state_e state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin : reg_ffs
        if (~n_rst) begin
            main_reg <= 0;
            skid_reg <= 0;
            state <= IDLE;
        end
        else begin
            if (state != SKID && next_state == BUSY)
                main_reg <= i_data;
            if (next_state == SKID)
                skid_reg <= i_data;
            if (state == SKID && next_state == BUSY)
                main_reg <= skid_reg;
            state <= next_state;
        end
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: begin
                if (i_valid)
                    next_state = BUSY;
            end
            BUSY: begin 
                if (i_valid && ~i_ready) // new piece of data, slave cannot accept
                    next_state = SKID;
                else if (~i_valid && i_ready) // slave accepted data, master doesn't send new data; all data accounted for 
                    next_state = IDLE;
            end
            SKID: begin 
                if (i_ready) // slave accepts 1/2 items stored 
                    next_state = BUSY;
            end
            default: next_state = IDLE;
        endcase
    end

    assign o_data = main_reg;
    assign o_ready = state == IDLE || state == BUSY;
    assign o_valid = state == BUSY || state == SKID;

endmodule

