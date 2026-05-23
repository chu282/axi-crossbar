// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtop__pch.h"
#include "Vtop.h"
#include "Vtop___024root.h"

// FUNCTIONS
Vtop__Syms::~Vtop__Syms()
{

    // Tear down scope hierarchy
    __Vhier.remove(0, &__Vscope_axi_addr_decoder_wrapper);
    __Vhier.remove(&__Vscope_axi_addr_decoder_wrapper, &__Vscope_axi_addr_decoder_wrapper__dut);
    __Vhier.remove(&__Vscope_axi_addr_decoder_wrapper__dut, &__Vscope_axi_addr_decoder_wrapper__dut__unnamedblk1);

}

Vtop__Syms::Vtop__Syms(VerilatedContext* contextp, const char* namep, Vtop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(25);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_TOP.configure(this, name(), "TOP", "TOP", "<null>", 0, VerilatedScope::SCOPE_OTHER);
    __Vscope_axi_addr_decoder_wrapper.configure(this, name(), "axi_addr_decoder_wrapper", "axi_addr_decoder_wrapper", "axi_addr_decoder_wrapper", -9, VerilatedScope::SCOPE_MODULE);
    __Vscope_axi_addr_decoder_wrapper__dut.configure(this, name(), "axi_addr_decoder_wrapper.dut", "dut", "axi_addr_decoder", -9, VerilatedScope::SCOPE_MODULE);
    __Vscope_axi_addr_decoder_wrapper__dut__unnamedblk1.configure(this, name(), "axi_addr_decoder_wrapper.dut.unnamedblk1", "unnamedblk1", "<null>", -9, VerilatedScope::SCOPE_OTHER);

    // Set up scope hierarchy
    __Vhier.add(0, &__Vscope_axi_addr_decoder_wrapper);
    __Vhier.add(&__Vscope_axi_addr_decoder_wrapper, &__Vscope_axi_addr_decoder_wrapper__dut);
    __Vhier.add(&__Vscope_axi_addr_decoder_wrapper__dut, &__Vscope_axi_addr_decoder_wrapper__dut__unnamedblk1);

    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
        __Vscope_TOP.varInsert(__Vfinal,"addr", &(TOP.addr), false, VLVT_UINT16,VLVD_IN|VLVF_PUB_RW,0,1 ,15,0);
        __Vscope_TOP.varInsert(__Vfinal,"decerr", &(TOP.decerr), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"slave_select", &(TOP.slave_select), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,1 ,3,0);
        __Vscope_TOP.varInsert(__Vfinal,"valid", &(TOP.valid), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"ADDR_MASKS", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__ADDR_MASKS))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1,1 ,3,0 ,15,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"ADDR_WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__ADDR_WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,0,1 ,31,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"BASE_ADDRS", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__BASE_ADDRS))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1,1 ,3,0 ,15,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"NUM_SLAVES", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__NUM_SLAVES))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,0,1 ,31,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"addr", &(TOP.axi_addr_decoder_wrapper__DOT__addr), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,0,1 ,15,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"decerr", &(TOP.axi_addr_decoder_wrapper__DOT__decerr), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"slave_select", &(TOP.axi_addr_decoder_wrapper__DOT__slave_select), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,3,0);
        __Vscope_axi_addr_decoder_wrapper.varInsert(__Vfinal,"valid", &(TOP.axi_addr_decoder_wrapper__DOT__valid), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"ADDR_MASKS", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1,1 ,3,0 ,15,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"ADDR_WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,0,1 ,31,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"BASE_ADDRS", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1,1 ,3,0 ,15,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"NUM_SLAVES", const_cast<void*>(static_cast<const void*>(&(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__NUM_SLAVES))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,0,1 ,31,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"addr", &(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__addr), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,0,1 ,15,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"decerr", &(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__decerr), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"slave_select", &(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__slave_select), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,3,0);
        __Vscope_axi_addr_decoder_wrapper__dut.varInsert(__Vfinal,"valid", &(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__valid), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_axi_addr_decoder_wrapper__dut__unnamedblk1.varInsert(__Vfinal,"i", &(TOP.axi_addr_decoder_wrapper__DOT__dut__DOT__unnamedblk1__DOT__i), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW|VLVF_DPI_CLAY,0,1 ,31,0);
    }
}
