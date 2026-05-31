import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

NUM_MASTERS = 8
FIFO_DEPTH = 8

@cocotb.test()
async def test_axi_grant_tracker(dut):
    test = dut.test
    # Inputs
    clk = dut.clk
    n_rst = dut.n_rst
    new_tx = dut.new_tx
    tf_finished = dut.tf_finished
    i_grant = dut.i_grant

    # Outputs
    full = dut.full
    o_grant = dut.o_grant

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    n_rst.value = 0
    new_tx.value = 0
    tf_finished.value = 0
    i_grant.value = 0

    await FallingEdge(clk)
    n_rst.value = 1

    dut._log.info("---- Fill up queue ----")
    test.value = 1
    new_tx.value = 1
    for i in range(NUM_MASTERS):
        i_grant.value = 0b1 << i
        await FallingEdge(clk)
        assert full.value == (i == NUM_MASTERS-1)
        assert o_grant.value == 0b1

    dut._log.info("---- Attempt to surpass queue depth ----")
    test.value = 2
    await FallingEdge(clk)
    assert full.value == 1
    assert o_grant.value == 0b1

    dut._log.info("---- Empty queue ----")
    test.value = 3
    new_tx.value = 0
    tf_finished.value = 1
    for i in range(NUM_MASTERS):
        assert o_grant.value == 0b1 << i
        await FallingEdge(clk)
        assert full.value == 0

    dut._log.info("---- Interleaved operation ----")
    test.value = 4
    i_grant_vals =     [1 << 2, 1 << 3, 1 << 7, 1 << 5, 0, 0, 0, 1 << 4, 1, 1 << 4, 0, 1 << 5, 0, 1 << 6, 1, 0, 0, 0, 0, 0]
    new_tx_vals =      [1     , 1     , 1     , 1     , 0, 0, 0, 1     , 1, 1     , 0, 1     , 0, 1     , 1, 0, 0, 0, 0, 0]
    tf_finished_vals = [0     , 1     , 0     , 0     , 0, 1, 1, 1     , 0, 1     , 0, 0     , 1, 0     , 1, 1, 1, 1, 1, 1]

    exp_fifo = []
    for i in range(20):
        i_grant.value = i_grant_vals[i]
        new_tx.value = new_tx_vals[i]
        tf_finished.value = tf_finished_vals[i]
        
        if tf_finished_vals[i] == 1 and len(exp_fifo) != 0:
            exp_fifo.pop(0)
        if new_tx_vals[i] == 1:
            exp_fifo.append(i_grant_vals[i])
        if len(exp_fifo) == 0:
            exp_o_grant = 0
        else:
            exp_o_grant = exp_fifo[0]

        await FallingEdge(clk)
        assert full.value == (len(exp_fifo) == FIFO_DEPTH)
        assert o_grant.value == (exp_o_grant)

    dut._log.info("---- Reset ----")
    test.value = 5
    n_rst.value = 0
    await FallingEdge(clk)
    n_rst.value = 1

    assert full.value == 0
    assert o_grant.value == 0