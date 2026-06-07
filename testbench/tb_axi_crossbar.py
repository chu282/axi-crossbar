import cocotb
import random
import logging
import warnings

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam

ADDR_WIDTH = 32
NUM_MASTERS = 2
NUM_SLAVES = 2

logging.getLogger("cocotb").setLevel(logging.INFO)
warnings.filterwarnings("ignore", category=DeprecationWarning)

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.n_rst = dut.n_rst

        # Start clock
        cocotb.start_soon(Clock(self.clk, 10, "ns").start())

        # Buses
        m0_bus = AxiBus.from_prefix(dut, "m0")
        m1_bus = AxiBus.from_prefix(dut, "m1")

        s0_bus = AxiBus.from_prefix(dut, "s0")
        s1_bus = AxiBus.from_prefix(dut, "s1")

        # Instantiate masters
        self.m0 = AxiMaster(m0_bus, self.clk, self.n_rst, reset_active_level=False)
        self.m1 = AxiMaster(m1_bus, self.clk, self.n_rst, reset_active_level=False)
        self.masters = [self.m0, self.m1]

        # Instantiate slaves
        self.s0 = AxiRam(s0_bus, self.clk, self.n_rst, size=2**ADDR_WIDTH, reset_active_level=False)
        self.s1 = AxiRam(s1_bus, self.clk, self.n_rst, size=2**ADDR_WIDTH, reset_active_level=False)
        self.slaves = [self.s0, self.s1]

        # Silence cocotbext-axi logging
        logging.getLogger(f"cocotb.{dut._name}.m0").setLevel(logging.WARNING)
        logging.getLogger(f"cocotb.{dut._name}.m1").setLevel(logging.WARNING)
        logging.getLogger(f"cocotb.{dut._name}.s0").setLevel(logging.WARNING)
        logging.getLogger(f"cocotb.{dut._name}.s1").setLevel(logging.WARNING)

    async def reset(self):
        self.n_rst.value = 0
        await FallingEdge(self.clk)
        self.n_rst.value = 1
        await FallingEdge(self.clk)

def get_rand_parameters(NUM_TESTS):
    addrs = []
    lengths = []
    data = []
    sizes = []

    for _ in range(NUM_TESTS):
        size = random.choice([0, 1, 2]) # bytes in beat = size^2
        length = (2**size) * random.randint(1, 16) # number of bytes
        addr = length * random.randint(0, 2**ADDR_WIDTH // length - 1)
        val = random.randbytes(length)

        lengths.append(length)
        addrs.append(addr)
        data.append(val)
        sizes.append(size)

    return addrs, lengths, data, sizes

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_single_write(dut):
    NUM_TESTS = 1000

    tb = TB(dut)
    await tb.reset()

    addrs, lengths, data, sizes = get_rand_parameters(NUM_TESTS)

    # write tests
    dut._log.info("---- Single transaction write tests ----")
    for m in tb.masters:
        for i in range(NUM_TESTS):
            addr = addrs[i]
            val = data[i]
            length = lengths[i]
            size = sizes[i]

            tb.s0.write(addr, b'\xaa' * length)
            tb.s1.write(addr, b'\xbb' * length)

            await m.write(addr, val, size=size)

            if addr < 0x8000_0000: # slave 0
                assert tb.s0.read(addr, length) == val
                assert tb.s1.read(addr, length) == b'\xbb' * length
            else: # slave 1
                assert tb.s0.read(addr, length) == b'\xaa' * length
                assert tb.s1.read(addr, length) == val

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_single_read(dut):
    NUM_TESTS = 1000

    tb = TB(dut)
    await tb.reset()

    addrs, lengths, data, sizes = get_rand_parameters(NUM_TESTS)

    # read tests
    dut._log.info("---- Single transaction read tests ----")
    for m in tb.masters:
        for i in range(NUM_TESTS):
            addr = addrs[i]
            val = data[i]
            length = lengths[i]
            size = sizes[i]

            tb.s0.write(addr, val)
            tb.s1.write(addr, val)
            
            read_data = await m.read(addr, length, size=size)

            if addr < 0x8000_0000: # slave 0
                assert read_data.data == tb.s0.read(addr, length)
            else: # slave 1
                assert read_data.data == tb.s1.read(addr, length)

@cocotb.test()
async def test_multiple_non_conflicting_transactions(dut):
    NUM_TESTS = 10000

    tb = TB(dut)
    await tb.reset()

    addrs, lengths, s0_data, sizes = get_rand_parameters(NUM_TESTS)
    s1_data = [random.randbytes(length) for length in lengths]

    s0_addrs = [addr // 2 for addr in addrs]
    s1_addrs = [addr // 2 + 0x8000_0000 for addr in addrs]

    slave_addrs = [s0_addrs, s1_addrs]

    dut._log.info("---- Multiple (non-conflicting) transaction tests ----")
    for i in range(NUM_TESTS):
        events = []

        s_val = [s0_data[i], s1_data[i]]
        length = lengths[i]
        size = sizes[i]

        # get random non-conflicting combinations of masters and slaves
        m_indices = list(range(NUM_MASTERS))
        s_indices = list(range(NUM_SLAVES))

        random.shuffle(m_indices)
        random.shuffle(s_indices)

        combinations = list(zip(m_indices, s_indices))

        # queue all transactions for a combination at the same time
        for m_idx, s_idx in combinations:
            addr = slave_addrs[s_idx][i]
            m = tb.masters[m_idx]

            tb.s0.write(addr, b'\xaa' * length)
            tb.s1.write(addr, b'\xbb' * length)

            event = m.init_write(addr, s_val[s_idx], size=size)
            events.append(event)

        # wait for transactions to complete
        for event in events:
            await event.wait()
            
        for m_idx, s_idx in combinations:
            addr = slave_addrs[s_idx][i]
            if s_idx == 0:
                assert tb.s0.read(addr, length) == s_val[0]
            else:
                assert tb.s1.read(addr, length) == s_val[1]

@cocotb.test()
async def test_multiple_conflicting_transactions(dut):
    NUM_TESTS = 10000

    tb = TB(dut)
    await tb.reset()

    addrs, lengths, s0_data, sizes = get_rand_parameters(NUM_TESTS)
    s1_data = [random.randbytes(length) for length in lengths]

    s0_addrs = [addr // 2 for addr in addrs]
    s1_addrs = [addr // 2 + 0x8000_0000 for addr in addrs]

    slave_addrs = [s0_addrs, s1_addrs]

    dut._log.info("---- Multiple (conflicting) transaction tests ----")
    for i in range(NUM_TESTS):
        events = []

        length = lengths[i]
        size = sizes[i]

        for s_idx, s in enumerate(tb.slaves):
            # generate random, different addresses that the masters will write to 
            addr_1 = random.choice(slave_addrs[s_idx])
            addr_2 = random.choice(slave_addrs[s_idx])

            while not((addr_2 < addr_1 and addr_2 + length*8 < addr_1) or (addr_2 > addr_1 + length*8)):
                addr_2 = random.choice(slave_addrs[s_idx])

            val_1 = random.randbytes(length)
            val_2 = random.randbytes(length)

            tx_addrs = [addr_1, addr_2]
            vals = [val_1, val_2]

            s.write(addr_1, val_1)
            s.write(addr_2, val_2)
        
            for m_idx, m in enumerate(tb.masters):
                event = m.init_write(tx_addrs[m_idx], vals[m_idx], size=size)
                events.append(event)
                
            for event in events:
                await event.wait()

            assert s.read(addr_1, length) == val_1
            assert s.read(addr_2, length) == val_2

# @cocotb.test()
# async def test_