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

IDLE = 0
BUSY = 1
ERR = 2

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_dma_csr(dut):
    logging.getLogger(f"cocotb.{dut._name}").setLevel(logging.WARNING)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    n_rst = dut.n_rst
    clk = dut.clk
    test = dut.test
    
    status = dut.status
    from_addr = dut.from_addr
    to_addr = dut.to_addr
    length = dut.length
    start = dut.start

    status.value = 0

    m_bus = AxiBus.from_prefix(dut, "")
    m = AxiMaster(m_bus, clk, n_rst, reset_active_level=False)

    dut.n_rst.value = 0
    await FallingEdge(dut.clk)
    dut.n_rst.value = 1

    log.info("---- Simple write operation ----")
    test.value = 1
    addrs = [0x0, 0x4, 0x8, 0xC, 0xC, 0xC, 0xC]
    data = [random.randbytes(i) for i in [4, 4, 4]]
    data.extend(bytes([i]) for i in range(4))
    sizes = [2, 2, 2, 0, 0, 0, 0]
    for i in range(7):
        addr = addrs[i]
        val = data[i]
        size = sizes[i]
        resp = await m.write(addr, val, size=size)

        assert resp.resp == AxiResp.OKAY
        match addr:
            case 0x0: assert from_addr.value == int.from_bytes(val, "little")
            case 0x4: assert to_addr.value == int.from_bytes(val, "little")
            case 0x8: assert length.value == int.from_bytes(val, "little")

    log.info("---- Simple read operation ----")
    test.value = 2
    for status_val in [IDLE, BUSY, ERR]:
        status.value = status_val
        resp = await m.read(0x10, 1)
        assert resp.data == bytes([status_val])
        assert resp.resp == AxiResp.OKAY
    status.value = IDLE

    log.info("---- Invalid operation ----")
    test.value = 3
    NUM_TESTS = 1000
    # write errors
    for i in range(NUM_TESTS):
        addr = random.randrange(0x10, 0x100, 4)
        val = random.randbytes(random.randint(1, 4))
        resp = await m.write(addr, val)
        assert resp.resp == AxiResp.SLVERR

    # read errors
    for addr in range(0x10):
        resp = await m.read(addr, 1)
        assert resp.resp == AxiResp.SLVERR

    for i in range(NUM_TESTS):
        addr = random.randrange(0x11, 0x100, 4)
        resp = await m.read(addr, 1)
        assert resp.resp == AxiResp.SLVERR

    log.info("---- Randomized operation ----")
    test.value = 4
    NUM_TESTS = 5000

    n_rst.value = 0
    await FallingEdge(clk)
    n_rst.value = 1

    exp_from_addr = 0
    exp_to_addr = 0
    exp_length = 0
    exp_start = 0

    for i in range(NUM_TESTS):
        addr = random.randrange(0, 0x100, 4)
        write = random.randint(0, 1)
        if write: val = random.randbytes(4)

        if write:
            exp_start = int.from_bytes(val, "little") & 1
            exp_ack_done = (int.from_bytes(val, "little") >> 2) & 1
            exp_ack_err = (int.from_bytes(val, "little") >> 3) & 1
            if addr == 0xC: cocotb.start_soon(check_pulses(dut, exp_start, exp_ack_done, exp_ack_err))
            resp = await m.write(addr, val)
            exp_resp = AxiResp.SLVERR if addr >= 0x10 else AxiResp.OKAY

            # update exp vals
            match addr:
                case 0x0: exp_from_addr = int.from_bytes(val, "little")
                case 0x4: exp_to_addr = int.from_bytes(val, "little")
                case 0x8: exp_length = int.from_bytes(val, "little")
        else:
            resp = await m.read(addr, 1)
            exp_resp = AxiResp.SLVERR if addr != 0x10 else AxiResp.OKAY

        # breakpoint()
        assert resp.resp == exp_resp
        assert from_addr.value == exp_from_addr
        assert to_addr.value == exp_to_addr
        assert length.value == exp_length

async def check_pulses(dut, exp_start, exp_ack_done, exp_ack_err):
    # wait until a cycle after write finishes
    while not dut.wvalid.value or not dut.wready.value: await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)

    assert dut.start.value == exp_start
    assert dut.ack_done.value == exp_ack_done
    assert dut.ack_err.value == exp_ack_err

    # ensure one cycle pulses
    await FallingEdge(dut.clk)
    assert dut.start.value == 0
    assert dut.ack_done.value == 0
    assert dut.ack_err.value == 0