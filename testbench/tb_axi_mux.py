import cocotb
import random
import math
from cocotb.triggers import Timer


@cocotb.test()
async def test_axi_mux(dut):
    PAYLOAD_WIDTH = int(dut.PAYLOAD_WIDTH.value)
    NUM_DEVICES = int(dut.NUM_DEVICES.value)
        
    for grant in [0b00, 0b10, 0b01]:
        dut.grant.value = grant
        for src_valid in range(0b100):
            dut.src_valid.value = src_valid
            for dst_ready in [0, 1]:
                dut.dst_ready.value = dst_ready
                for src_idx in range(NUM_DEVICES):
                    dut.src_payload[src_idx].value = random.getrandbits(PAYLOAD_WIDTH)

                await Timer(1, unit="ns")

                assert dut.dst_valid.value == ((src_valid & grant) != 0)
                if (grant == 0):
                    assert dut.dst_payload.value == 0
                else:
                    idx = math.ceil(math.log2(grant))
                    assert dut.dst_payload.value == dut.src_payload.value[idx] 
                assert dut.src_ready.value == (grant if dst_ready else 0)