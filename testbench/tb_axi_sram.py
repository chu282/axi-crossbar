import cocotb
import random
import logging
import warnings
import math

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiResp

warnings.filterwarnings("ignore", category=DeprecationWarning)

log = logging.getLogger(f"cocotb.{__name__}")
log.setLevel(logging.INFO)

NUM_TESTS = 2000

@cocotb.test()
async def test_axi_sram(dut):
    logging.getLogger(f"cocotb.{dut._name}").setLevel(logging.WARNING)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    clk = dut.clk
    n_rst = dut.n_rst
    test = dut.test
    
    m_bus = AxiBus.from_prefix(dut, "")
    m = AxiMaster(m_bus, dut.clk, reset=dut.n_rst, reset_active_level=False)

    dut.n_rst.value = 0
    await FallingEdge(dut.clk)
    dut.n_rst.value = 1
    await FallingEdge(dut.clk)

    log.info("---- Simple write operation ----")
    dut.test.value = 1
    data = [0xAA, 0xBB, 0xCC, 0xDD]
    addrs = [0x00, 0x10, 0x20, 0x30]
    for i in range(4):
        val = bytes([data[i]])
        addr = addrs[i]

        await m.write(addr, val)
        read_data = await m.read(addr, 1)
        
        assert read_data.data == val
    
    log.info("---- Burst write and read operation ----")
    test.value = 2
    for i in range(10):
        num_bytes = random.randint(1, 10)
        addr = random.randint(0x00, 0xFF)
        val = random.randbytes(num_bytes)
        size = random.randint(0, 2)

        await m.write(addr, val, size=size)
        read_data = await m.read(addr, num_bytes, size=size)

    # random values
    for i in range(NUM_TESTS):
        addr = random.randint(0x0000, 0x0FFF)
        num_bytes = random.randint(1, 4096 - addr)
        size = random.randint(0, 2)
        val = random.randbytes(num_bytes)

        response = random.choice([await m.write(addr, val, size=size), await m.read(addr, num_bytes, size=size)])
        assert response.resp == AxiResp.OKAY

    log.info("---- Randomized operation ----")
    test.value = 3
    sram_model = bytearray(4096)

    # set the entire memory array to 0
    await m.write(0, bytes(4096))

    for i in range(NUM_TESTS):
        addr = random.randint(0x0000, 0x0FFF)
        num_bytes = random.randint(1, 4096 - addr)
        val = random.randbytes(num_bytes)
        write = random.randint(0, 1)
        size = random.randint(0, 2)

        # update reference sram model
        if write: sram_model[addr:addr+num_bytes] = val

        response = await m.write(addr, val, size=size) if write else await m.read(addr, num_bytes, size=size)
        if not write:
            assert response.data == sram_model[addr:addr+num_bytes]
        assert response.resp == AxiResp.OKAY