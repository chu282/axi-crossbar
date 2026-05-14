`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_skid_buffer ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    logic i_valid, i_ready, o_valid, o_ready;
    logic [31:0] i_data, o_data;

    skid_buffer #(.DATA_WIDTH(32)) DUT (.*);

    initial begin
        n_rst = 1;
        i_valid = 0;
        i_ready = 0;
        i_data = 0;
        
        reset_dut;
        @(negedge clk);

        i_valid = 1;
        i_ready = 1;
        i_data = 32'hDEADBEEF;
        @(negedge clk);
        i_data = 32'hBEEFDEAD;
        @(negedge clk);
        i_data = 32'hBEEFBEEF;
        @(negedge clk);
        i_data = 32'hDEADDEAD;
        @(negedge clk);

        i_ready = 0;
        i_data = 32'hABABABAB;
        @(negedge clk);
        @(negedge clk);

        i_ready = 1;
        @(negedge clk);

        $finish;
    end
endmodule

/* verilator coverage_on */

