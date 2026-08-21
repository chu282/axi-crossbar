import cocotb
import warnings
import logging
import random

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotbext.axi import AxiBus, AxiRam, AxiResp

warnings.filterwarnings("ignore", category=DeprecationWarning)

log = logging.getLogger(f"cocotb.{__name__}")
log.setLevel(logging.INFO)

IDLE = 0
BUSY = 1
DONE = 2
ERR = 3

def calc_exp_err(from_addr, to_addr, length):
    if ((from_addr < to_addr and from_addr + length > to_addr) or
        (from_addr > to_addr and to_addr + length > from_addr) or
        from_addr == to_addr or
        length == 0):
        return 1
    elif (from_addr >= 0x10000 or to_addr >= 0x10000):
        return 1
    else:
        return 0

def overlaps_source(guard_addr, guard_len, from_addr, length):
    if guard_len == 0 or length == 0:
        return False
    return not (guard_addr + guard_len <= from_addr or guard_addr >= from_addr + length)

def stall_generator(probability=0.2):
    while True:
        yield random.random() < probability

async def test_transfer(dut, s, length, from_addr, to_addr, data, exp_err=0, debug=0):
    s.write(from_addr, data)

    # write guard data
    lower_guard_length = min(4, to_addr)
    lower_guard_addr = to_addr - lower_guard_length
    lower_guard_data = b"\xde\xad\xbe\xef"[:lower_guard_length]

    upper_guard_length = min(4, 65536 - (to_addr + length))
    upper_guard_addr = to_addr + length
    upper_guard_data = b"\xbe\xef\xde\xad"[:upper_guard_length]

    lower_guard_valid = (lower_guard_length > 0) and not overlaps_source(lower_guard_addr, lower_guard_length, from_addr, length)
    upper_guard_valid = (upper_guard_length > 0) and not overlaps_source(upper_guard_addr, upper_guard_length, from_addr, length)

    if lower_guard_valid: s.write(lower_guard_addr, lower_guard_data)
    if upper_guard_valid: s.write(upper_guard_addr, upper_guard_data)

    if debug: log.info("Expected: %s", data.hex(" "))

    dut.start.value = 1
    dut.length.value = length
    dut.from_addr.value = from_addr
    dut.to_addr.value = to_addr

    await FallingEdge(dut.clk)
    dut.start.value = 0

    if (not exp_err):
        while dut.status.value != DONE: await FallingEdge(dut.clk)
        if debug: log.info("Received: %s", s.read(to_addr, length).hex(" "))
        assert s.read(to_addr, length) == data

        # assert guard data
        if lower_guard_valid: assert s.read(lower_guard_addr, lower_guard_length) == lower_guard_data
        if upper_guard_valid: assert s.read(upper_guard_addr, upper_guard_length) == upper_guard_data

        dut.ack_done.value = 1
        await FallingEdge(dut.clk)
        dut.ack_done.value = 0
        assert dut.status.value == IDLE
    else:
        while dut.status.value != ERR: await FallingEdge(dut.clk)

        dut.ack_err.value = 1
        await FallingEdge(dut.clk)
        dut.ack_err.value = 0
        assert dut.status.value == IDLE

@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_dma_engine(dut):
    logging.getLogger(f"cocotb.{dut._name}").setLevel(logging.WARNING)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    n_rst = dut.n_rst
    clk = dut.clk
    test = dut.test

    s_bus = AxiBus.from_prefix(dut, "")
    s = AxiRam(s_bus, clk, n_rst, reset_active_level=False, size=65536)

    dut.n_rst.value = 0
    await FallingEdge(dut.clk)
    dut.n_rst.value = 1

    log.info("---- Simple directed tests ----")
    test.value = 1

    # aligned single word transfer
    await test_transfer(dut, s, 4, 0x0, 0x100, int.to_bytes(0xABAB_CDCD, 4, "little"))

    # small byte transfers 
    for from_addr in range(4):
        for to_addr in range(0x100, 0x104):
            for length in range(1, 4):
                await test_transfer(dut, s, length, from_addr, to_addr, random.randbytes(length))

    # aligned multi word transfer
    await test_transfer(dut, s, 16, 0x0, 0x100, random.randbytes(16))

    # aligned multi word transfer (offset)
    await test_transfer(dut, s, 16, 0x1, 0x101, random.randbytes(16))

    # unaligned multi word transfer
    for i in range(4):
        for j in range(4):
            length = random.randint(1, 16)
            await test_transfer(dut, s, length, 0x0 + i, 0x100 + j, random.randbytes(length))

    # aligned > 1024 byte transfer
    await test_transfer(dut, s, 1028, 0x0, 0x2000, random.randbytes(1028))

    # unaligned > 1024 byte transfer
    for i in range(4):
        for j in range(4):
            length = random.randint(1024, 2048)
            await test_transfer(dut, s, length, 0x0 + i, 0x2000 + j, random.randbytes(length))

    log.info("---- Error generation ----")
    test.value = 2

    from_addrs = [0, 8, 32, 64, 128, 256, 512, 1024, 2048, 4095]
    to_addrs = [0, 8, 32, 64, 128, 256, 512, 1024, 2048, 4095]
    byte_nums = [0, 1, 2, 3, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4095]

    for from_addr in from_addrs:
        for to_addr in to_addrs:
            for length in byte_nums:
                exp_err = calc_exp_err(from_addr, to_addr, length)
                await test_transfer(dut, s, length, from_addr, to_addr, random.randbytes(length), exp_err=exp_err, debug=0)

    log.info("---- Constrained random tests (with backpressure) ----")
    test.value = 3
    NUM_TESTS = 2000

    for _ in range(NUM_TESTS):
        prob = random.uniform(0, 0.8)
        s.write_if.aw_channel.set_pause_generator(stall_generator(prob))
        s.write_if.w_channel.set_pause_generator(stall_generator(prob))
        s.write_if.b_channel.set_pause_generator(stall_generator(prob))
        s.read_if.ar_channel.set_pause_generator(stall_generator(prob))
        s.read_if.r_channel.set_pause_generator(stall_generator(prob))

        from_addr = random.randint(0, 4096)
        to_addr = random.randint(0, 4096)
        length = random.randint(0, 4096)

        exp_err = calc_exp_err(from_addr, to_addr, length)
        
        await test_transfer(dut, s, length, from_addr, to_addr, random.randbytes(length), exp_err=exp_err, debug=0)