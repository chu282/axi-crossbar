import cocotb

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_axi_skid_buffer(dut):

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    clk = dut.clk

    dut.n_rst.value = 0
    dut.src_valid.value = 0
    dut.dst_ready.value = 0
    dut.src_payload.value = 0
    dut.test.value = 0

    await FallingEdge(clk)
    dut.n_rst.value = 1

    dut._log.info("---- Normal Operation ----")
    dut.test.value = 1
    data_array = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
    dut.src_valid.value = 1
    dut.dst_ready.value = 1

    for data in data_array:
        dut.src_payload.value = data
        await FallingEdge(clk)
        assert dut.src_ready.value == 1
        assert dut.dst_valid.value == 1
        assert dut.dst_payload.value == data

    dut._log.info("---- Backpressure ----")
    dut.test.value = 2
    dut.src_valid.value = 1
    dut.dst_ready.value = 0
    dut.src_payload.value = 0xAB

    await FallingEdge(clk)
    assert dut.src_ready.value == 0
    assert dut.dst_valid.value == 1

    # Make sure that buffer holds value by waiting a bit
    dut.src_payload.value = 0x11
    for _ in range(8): await FallingEdge(clk)
    assert dut.src_ready.value == 0
    assert dut.dst_valid.value == 1

    dut._log.info("---- Empty skid buffer ----")
    dut.test.value = 3
    dut.src_valid.value = 1
    dut.dst_ready.value = 1

    await FallingEdge(clk)
    assert dut.src_ready.value == 1
    assert dut.dst_valid.value == 1
    assert dut.dst_payload.value == 0xAB # value should be from buffer

    dut._log.info("---- Continue normal operation ----")
    dut.test.value = 4
    dut.src_valid.value = 1
    dut.dst_ready.value = 1
    data_array = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]

    for data in data_array:
        dut.src_payload.value = data
        await FallingEdge(clk)
        assert dut.src_ready.value == 1
        assert dut.dst_valid.value == 1
        assert dut.dst_payload.value == data

    dut._log.info("---- Reset ----")
    dut.test.value = 5
    dut.n_rst.value = 0
    dut.src_valid.value = 0
    dut.dst_ready.value = 0

    await FallingEdge(clk)
    dut.n_rst.value = 1
    assert dut.src_ready.value == 1
    assert dut.dst_valid.value == 0
    assert dut.dst_payload.value == 0

    dut._log.info("---- Single cycle skid ----")
    dut.test.value = 6
    # Normal cycle
    dut.src_valid.value = 1
    dut.dst_ready.value = 1
    dut.src_payload.value = 0xAB

    await FallingEdge(clk)
    assert dut.src_ready.value == 1
    assert dut.dst_valid.value == 1
    assert dut.dst_payload.value == 0xAB

    # Ready is pulled low
    dut.dst_ready.value = 0
    dut.src_payload.value = 0xBC

    await FallingEdge(clk)
    assert dut.src_ready.value == 0
    assert dut.dst_valid.value == 1
    assert dut.dst_payload.value == 0xAB

    # Restore from skid buffer
    dut.dst_ready.value = 1
    dut.src_payload.value = 0xCD

    await FallingEdge(clk)
    assert dut.src_ready.value == 1
    assert dut.dst_valid.value == 1
    assert dut.dst_payload.value == 0xBC
    
    await FallingEdge(clk)
    assert dut.src_ready.value == 1
    assert dut.dst_valid.value == 1
    assert dut.dst_payload.value == 0xCD