module axi_decerr_handler #(
    parameter ID_WIDTH = 4,
    parameter LEN_WIDTH = 8
) (
    input  logic clk, n_rst, 
    input  logic write, decerr, response_ready, write_valid, write_last, 
    input  logic [ID_WIDTH-1:0] address_id, 
    input  logic [LEN_WIDTH-1:0] read_len, 
    output logic response_valid, response_last, address_ready, write_ready, decerr_grant,
    output logic [ID_WIDTH-1:0] response_id,
    output logic [1:0] response_resp
);

    localparam DECERR = 2'b11;

    logic [ID_WIDTH-1:0] reg_id;
    logic [LEN_WIDTH-1:0] reg_len;
    logic [LEN_WIDTH-1:0] sent_responses;

    typedef enum logic [1:0] {
        IDLE, SEND_ADDR_READY, SEND_W_READY, SEND_RESP
    } state_e;

    state_e state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin : state_ff
        if (~n_rst) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : capture_ff
        if(~n_rst) begin
            reg_id <= 0;
            reg_len <= 0;
            sent_responses <= 0;
        end
        else if (state == SEND_ADDR_READY && decerr) begin
            reg_id <= address_id;
            reg_len <= read_len;
            sent_responses <= 0;
        end
        else if (state == SEND_RESP && response_ready) begin
            sent_responses <= sent_responses + 1;
        end
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: begin
                next_state = decerr ? SEND_ADDR_READY : IDLE;
            end
            SEND_ADDR_READY: begin // send ready to complete handshake
                if (write) 
                    next_state = SEND_W_READY;
                else 
                    next_state = SEND_RESP;
            end
            SEND_W_READY: begin // wait until last data sent (although we dont need it)
                if (write_valid && write_last)
                    next_state = SEND_RESP;
            end
            SEND_RESP: begin // send read_len responses
                if (response_ready && (sent_responses == reg_len)) 
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always_comb begin : output_logic
        case (state)
            IDLE: begin
                address_ready = 0;
                write_ready = 0;
                response_valid = 0;
                response_resp = 0;
                response_id = 0;
                decerr_grant = 0;
                response_last = 0;
            end
            SEND_ADDR_READY: begin
                address_ready = 1;
                write_ready = 0;
                response_valid = 0;
                response_resp = 0;
                response_id = 0;
                decerr_grant = 1;
                response_last = 0;
            end
            SEND_W_READY: begin
                address_ready = 0;
                write_ready = 1;
                response_valid = 0;
                response_resp = 0;
                response_id = 0;
                decerr_grant = 1;
                response_last = 0;
            end
            SEND_RESP: begin
                address_ready = 0;
                write_ready = 0;
                response_valid = 1;
                response_resp = DECERR;
                response_id = reg_id;
                decerr_grant = 1;
                response_last = sent_responses == reg_len;
            end
            default: begin
                address_ready = 0;
                write_ready = 0;
                response_valid = 0;
                response_resp = 0;
                response_id = 0;
                decerr_grant = 0;
                response_last = 0;
            end
        endcase
    end

endmodule
