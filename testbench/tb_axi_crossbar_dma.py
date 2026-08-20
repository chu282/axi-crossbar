import cocotb
import random
import logging
import warnings

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiResp

ADDR_WIDTH = 32
DATA_WIDTH = 32
ID_WIDTH = 4

# DMA CSR
CSR_BASE_ADDR = 0x8000_0000
FROM_ADDR_REG = CSR_BASE_ADDR + 0x0
TO_ADDR_REG = CSR_BASE_ADDR + 0x4
LENGTH_REG = CSR_BASE_ADDR + 0x8
CONTROL_REG = CSR_BASE_ADDR + 0xC
STATUS_REG = CSR_BASE_ADDR + 0x10

IDLE = 0
BUSY = 1
DONE = 2
ERR = 3

START = 1 << 0
ACK_DONE = 1 << 1
ACK_ERR  = 1 << 2

warnings.filterwarnings("ignore", category=DeprecationWarning)

log = logging.getLogger(f"cocotb.{__name__}")
log.setLevel(logging.INFO)

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.n_rst = dut.n_rst

        # Start clock
        cocotb.start_soon(Clock(self.clk, 10, "ns").start())

        # Buses
        cpu_bus = AxiBus.from_prefix(dut, "m0")

        # Instantiate CPU
        self.cpu = AxiMaster(cpu_bus, self.clk, self.n_rst, reset_active_level=False)

        # Silence cocotbext-axi logging
        logging.getLogger(f"cocotb.{dut._name}").setLevel(logging.WARNING)
        logging.getLogger(f"cocotb.{dut._name}.m0").setLevel(logging.WARNING)

    async def reset(self):
        self.n_rst.value = 0
        await FallingEdge(self.clk)
        self.n_rst.value = 1
        await FallingEdge(self.clk)

    def set_stalls(self, probability=0.2):
        self.cpu.write_if.aw_channel.set_pause_generator(stall_generator(probability))
        self.cpu.write_if.w_channel.set_pause_generator(stall_generator(probability))
        self.cpu.write_if.b_channel.set_pause_generator(stall_generator(probability))
        self.cpu.read_if.ar_channel.set_pause_generator(stall_generator(probability))
        self.cpu.read_if.r_channel.set_pause_generator(stall_generator(probability))

    def clear_stalls(self):
        self.set_stalls(probability=0.0)

def overlaps_source(guard_addr, guard_len, from_addr, length):
    if guard_len == 0 or length == 0:
        return False
    return not (guard_addr + guard_len <= from_addr or guard_addr >= from_addr + length)

async def write_guard_data(tb, from_addr, to_addr, length):
    lower_guard_length = min(4, to_addr)
    lower_guard_addr = to_addr - lower_guard_length
    lower_guard_data = b"\xde\xad\xbe\xef"[:lower_guard_length]

    upper_guard_length = min(4, 4096 - (to_addr + length))
    upper_guard_addr = to_addr + length
    upper_guard_data = b"\xbe\xef\xde\xad"[:upper_guard_length]

    lower_guard_valid = (lower_guard_length > 0) and not overlaps_source(lower_guard_addr, lower_guard_length, from_addr, length)
    upper_guard_valid = (upper_guard_length > 0) and not overlaps_source(upper_guard_addr, upper_guard_length, from_addr, length)

    if lower_guard_valid: await tb.cpu.write(lower_guard_addr, lower_guard_data)
    if upper_guard_valid: await tb.cpu.write(upper_guard_addr, upper_guard_data)

    return (lower_guard_valid, lower_guard_addr, lower_guard_length, lower_guard_data,
            upper_guard_valid, upper_guard_addr, upper_guard_length, upper_guard_data)

async def check_guard_data(tb, guard_info):
    (lower_guard_valid, lower_guard_addr, lower_guard_length, lower_guard_data,
     upper_guard_valid, upper_guard_addr, upper_guard_length, upper_guard_data) = guard_info

    if lower_guard_valid:
        r_lower = await tb.cpu.read(lower_guard_addr, lower_guard_length)
        assert r_lower.data == lower_guard_data
    if upper_guard_valid:
        r_upper = await tb.cpu.read(upper_guard_addr, upper_guard_length)
        assert r_upper.data == upper_guard_data

def stall_generator(probability=0.5):
    while True:
        yield random.random() < probability

async def poll_status(tb):
    while True:
        resp = await tb.cpu.read(STATUS_REG, 4)
        status = int.from_bytes(resp.data, "little")
        if status == DONE or status == ERR:
            return status
        await FallingEdge(tb.dut.clk)

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_sram_write(dut):
    dut._log.info("---- Testing CPU-SRAM direct write and read ----")

    tb = TB(dut)
    await tb.reset()
    tb.dut.test.value = 2

    NUM_TESTS = 200
    
    for i in range(NUM_TESTS):
        if i == NUM_TESTS // 2:
            tb.set_stalls(0.2)

        length = random.randint(1, 512)
        addr = random.randint(0, 0x7FFF_FFFF - length)
        data = random.randbytes(length)

        w_resp = await tb.cpu.write(addr, data)
        r_resp = await tb.cpu.read(addr, length)

        assert w_resp.resp == AxiResp.OKAY
        assert r_resp.resp == AxiResp.OKAY
        assert r_resp.data == data

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_directed_transfer(dut):
    dut._log.info("---- Directed normal transfer test ----")

    tb = TB(dut)
    await tb.reset()
    tb.dut.test.value = 2

    cases = [
        {"name": "1-byte transfer",              "from_addr": 0x000, "to_addr": 0x001, "length": 0x1},
        {"name": "2-byte transfer",              "from_addr": 0x000, "to_addr": 0x002, "length": 0x2},
        {"name": "4-byte transfer",              "from_addr": 0x000, "to_addr": 0x004, "length": 0x4},
        {"name": "1-byte unaligned transfer",    "from_addr": 0x001, "to_addr": 0x103, "length": 0x1},
        {"name": "4-byte unaligned transfer",    "from_addr": 0x002, "to_addr": 0x107, "length": 0x4},
        {"name": "256-byte transfer",            "from_addr": 0x000, "to_addr": 0x200, "length": 0x100},
        {"name": "256-byte unaligned transfer",  "from_addr": 0x001, "to_addr": 0x202, "length": 0x100},
        {"name": "512-byte transfer",            "from_addr": 0x000, "to_addr": 0x400, "length": 0x200},
        {"name": "513-byte unaligned transfer",  "from_addr": 0x001, "to_addr": 0x403, "length": 0x201},
        {"name": "1024-byte transfer",           "from_addr": 0x000, "to_addr": 0x800, "length": 0x400},
        {"name": "Unaligned 1021-byte transfer", "from_addr": 0x003, "to_addr": 0x801, "length": 0x3FD}
    ]

    for stall in [0, 1]:
        if stall == 1:
            tb.set_stalls(0.5)
        else:
            tb.clear_stalls()

        for case in cases:
            from_addr = case["from_addr"]
            to_addr = case["to_addr"]
            length = case["length"]
            data = random.randbytes(length)
            log.info(case["name"])

            # write source data to SRAM
            await tb.cpu.write(from_addr, data)

            # write guard data around destination buffer
            guard_info = await write_guard_data(tb, from_addr, to_addr, length)

            # write parameters into DMA csr
            await tb.cpu.write(FROM_ADDR_REG, int.to_bytes(from_addr, 4, "little"))
            await tb.cpu.write(TO_ADDR_REG,   int.to_bytes(to_addr, 4, "little"))
            await tb.cpu.write(LENGTH_REG,    int.to_bytes(length, 4, "little"))

            # start DMA transfer
            await tb.cpu.write(CONTROL_REG, int.to_bytes(START, 4, "little"))

            # poll until done
            status = await poll_status(tb)
            assert status == DONE

            # assert destination data is correct
            r_resp = await tb.cpu.read(to_addr, length)
            assert r_resp.resp == AxiResp.OKAY
            assert r_resp.data == data

            # assert guard data remained intact
            await check_guard_data(tb, guard_info)

            # acknowledge done and return to IDLE
            await tb.cpu.write(CONTROL_REG, int.to_bytes(ACK_DONE, 4, "little"))
            resp = await tb.cpu.read(STATUS_REG, 4)
            assert (int.from_bytes(resp.data, "little")) == IDLE

@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_error_generation(dut):
    dut._log.info("---- Error generation test ----")

    tb = TB(dut)
    await tb.reset()
    tb.dut.test.value = 3

    cases = [
        {"name": "Out of bounds to_addr error",   "from_addr": 0x001, "to_addr": 0x1000, "length": 0x100},
        {"name": "Out of bounds from_addr error", "from_addr": 0x1001, "to_addr": 0x002, "length": 0x2},
        {"name": "Same address error",            "from_addr": 0x010, "to_addr": 0x010, "length": 0x010},
        {"name": "Overlapping error (from_addr < to_addr)", "from_addr": 0x001, "to_addr": 0x103, "length": 0x200},
        {"name": "Overlapping error (from_addr > to_addr)", "from_addr": 0x080, "to_addr": 0x010, "length": 0x120},
        {"name": "0 length burst", "from_addr": 0x080, "to_addr": 0x010, "length": 0x0},
    ]

# @cocotb.test(timeout_time=1, timeout_unit="ms")
# async def test_random_transfer(dut):
#     dut._log.info("---- Constrained random transfer ----")

#     tb = TB(dut)
#     await tb.reset()

#     NUM_TESTS = 200
#     for i in range(NUM_TESTS):
#         if i == NUM_TESTS // 2:
#             tb.set_stalls(0.2)

#         from_addr = random.randint(0, 0x7FFF_FFFF)
#         to_addr = random.randint(0, 0x7FFF_FFFF)
#         length = random.randint(1, 1024)

#         # write random data into SRAM
#         data = random.randbytes(length)
#         await tb.cpu.write(to_addr, data)

#         w_resp1 = await tb.cpu.write(FROM_ADDR_REG, from_addr)
#         w_resp2 = await tb.cpu.write(TO_ADDR_REG, to_addr)
#         w_resp3 = await tb.cpu.write(LENGTH_REG, length)

#         r_resp1 = await tb.cpu.read(FROM_ADDR_REG, 4)
#         r_resp2 = await tb.cpu.read(TO_ADDR_REG, 4)
#         r_resp3 = await tb.cpu.read(LENGTH_REG, 4)

#         assert w_resp1.resp == AxiResp.OKAY
#         assert w_resp2.resp == AxiResp.OKAY
#         assert w_resp3.resp == AxiResp.OKAY
#         assert r_resp1.resp == AxiResp.OKAY
#         assert r_resp2.resp == AxiResp.OKAY
#         assert r_resp3.resp == AxiResp.OKAY
#         assert r_resp1.data == int.to_bytes(from_addr, 4, "little")
#         assert r_resp2.data == int.to_bytes(to_addr, 4, "little")
#         assert r_resp3.data == int.to_bytes(length, 4, "little")

# @cocotb.test()
# async def test_cpu_csr_access(dut):
#     """Verify CPU can read and write DMA CSR registers."""
#     tb = TB(dut)
#     await tb.reset()

#     log.info("---- Testing CPU read/write to DMA CSR registers ----")

#     # Write CSR parameters
#     await tb.cpu.write(REG_FROM_ADDR, int.to_bytes(0x0000_1234, 4, "little"))
#     await tb.cpu.write(REG_TO_ADDR,   int.to_bytes(0x0000_5678, 4, "little"))
#     await tb.cpu.write(REG_LENGTH,    int.to_bytes(256, 4, "little"))

#     # Read back and verify
#     read_from   = await tb.cpu.read(REG_FROM_ADDR, 4)
#     read_to     = await tb.cpu.read(REG_TO_ADDR, 4)
#     read_length = await tb.cpu.read(REG_LENGTH, 4)
#     read_status = await tb.cpu.read(REG_STATUS, 4)

#     assert int.from_bytes(read_from.data, "little") == 0x0000_1234
#     assert int.from_bytes(read_to.data, "little") == 0x0000_5678
#     assert int.from_bytes(read_length.data, "little") == 256
#     assert (int.from_bytes(read_status.data, "little") & 0x3) == STATUS_IDLE

# @cocotb.test()
# async def test_dma_transfer(dut):
#     """Verify full end-to-end CPU-initiated DMA transfer in SRAM through Crossbar."""
#     tb = TB(dut)
#     await tb.reset()

#     log.info("---- Testing end-to-end DMA transfer in SRAM ----")

#     from_addr = 0x0000_1000
#     to_addr   = 0x0000_4000
#     length    = 64
#     test_data = random.randbytes(length)

#     # 1. CPU initializes source data in SRAM
#     await tb.cpu.write(from_addr, test_data)

#     # 2. CPU configures DMA CSR
#     await tb.cpu.write(REG_FROM_ADDR, int.to_bytes(from_addr, 4, "little"))
#     await tb.cpu.write(REG_TO_ADDR,   int.to_bytes(to_addr, 4, "little"))
#     await tb.cpu.write(REG_LENGTH,    int.to_bytes(length, 4, "little"))

#     # 3. CPU triggers DMA start
#     await tb.cpu.write(REG_STATUS, int.to_bytes(CTRL_START, 4, "little"))

#     # 4. CPU polls DMA status until DONE
#     while True:
#         resp = await tb.cpu.read(REG_STATUS, 4)
#         status = int.from_bytes(resp.data, "little") & 0x3
#         if status == STATUS_DONE:
#             break
#         await FallingEdge(tb.clk)

#     # 5. Verify transferred data in SRAM
#     assert tb.sram.read(to_addr, length) == test_data

#     # 6. CPU acknowledges DONE
#     await tb.cpu.write(REG_STATUS, int.to_bytes(CTRL_ACK_DONE, 4, "little"))
#     resp = await tb.cpu.read(REG_STATUS, 4)
#     assert (int.from_bytes(resp.data, "little") & 0x3) == STATUS_IDLE
