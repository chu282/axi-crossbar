import cocotb
import random

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.n_rst = dut.n_rst

        # Start clock
        cocotb.start_soon(Clock(self.clk, 10, "ns").start())

        # Reset
        self.reset()

        # Buses
        m0_bus = AxiBus.from_prefix(dut, "m0")
        m1_bus = AxiBus.from_prefix(dut, "m1")

        s0_bus = AxiBus.from_prefix(dut, "s0")
        s1_bus = AxiBus.from_prefix(dut, "s1")

        # Instantiate masters
        self.m0 = AxiMaster(m0_bus, self.clk, self.n_rst, reset_active_level=False)
        self.m1 = AxiMaster(m1_bus, self.clk, self.n_rst, reset_active_level=False)

        # Instantiate slaves
        self.s0 = AxiRam(s0_bus, self.clk, self.n_rst, size=2**32)
        self.s1 = AxiRam(s1_bus, self.clk, self.n_rst, size=2**32)

    async def reset(self):
        self.n_rst.value = 0
        await FallingEdge(self.clk)
        self.n_rst.value = 1
        await FallingEdge(self.clk)

@cocotb.test()
async def test_single_transaction(dut):
    NUM_TESTS = 1000

    tb = TB(dut)

    addrs = []
    sizes = []
    data = []
    # generate random parameters
    for idx in range(NUM_TESTS):
        size = random.randint(0, 2)
        size_bytes = 2 ** size
        addr = size_bytes * random.randint(0, 2**32 // size_bytes - 1)
        datum = random.getrandbits(size_bytes * 8)

        sizes.append(size)
        addrs.append(addr)
        data.append(datum)

    for i in range(NUM_TESTS):
        tb.s0.write(0, 0xABCD)

        await tb.m0.write(addrs[i], data[i], size=sizes[i])
        assert tb.s0.read(0, 2*32) == 0xABCD