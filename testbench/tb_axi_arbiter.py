import cocotb
import random
import math

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import Timer

NUM_DEVICES = 8

def get_exp_grant(req, last_grant):
    if (req == 0): return 0

    if (last_grant == 0): 
        grant = 1
    else:
        grant = last_grant << 1

    wrap = 1
    while grant < 2 ** NUM_DEVICES:
        if req & grant != 0:
            wrap = 0
            break
        grant = grant << 1
    
    if wrap:
        grant = 1
        while grant < 2 ** NUM_DEVICES:
            if req & grant != 0:
                wrap = 0
                break
            grant = grant << 1

    return grant

@cocotb.test()
async def test_axi_arbiter(dut):
    test = dut.test
    # Inputs
    clk = dut.clk
    n_rst = dut.n_rst
    tf_finished = dut.tf_finished
    request = dut.request

    # Outputs
    grant = dut.grant

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    n_rst.value = 0
    tf_finished.value = 0
    request.value = 0

    await FallingEdge(clk)
    n_rst.value = 1
    await FallingEdge(clk)
    
    dut._log.info("---- Single device ----")
    test.value = 1
    reqs = [1 << x for x in range(NUM_DEVICES)]
    request.value = reqs[0]
    await FallingEdge(clk)
    for idx, req in enumerate(reqs):
        assert grant.value == req
        # verify grant is held
        await FallingEdge(clk)
        await FallingEdge(clk)
        assert grant.value == req

        # tf finished
        tf_finished.value = 1
        request.value = reqs[idx+1] if idx < len(reqs) - 1 else 0
        await FallingEdge(clk)
        tf_finished.value = 0
        await Timer(1, unit="ns")

    dut._log.info("---- Simple round robin ----")
    test.value = 2
    request.value = 0b1111_1111
    exp_grant = [1 << i for i in range(8)]
    await FallingEdge(clk)
    for idx in range(20):
        assert grant.value == exp_grant[idx % 8]
        # verify grant is held
        await FallingEdge(clk)
        await FallingEdge(clk)
        assert grant.value == exp_grant[idx % 8]

        # tf finished
        tf_finished.value = 1
        await FallingEdge(clk)
        tf_finished.value = 0
        await Timer(1, unit="ns")

    dut._log.info("---- Reset ----")
    test.value = 3
    request.value = 0
    n_rst.value = 0
    await FallingEdge(clk)
    n_rst.value = 1
    assert grant.value == 0

    dut._log.info("---- Complex round robin ----")
    test.value = 4

    NUM_TESTS = 100
    reqs = random.randbytes(NUM_TESTS)
    last_grant = 0
    request.value = reqs[0]
    await FallingEdge(clk)
    for idx, req in enumerate(reqs):
        exp_grant = get_exp_grant(req, last_grant)
        assert grant.value == exp_grant
        # verify grant is held
        for _ in range(random.randint(1, 3)):
            await FallingEdge(clk)
            assert grant.value == exp_grant

        if grant.value != 0:
            last_grant = int(grant.value)

        # tf finished
        tf_finished.value = 1
        request.value = reqs[idx+1] if idx < len(reqs) - 1 else 0
        await FallingEdge(clk)
        tf_finished.value = 0
        await Timer(1, unit="ns")