`timescale 1ns / 10ps

module skid_buffer #(
    parameter PAYLOAD_WIDTH = 49
) (
    input logic clk, n_rst, master_valid, slave_ready, 
    input logic [DATA_WIDTH-1:0] master_data,
    output logic slave_valid, master_ready,
    output logic [DATA_WIDTH-1:0] slave_data
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
                main_reg <= master_data;
            if (next_state == SKID)
                skid_reg <= master_data;
            if (state == SKID && next_state == BUSY)
                main_reg <= skid_reg;
            state <= next_state;
        end
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: begin
                if (master_valid)
                    next_state = BUSY;
            end
            BUSY: begin 
                if (master_valid && ~slave_ready) // new piece of data, slave cannot accept
                    next_state = SKID;
                else if (~master_valid && slave_ready) // slave accepted data, master doesn't send new data; all data accounted for 
                    next_state = IDLE;
            end
            SKID: begin 
                if (slave_ready) // slave accepts 1/2 items stored 
                    next_state = BUSY;
            end
            default: next_state = IDLE;
        endcase
    end

    assign slave_data = main_reg;
    assign master_ready = state == IDLE || state == BUSY;
    assign slave_valid = state == BUSY || state == SKID;

endmodule
