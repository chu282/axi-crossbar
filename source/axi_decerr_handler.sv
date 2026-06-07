module axi_decerr_handler #(
    parameter ID_WIDTH = 4, 
    parameter PAYLOAD_WIDTH = 6
) (
    input  logic clk, n_rst, 
    input  logic skip_write, decerr, response_ready, write_valid, write_last, 
    input  logic [ID_WIDTH-1:0] address_id, 
    output logic response_valid, address_ready, write_ready, decerr_grant,
    output logic [PAYLOAD_WIDTH-1:0] response_payload
);

    localparam DECERR = 2'b11;

    logic [ID_WIDTH-1:0] response_id;

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

    always_ff @(posedge clk, negedge n_rst) begin : id_ff
        if(~n_rst) begin
            response_id <= 0;
        end
        else if (state == IDLE && next_state == SEND_ADDR_READY) begin
            response_id <= address_id;
        end
    end

    always_comb begin : next_state_logic
        next_state = state;
        case (state)
            IDLE: begin
                next_state = decerr ? SEND_ADDR_READY : IDLE;
            end
            SEND_ADDR_READY: begin // dont need to wait, address already valid
                next_state = skip_write ? SEND_RESP : SEND_W_READY;
            end
            SEND_W_READY: begin // wait until last data sent (although we dont need it)
                if (write_valid && write_last)
                    next_state = SEND_RESP;
            end
            SEND_RESP: begin // wait until response is ready to be accepted
                if (response_ready)
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
                response_payload = 0;
                decerr_grant = 0;
            end
            SEND_ADDR_READY: begin
                address_ready = 1;
                write_ready = 0;
                response_valid = 0;
                response_payload = 0;
                decerr_grant = 1;
            end
            SEND_W_READY: begin
                address_ready = 0;
                write_ready = 1;
                response_valid = 0;
                response_payload = 0;
                decerr_grant = 1;
            end
            SEND_RESP: begin
                address_ready = 0;
                write_ready = 0;
                response_valid = 1;
                response_payload = {response_id, DECERR};
                decerr_grant = 1;
            end
            default: begin
                address_ready = 0;
                write_ready = 0;
                response_valid = 0;
                response_payload = 0;
                decerr_grant = 0;
            end
        endcase
    end

endmodule
