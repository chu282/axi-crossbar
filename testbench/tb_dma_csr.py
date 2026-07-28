import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_dma_csr(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    
    dut.n_rst.value = 0
    await FallingEdge(dut.clk)
    dut.n_rst.value = 1
    await FallingEdge(dut.clk)
