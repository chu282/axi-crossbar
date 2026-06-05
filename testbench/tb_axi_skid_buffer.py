import cocotb
import random

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

PAYLOAD_WIDTH = 8
NUM_TESTS = 1000

@cocotb.test()
async def test_axi_skid_buffer(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    clk = dut.clk
    
    # signals
    n_rst = dut.n_rst
    src_valid = dut.src_valid
    dst_ready = dut.dst_ready
    src_payload = dut.src_payload
    dst_payload = dut.dst_payload
    src_ready = dut.src_ready
    dst_valid = dut.dst_valid
    test = dut.test

    n_rst.value = 0
    src_valid.value = 0
    dst_ready.value = 0
    src_payload.value = 0
    test.value = 0

    await FallingEdge(clk)
    n_rst.value = 1

    dut._log.info("---- Normal Operation ----")
    test.value = 1
    data_array = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
    src_valid.value = 1
    dst_ready.value = 1

    for data in data_array:
        dut.src_payload.value = data
        await FallingEdge(clk)
        assert src_ready.value == 1
        assert dst_valid.value == 1
        assert dst_payload.value == data

    dut._log.info("---- Backpressure ----")
    test.value = 2
    src_valid.value = 1
    dst_ready.value = 0
    src_payload.value = 0xAB

    await FallingEdge(clk)
    assert src_ready.value == 0
    assert dst_valid.value == 1

    # Make sure that buffer holds value by waiting a bit
    src_payload.value = 0x11
    for _ in range(8): await FallingEdge(clk)
    assert src_ready.value == 0
    assert dst_valid.value == 1

    dut._log.info("---- Empty skid buffer ----")
    test.value = 3
    src_valid.value = 1
    dst_ready.value = 1

    await FallingEdge(clk)
    assert src_ready.value == 1
    assert dst_valid.value == 1
    assert dst_payload.value == 0xAB # value should be from buffer

    dut._log.info("---- Continue normal operation ----")
    test.value = 4
    src_valid.value = 1
    dst_ready.value = 1
    data_array = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]

    for data in data_array:
        src_payload.value = data
        await FallingEdge(clk)
        assert src_ready.value == 1
        assert dst_valid.value == 1
        assert dst_payload.value == data

    dut._log.info("---- Reset ----")
    test.value = 5
    n_rst.value = 0
    src_valid.value = 0
    dst_ready.value = 0

    await FallingEdge(clk)
    n_rst.value = 1
    assert src_ready.value == 1
    assert dst_valid.value == 0
    assert dst_payload.value == 0

    dut._log.info("---- Single cycle skid ----")
    test.value = 6
    # Normal cycle
    src_valid.value = 1
    dst_ready.value = 1
    src_payload.value = 0xAB

    await FallingEdge(clk)
    assert src_ready.value == 1
    assert dst_valid.value == 1
    assert dst_payload.value == 0xAB

    # Ready is pulled low
    dst_ready.value = 0
    src_payload.value = 0xBC

    await FallingEdge(clk)
    assert src_ready.value == 0
    assert dst_valid.value == 1
    assert dst_payload.value == 0xAB

    # Restore from skid buffer
    dst_ready.value = 1
    src_payload.value = 0xCD

    await FallingEdge(clk)
    assert src_ready.value == 1
    assert dst_valid.value == 1
    assert dst_payload.value == 0xBC
    
    await FallingEdge(clk)
    assert src_ready.value == 1
    assert dst_valid.value == 1
    assert dst_payload.value == 0xCD

    n_rst.value = 0
    src_valid.value = 0
    dst_ready.value = 0
    await FallingEdge(clk)
    n_rst.value = 1

    dut._log.info("---- Randomized operation ----")
    test.value = 7
    queue = []

    for i in range(NUM_TESTS):
        in_src_valid = random.randint(0, 1)
        in_dst_ready = random.randint(0, 1)
        in_src_payload = random.getrandbits(PAYLOAD_WIDTH)

        src_valid.value = in_src_valid
        dst_ready.value = in_dst_ready
        src_payload.value = in_src_payload

        exp_dst_valid = 0
        exp_src_ready = 1
        exp_dst_payload = 0

        push = in_src_valid == 1 and len(queue) < 2 # buffer has space
        pop = in_dst_ready == 1 and len(queue) > 0 # buffer has no space

        if push:
            queue.append(in_src_payload)
        if pop:
            queue.pop(0)

        exp_dst_valid = len(queue) > 0 # buffer has items
        exp_src_ready = len(queue) < 2 # buffer not full
        exp_dst_payload = queue[0] if len(queue) > 0 else 0

        await FallingEdge(clk)

        assert dst_valid.value == exp_dst_valid
        assert src_ready.value == exp_src_ready
        if len(queue) > 0:
            assert int(dst_payload.value) == int(exp_dst_payload)
