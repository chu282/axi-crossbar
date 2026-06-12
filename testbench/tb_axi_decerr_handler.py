import cocotb
import random

from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

NUM_TESTS = 10000
DECERR = 0b11

@cocotb.test()
async def test_axi_decerr_handler(dut):
    # Inputs
    clk = dut.clk
    n_rst = dut.n_rst
    write = dut.write
    decerr = dut.decerr
    response_ready = dut.response_ready
    write_valid = dut.write_valid
    write_last = dut.write_last
    address_id = dut.address_id
    read_len = dut.read_len

    # Outputs
    response_valid = dut.response_valid
    response_last = dut.response_last
    address_ready = dut.address_ready
    write_ready = dut.write_ready
    decerr_grant = dut.decerr_grant
    response_id = dut.response_id
    response_resp = dut.response_resp

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.n_rst.value = 0
    dut.write.value = 0
    dut.decerr.value = 0
    dut.response_ready.value = 0
    dut.write_valid.value = 0
    dut.write_last.value = 0
    dut.address_id.value = 0
    dut.read_len.value = 0

    await FallingEdge(clk)
    dut.n_rst.value = 1
    await FallingEdge(clk)

    dut._log.info("---- Normal read operation ----")
    # stay in idle
    for _ in range(10):
        await FallingEdge(clk)
        assert address_ready.value == 0
        assert response_valid.value == 0
        assert response_id.value == 0
        assert response_resp.value == 0
        assert response_last.value == 0
        assert decerr_grant.value == 0

    # transition to send_addr_ready
    decerr.value = 1
    address_id_val = 0b1010
    address_id.value = address_id_val
    read_len.value = 8
    await FallingEdge(clk)
    address_id.value = 0b0000
    decerr.value = 0
    read_len.value = 0

    assert address_ready.value == 1
    assert response_valid.value == 0
    assert response_id.value == 0
    assert response_resp.value == 0
    assert response_last.value == 0
    assert decerr_grant.value == 1

    # transition to send_resp
    write_valid.value = 1
    write_last.value = 1
    await FallingEdge(clk)
    write_valid.value = 0
    write_last.value = 0

    for i in range(8):
        # make sure we dont count sent responses when master is not ready
        response_ready.value = 0
        await FallingEdge(clk)
        response_ready.value = 1

        assert address_ready.value == 0
        assert response_valid.value == 1
        assert response_id.value == address_id_val
        assert response_resp.value == DECERR
        assert response_last.value == 0
        assert decerr_grant.value == 1
        await FallingEdge(clk)

    assert address_ready.value == 0
    assert response_valid.value == 1
    assert response_id.value == address_id_val
    assert response_resp.value == DECERR
    assert response_last.value == 1
    assert decerr_grant.value == 1

    # transition to idle
    await FallingEdge(clk)
    
    assert address_ready.value == 0
    assert response_valid.value == 0
    assert response_id.value == 0
    assert response_resp.value == 0
    assert response_last.value == 0
    assert decerr_grant.value == 0

    dut._log.info("---- Normal write operation ----")
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
    assert write_ready.value == 0
    assert response_valid.value == 0
    assert response_id.value == 0
    assert response_resp.value == 0
    assert decerr_grant.value == 1

    # transition to send_w_ready
    write.value = 1
    await FallingEdge(clk)
    write.value = 0

    for _ in range(10):
        assert address_ready.value == 0
        assert response_valid.value == 0
        assert response_id.value == 0
        assert response_resp.value == 0
        assert response_last.value == 0
        assert decerr_grant.value == 1
        await FallingEdge(clk)

    # transition to send_resp
    write_valid.value = 1
    write_last.value = 1
    await FallingEdge(clk)
    write_valid.value = 0
    write_last.value = 0

    # make sure we dont count sent responses when master is not ready
    response_ready.value = 0
    for _ in range(10):
        await FallingEdge(clk)
    response_ready.value = 1

    # transition to idle
    write_ready.value = 1
    await FallingEdge(clk)
    write_ready.value = 0
    
    assert address_ready.value == 0
    assert write_ready.value == 0
    assert response_valid.value == 0
    assert response_id.value == 0
    assert response_resp.value == 0
    assert decerr_grant.value == 0

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
        if state == States.IDLE: write_val = random.randint(0, 1)
        decerr_val = random.randint(0, 1)
        response_ready_val = random.randint(0, 1)
        write_valid_val = random.randint(0, 1)
        write_last_val = random.randint(0, 1)
        address_id_val = random.randint(0, 15)
        read_len_val = random.randint(0, 255)

        write.value = write_val
        decerr.value = decerr_val
        response_ready.value = response_ready_val
        write_valid.value = write_valid_val
        write_last.value = write_last_val
        address_id.value = address_id_val
        read_len.value = read_len_val

        match state:
            case States.IDLE:
                assert address_ready.value == 0
                assert write_ready.value == 0
                assert response_valid.value == 0
                assert response_id.value == 0
                assert response_resp.value == 0
                assert response_last.value == 0
                assert decerr_grant.value == 0

                if decerr_val == 1:
                    state = States.SEND_ADDR_READY
                    captured_address_id = address_id_val
                    captured_read_len = read_len_val
                    sent_responses = 0

            case States.SEND_ADDR_READY:
                assert address_ready.value == 1
                if write_val == 1: assert write_ready.value == 0
                assert response_valid.value == 0
                assert response_id.value == 0
                assert response_resp.value == 0
                if write_val == 0: assert response_last.value == 0
                assert decerr_grant.value == 1

                if write_val == 1:
                    state = States.SEND_W_READY
                else:
                    state = States.SEND_RESP
            case States.SEND_W_READY:
                assert address_ready.value == 0
                if write_val == 1: assert write_ready.value == 1
                assert response_valid.value == 0
                assert response_id.value == 0
                assert response_resp.value == 0
                if write_val == 0: assert response_last.value == 0
                assert decerr_grant.value == 1

                if write_valid_val == 1 and write_last_val == 1:
                    state = States.SEND_RESP
            case States.SEND_RESP:
                assert address_ready.value == 0
                if write_val == 1: assert write_ready.value == 0
                assert response_valid.value == 1
                assert response_id.value == captured_address_id
                assert response_resp.value == DECERR
                if write_val == 0: assert response_last.value == (sent_responses == captured_read_len)
                assert decerr_grant.value == 1

                if (response_ready_val == 1 and (sent_responses == captured_read_len)):
                   state = States.IDLE

                if response_ready_val == 1:
                    sent_responses += 1
            case _:
                state = States.IDLE
        
        await FallingEdge(clk)