import cocotb
import warnings
import logging

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiRam, AxiResp

warnings.filterwarnings("ignore", category=DeprecationWarning)

log = logging.getLogger(f"cocotb.{__name__}")
log.setLevel(logging.INFO)

IDLE = 0
TRANS = 1
DONE = 2
ERR = 3

@cocotb.test(timeout_time=1, timeout_unit="us")
async def test_dma_engine(dut):
    logging.getLogger(f"cocotb.{dut._name}").setLevel(logging.WARNING)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    n_rst = dut.n_rst
    clk = dut.clk
    test = dut.test

    start = dut.start
    ack_done = dut.ack_done
    ack_err = dut.ack_err
    length = dut.length
    from_addr = dut.from_addr
    to_addr = dut.to_addr
    status = dut.status

    s_bus = AxiBus.from_prefix(dut, "")
    s = AxiRam(s_bus, clk, n_rst, reset_active_level=False, size=4096)

    dut.n_rst.value = 0
    await FallingEdge(dut.clk)
    dut.n_rst.value = 1

    log.info("---- Simple directed operation ----")
    test.value = 1

    s.write(0x0, 0xABAB_CDCD.to_bytes(4, "little"))

    start.value = 1
    length.value = 4
    from_addr.value = 0x0
    to_addr.value = 0x100

    await FallingEdge(clk)
    start.value = 0

    while status.value != DONE: await FallingEdge(clk)
    assert int.from_bytes(s.read(0x100, 4), 'little') == 0xABAB_CDCD