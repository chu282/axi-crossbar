import cocotb
import random
from assertion_error import *
from cocotb.triggers import Timer

@cocotb.test()
async def test_axi_addr_decoder(dut):
    ADDR_WIDTH = int(dut.ADDR_WIDTH.value)
    NUM_SLAVES = int(dut.NUM_SLAVES.value)

    base_addrs = [0x0000, 0x0080, 0x2000, 0x8000]
    addr_masks = [0xFFF0, 0xFF80, 0xE000, 0x8000]

    for valid in [0, 1]:
        dut.valid.value = valid
        for addr in range(2**ADDR_WIDTH):
            dut.addr.value = addr

            await Timer(1, unit="ns")
            exp_slave_select = 0
            if valid:
                for i in range(NUM_SLAVES):
                    base_addr = base_addrs[i]
                    addr_mask = addr_masks[i]
                    if (addr & addr_mask) == base_addr:
                        exp_slave_select = 1 << i

            assert int(dut.slave_select.value) == exp_slave_select, \
                get_err(exp_slave_select, "slave_select", dut.slave_select.value, [addr, valid, base_addr, addr_mask], ["addr", "valid", "base_addr", "addr_mask"])
            assert int(dut.decerr.value) == (valid and exp_slave_select == 0), \
                get_err(exp_decerr, "decerr", dut.decerr.value, [addr, valid], ["addr", "valid"])