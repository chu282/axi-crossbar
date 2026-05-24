import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_axi_fifo(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    clk = dut.clk
    
    dut.push.value = 0
    dut.pop.value = 0
    dut["in"].value = 0

    dut.n_rst.value = 0
    await FallingEdge(clk)
    dut.n_rst.value = 1

    vals = [0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8]

    assert dut.empty.value == 1
    assert dut.full.value == 0
    assert dut.out.value == 0
    await FallingEdge(clk)

    # Fill
    dut.push.value = 1
    for val in vals:
        dut["in"].value = val
        await FallingEdge(clk)
        assert dut.empty.value == 0
        assert dut.full.value == (1 if val == vals[-1] else 0)
        assert dut.out.value == vals[0]
    dut.push.value = 0

    dut.pop.value = 1
    for val in vals:
        assert dut.out.value == val
        await FallingEdge(clk)
        assert dut.empty.value == (1 if val == vals[-1] else 0)
        assert dut.full.value == 0
    dut.pop.value = 0