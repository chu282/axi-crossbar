`timescale 1ns / 10ps

module axi_edge_det #(
    parameter TRIG_RISE = 1,
    parameter TRIG_FALL = 0
) (
    input  logic clk, n_rst, in,
    output logic edge_flag
);

    logic last_val;
    always_ff @(posedge clk, negedge n_rst) begin
        if (n_rst == 1'b0) begin
            last_val <= 0;
        end
        else begin
            last_val <= in;
        end
    end

    always_comb begin
        if (~last_val && in && TRIG_RISE)
            edge_flag = 1'b1;
        else if (last_val && ~in && TRIG_FALL)
            edge_flag = 1'b1;
        else if (last_val ^ in && TRIG_FALL && TRIG_RISE)
            edge_flag = 1'b1;
        else
            edge_flag = 1'b0;
    end

endmodule
