`timescale 1ns / 10ps

module axi_fifo #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
) (
    input  logic clk, n_rst, push, pop, 
    input  logic [WIDTH-1:0] in,
    output logic full, empty,
    output logic [WIDTH-1:0] out
);

    parameter PTR_WIDTH = $clog2(DEPTH);
    logic [DEPTH-1:0][WIDTH-1:0] fifo;
    logic [DEPTH-1:0][WIDTH-1:0] next_fifo;
    logic [PTR_WIDTH:0] ptr, next_ptr;

    always_ff @(posedge clk, negedge n_rst) begin : fifo_ff
        if (~n_rst) begin
            fifo <= 0;
            ptr <= 0;
        end
        else begin
            fifo <= next_fifo;
            ptr <= next_ptr;
        end
    end

    always_comb begin : next_fifo_logic
        next_fifo = fifo;
        next_ptr = ptr;
        if (push && pop) begin
            if (empty) begin
                next_fifo[ptr] = in;
                next_ptr++;
            end
            else begin
                next_fifo = next_fifo >> WIDTH;
                next_fifo[ptr-1] = in;
            end
        end 
        else if (push && ~full) begin
            next_fifo[ptr] = in;
            next_ptr++;
        end
        else if (pop && ~empty) begin
            next_fifo = next_fifo >> WIDTH;
            next_ptr--;
        end
    end

    assign full = (ptr == DEPTH);
    assign empty = (ptr == 0);
    assign out = fifo[0];

endmodule
