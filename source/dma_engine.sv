`timescale 1ns / 10ps

module dma_engine (
    input  logic clk, n_rst,
    axi_if.master m,

    input  logic start, stop, ack_done, ack_err,
    input  logic [31:0] length,
    input  logic [ADDR_WIDTH-1:0] from_addr, to_addr
    output  logic [1:0] status,
);

    FIFO_DEPTH = 16;

    typedef enum logic [1:0] {
        W_IDLE,
        W_WRITE,
        W_RESP
    } write_state_e;

    typedef enum logic {
        R_IDLE,
        R_READ
    } read_state_e;

    write_state_e write_state, next_write_state;
    read_state_e read_state, next_read_state;



endmodule
