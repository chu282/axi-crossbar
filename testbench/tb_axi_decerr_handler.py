import cocotb
import random

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

NUM_TESTS = 1000
DECERR = 0b11

@cocotb.test()
async def test_axi_decerr_handler(dut):
    # Inputs
    clk = dut.clk
    n_rst = dut.n_rst
    skip_write = dut.skip_write
    decerr = dut.decerr
    response_ready = dut.response_ready
    write_valid = dut.write_valid
    write_last = dut.write_last
    address_id = dut.address_id

    # Outputs
    response_valid = dut.response_valid
    address_ready = dut.address_ready
    write_ready = dut.write_ready
    response_payload = dut.response_payload
    decerr_grant = dut.decerr_grant

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.n_rst.value = 0
    dut.skip_write.value = 0
    dut.decerr.value = 0
    dut.response_ready.value = 0
    dut.write_valid.value = 0
    dut.write_last.value = 0
    dut.address_id.value = 0

    await FallingEdge(clk)
    dut.n_rst.value = 1
    await FallingEdge(clk)

    dut._log.info("---- Normal operation ----")
    # stay in idle
    for _ in range(10):
        await FallingEdge(clk)
        assert response_valid.value == 0
        assert address_ready.value == 0
        assert write_ready.value == 0
        assert decerr_grant.value == 0
        assert response_payload.value == 0

    # transition to send_addr_ready
    decerr.value = 1
    address_id_val = 0b1010
    address_id.value = address_id_val
    await FallingEdge(clk)
    address_id.value = 0b0000
    decerr.value = 0

    assert address_ready.value == 1
    assert decerr_grant.value == 1
    assert response_valid.value == 0
    assert write_ready.value == 0
    assert response_payload.value == 0

    # transition to send_w_ready
    write_valid.value = 1
    write_last.value = 1
    await FallingEdge(clk)
    write_valid.value = 0
    write_last.value = 0

    for _ in range(10):
        assert address_ready.value == 0
        assert decerr_grant.value == 1
        assert response_valid.value == 0
        assert write_ready.value == 1
        assert response_payload.value == 0
        await FallingEdge(clk)

    # transition to send_resp
    write_valid.value = 1
    write_last.value = 1
    await FallingEdge(clk)
    write_valid.value = 0
    write_last.value = 0

    for _ in range(10):
        assert address_ready.value == 0
        assert decerr_grant.value == 1
        assert response_valid.value == 1
        assert write_ready.value == 0
        assert response_payload.value == address_id_val << 2 | DECERR
        await FallingEdge(clk)

    # transition to idle
    response_ready.value = 1
    await FallingEdge(clk)
    response_ready.value = 0
    
    assert address_ready.value == 0
    assert decerr_grant.value == 0
    assert response_valid.value == 0
    assert write_ready.value == 0
    assert response_payload.value == 0

    dut._log.info("---- Skip write ----")
    # idle
    await FallingEdge(clk)

    # transition to send_addr_ready
    decerr.value = 1
    address_id_val = 0b1111
    address_id.value = address_id_val
    await FallingEdge(clk)
    address_id.value = 0b0000
    decerr.value = 0

    assert address_ready.value == 1
    assert decerr_grant.value == 1
    assert response_valid.value == 0
    assert write_ready.value == 0
    assert response_payload.value == 0

    # transition to send_resp
    skip_write.value = 1
    await FallingEdge(clk)
    skip_write.value = 0
    
    assert address_ready.value == 0
    assert decerr_grant.value == 1
    assert response_valid.value == 1
    assert write_ready.value == 0
    assert response_payload.value == address_id_val << 2 | DECERR

    # reset
    n_rst.value = 0
    await FallingEdge(clk)
    n_rst.value = 1
    await FallingEdge(clk)

    dut._log.info("---- Randomized operation ----")
    class States:
        IDLE = 0
        SEND_ADDR_READY = 1
        SEND_W_READY = 2
        SEND_RESP = 3

    state = States.IDLE
    
    for _ in range(NUM_TESTS):
        # random inputs
        skip_write_val = random.randint(0, 1)
        decerr_val = random.randint(0, 1)
        response_ready_val = random.randint(0, 1)
        write_valid_val = random.randint(0, 1)
        write_last_val = random.randint(0, 1)
        address_id_val = random.randint(0, 3)

        decerr.value = decerr_val
        response_ready.value = response_ready_val
        write_valid.value = write_valid_val
        write_last.value = write_last_val
        address_id.value = address_id_val
        skip_write.value = skip_write_val
        
        match state:
            case States.IDLE:
                assert address_ready.value == 0
                assert decerr_grant.value == 0
                assert response_valid.value == 0
                assert write_ready.value == 0
                assert response_payload.value == 0

                if decerr_val == 1:
                    state = States.SEND_ADDR_READY
                    address_id_captured_val = address_id_val
            case States.SEND_ADDR_READY:
                assert address_ready.value == 1
                assert decerr_grant.value == 1
                assert response_valid.value == 0
                assert write_ready.value == 0
                assert response_payload.value == 0

                if skip_write_val == 1:
                    state = States.SEND_RESP
                else:
                    state = States.SEND_W_READY
            case States.SEND_W_READY:
                assert address_ready.value == 0
                assert decerr_grant.value == 1
                assert response_valid.value == 0
                assert write_ready.value == 1
                assert response_payload.value == 0

                if write_valid_val == 1 and write_last_val == 1:
                    state = States.SEND_RESP
            case States.SEND_RESP:
                assert address_ready.value == 0
                assert decerr_grant.value == 1
                assert response_valid.value == 1
                assert write_ready.value == 0
                assert response_payload.value == address_id_captured_val << 2 | DECERR

                if response_ready_val == 1:
                    state = States.IDLE
            case _:
                state = States.IDLE
        
        await FallingEdge(clk)
        