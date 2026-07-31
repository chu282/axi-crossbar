import cocotb
import random
import logging
import warnings

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiResp

warnings.filterwarnings("ignore", category=DeprecationWarning)

log = logging.getLogger(f"cocotb.{__name__}")
log.setLevel(logging.INFO)

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_dma_csr(dut):
    logging.getLogger(f"cocotb.{dut._name}").setLevel(logging.WARNING)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    n_rst = dut.n_rst
    clk = dut.clk
    test = dut.test

    m_bus = AxiBus.from_prefix(dut, "")
    m = AxiMaster(m_bus, clk, n_rst, reset_active_level=False)
    
    dut.n_rst.value = 0
    await FallingEdge(dut.clk)
    dut.n_rst.value = 1
    await FallingEdge(dut.clk)

    log.info("---- Simple write operation ----")
    test.value = 1
    addrs = [0x0, 0x4, 0x8, 0xC]
    data = [random.randbytes(i) for i in [4, 4, 4, 1]]
    sizes = [2, 2, 2, 0]
    for i in range(4):
        addr = addrs[i]
        val = data[i]
        size = sizes[i]
        resp = await m.write(addr, val, size=size)
        assert resp.resp == AxiResp.OKAY

    log.info("---- Simple read operation ----")
    log.info("---- Invalid operation ----")
    log.info("---- Randomized operation ----")