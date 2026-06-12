import cocotb
import random
import logging
import warnings

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiResp
from cocotbext.axi.axi_master import AxiReadResp

ADDR_WIDTH = 32
ID_WIDTH = 4
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

def get_rand_parameters(NUM_TESTS, MAX_ADDR=0x8FFF_FFFF):
    addrs = []
    lengths = []
    data = []
    sizes = []
    ids = []

    for _ in range(NUM_TESTS):
        size = random.choice([0, 1, 2]) # bytes in beat = size^2
        length = (2**size) * random.randint(1, 16) # number of bytes
        addr = length * random.randint(0, MAX_ADDR // length - 1)
        val = random.randbytes(length)
        id_ = random.randint(0, ID_WIDTH - 1)

        lengths.append(length)
        addrs.append(addr)
        data.append(val)
        sizes.append(size)
        ids.append(id_)

    return addrs, lengths, data, sizes, ids

def stall_generator(probability=0.5):
    while True:
        yield random.random() < probability

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
    NUM_TESTS = 2000

    tb = TB(dut)
    await tb.reset()

    s0_addrs, lengths, s0_data, sizes = get_rand_parameters(NUM_TESTS, 0x7FFF_FFFF)
    s1_addrs, _, _, _ = get_rand_parameters(NUM_TESTS, 0x0FFF_FFFF)
    s1_addrs = [addr + 0x8000_0000 for addr in s1_addrs]
    s1_data = [random.randbytes(length) for length in lengths]

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
    NUM_TESTS = 2000

    tb = TB(dut)
    await tb.reset()

    s0_addrs, lengths, s0_data, sizes = get_rand_parameters(NUM_TESTS, 0x8000_0000)
    s1_addrs, _, _, _ = get_rand_parameters(NUM_TESTS, 0x1000_0000)
    s1_addrs = [addr + 0x8000_0000 for addr in s1_addrs]
    s1_data = [random.randbytes(length) for length in lengths]

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

@cocotb.test()
async def test_decerr(dut):
    NUM_TESTS = 1000

    tb = TB(dut)
    await tb.reset()

    _, lengths, data, sizes = get_rand_parameters(NUM_TESTS)
    
    addrs = []
    for _ in range(NUM_TESTS):
        addrs.append(0x1000 * random.randint(0x8_0000 - 0x2, 0x8_0000 + 0x2)) # test boundary between slaves

    for i in range(NUM_TESTS):
        events = []
        
        addr = addrs[i]
        length = lengths[i]
        size = sizes[i]
        val = data[i]

        for m in tb.masters:
            resp = await m.read(addr, length, size=size)
            assert resp.resp == AxiResp.OKAY
            
    addrs = []
    for _ in range(NUM_TESTS):
        addrs.append(0x1000 * random.randint(0x9_0000, 0xF_FFFF)) # test boundary
    
    for i in range(NUM_TESTS):
        events = []
        
        addr = addrs[i]
        length = lengths[i]
        size = sizes[i]
        val = data[i]

        for m in tb.masters:
            resp = await m.read(addr, length, size=size)
            assert resp.resp == AxiResp.DECERR
    
@cocotb.test()
async def test_random_transactions(dut):
    NUM_TESTS = 1000

    tb = TB(dut)
    await tb.reset()

    m0_addrs_w, m0_lengths_w, m0_data_w, m0_sizes_w, m0_ids_w = get_rand_parameters(NUM_TESTS, MAX_ADDR=0xFFFF_FFFF)
    m0_addrs_r, m0_lengths_r, m0_data_r, m0_sizes_r, m0_ids_r = get_rand_parameters(NUM_TESTS, MAX_ADDR=0xFFFF_FFFF)
    m1_addrs_w, m1_lengths_w, m1_data_w, m1_sizes_w, m1_ids_w = get_rand_parameters(NUM_TESTS, MAX_ADDR=0xFFFF_FFFF)
    m1_addrs_r, m1_lengths_r, m1_data_r, m1_sizes_r, m1_ids_r = get_rand_parameters(NUM_TESTS, MAX_ADDR=0xFFFF_FFFF)

    for i in range(NUM_TESTS):
        m0_w_addr = m0_addrs_w[i]
        m0_w_len = m0_lengths_w[i]
        m0_w_size = m0_sizes_w[i]
        m0_w_val = m0_data_w[i]
        m0_w_id = m0_ids_w[i]

        m0_r_addr = m0_addrs_r[i]
        m0_r_len = m0_lengths_r[i]
        m0_r_size = m0_sizes_r[i]
        m0_r_val = m0_data_r[i]
        m0_r_id = m0_ids_r[i]

        m1_w_addr = m1_addrs_w[i]
        m1_w_len = m1_lengths_w[i]
        m1_w_size = m1_sizes_w[i]
        m1_w_val = m1_data_w[i]
        m1_w_id = m1_ids_w[i]

        m1_r_addr = m1_addrs_r[i]
        m1_r_len = m1_lengths_r[i]
        m1_r_size = m1_sizes_r[i]
        m1_r_val = m1_data_r[i]
        m1_r_id = m1_ids_r[i]

        # ensure reads/writes dont overlap
        while abs(m0_r_addr - m0_w_addr) < 0x1000 or abs(m0_r_addr - m1_w_addr) < 0x1000:
            m0_r_addr = (m0_r_addr + 0x1000) & 0x8FFF_FFFF

        while abs(m1_r_addr - m1_w_addr) < 0x1000 or abs(m1_r_addr - m0_w_addr) < 0x1000:
            m1_r_addr = (m1_r_addr + 0x1000) & 0x8FFF_FFFF

        # backdoor write to initialize read locations with expected data
        if m0_r_addr < 0x8000_0000:
            tb.s0.write(m0_r_addr, m0_r_val)
        else:
            tb.s1.write(m0_r_addr, m0_r_val)

        if m1_r_addr < 0x8000_0000:
            tb.s0.write(m1_r_addr, m1_r_val)
        else:
            tb.s1.write(m1_r_addr, m1_r_val)

        # random/valid stalls
        for device in tb.masters + tb.slaves:
            device.write_if.aw_channel.set_pause_generator(stall_generator())
            device.write_if.w_channel.set_pause_generator(stall_generator())
            device.write_if.b_channel.set_pause_generator(stall_generator())
            device.read_if.ar_channel.set_pause_generator(stall_generator())
            device.read_if.r_channel.set_pause_generator(stall_generator())

        # queue and execute transactions
        events = []
        resps = []

        for _ in range(9):
            events.append(tb.m0.init_write(m0_w_addr, m0_w_val, size=m0_w_size, awid=m0_w_id))
            events.append(tb.m1.init_write(m1_w_addr, m1_w_val, size=m1_w_size, awid=m1_w_id))
            events.append(tb.m0.init_read(m0_r_addr, m0_r_len, size=m0_r_size, arid=m0_r_id))
            events.append(tb.m1.init_read(m1_r_addr, m1_r_len, size=m1_r_size, arid=m1_r_id))

        for event in events:
            await event.wait()
            resps.append(event.data)

        # backdoor read verification for writes
        if m0_w_addr < 0x8000_0000:
            assert tb.s0.read(m0_w_addr, m0_w_len) == m0_w_val
        elif m0_w_addr < 0x9000_0000:
            assert tb.s1.read(m0_w_addr, m0_w_len) == m0_w_val

        if m1_w_addr < 0x8000_0000:
            assert tb.s0.read(m1_w_addr, m1_w_len) == m1_w_val
        elif m1_w_addr < 0x9000_0000:
            assert tb.s1.read(m1_w_addr, m1_w_len) == m1_w_val

        for resp in resps:
            assert resp.resp == (AxiResp.OKAY if resp.address < 0x9000_0000 else AxiResp.DECERR)

            if isinstance(resp, AxiReadResp) and resp.resp == AxiResp.OKAY:
                assert resp.data == (m0_r_val if resp.address == m0_r_addr else m1_r_val)