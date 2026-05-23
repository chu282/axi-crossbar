// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vtop__Syms.h"


void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vtop___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vtop___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0_sub_0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    bufp->chgBit(oldp+0,(vlSelfRef.valid));
    bufp->chgSData(oldp+1,(vlSelfRef.addr),16);
    bufp->chgCData(oldp+2,(vlSelfRef.slave_select),4);
    bufp->chgBit(oldp+3,(vlSelfRef.decerr));
    bufp->chgBit(oldp+4,(vlSelfRef.axi_addr_decoder_wrapper__DOT__valid));
    bufp->chgSData(oldp+5,(vlSelfRef.axi_addr_decoder_wrapper__DOT__addr),16);
    bufp->chgCData(oldp+6,(vlSelfRef.axi_addr_decoder_wrapper__DOT__slave_select),4);
    bufp->chgBit(oldp+7,(vlSelfRef.axi_addr_decoder_wrapper__DOT__decerr));
    bufp->chgSData(oldp+8,(vlSelfRef.axi_addr_decoder_wrapper__DOT__BASE_ADDRS[0]),16);
    bufp->chgSData(oldp+9,(vlSelfRef.axi_addr_decoder_wrapper__DOT__BASE_ADDRS[1]),16);
    bufp->chgSData(oldp+10,(vlSelfRef.axi_addr_decoder_wrapper__DOT__BASE_ADDRS[2]),16);
    bufp->chgSData(oldp+11,(vlSelfRef.axi_addr_decoder_wrapper__DOT__BASE_ADDRS[3]),16);
    bufp->chgSData(oldp+12,(vlSelfRef.axi_addr_decoder_wrapper__DOT__ADDR_MASKS[0]),16);
    bufp->chgSData(oldp+13,(vlSelfRef.axi_addr_decoder_wrapper__DOT__ADDR_MASKS[1]),16);
    bufp->chgSData(oldp+14,(vlSelfRef.axi_addr_decoder_wrapper__DOT__ADDR_MASKS[2]),16);
    bufp->chgSData(oldp+15,(vlSelfRef.axi_addr_decoder_wrapper__DOT__ADDR_MASKS[3]),16);
    bufp->chgSData(oldp+16,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS[0]),16);
    bufp->chgSData(oldp+17,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS[1]),16);
    bufp->chgSData(oldp+18,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS[2]),16);
    bufp->chgSData(oldp+19,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS[3]),16);
    bufp->chgSData(oldp+20,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS[0]),16);
    bufp->chgSData(oldp+21,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS[1]),16);
    bufp->chgSData(oldp+22,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS[2]),16);
    bufp->chgSData(oldp+23,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS[3]),16);
    bufp->chgBit(oldp+24,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__valid));
    bufp->chgSData(oldp+25,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__addr),16);
    bufp->chgCData(oldp+26,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__slave_select),4);
    bufp->chgBit(oldp+27,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__decerr));
    bufp->chgIData(oldp+28,(vlSelfRef.axi_addr_decoder_wrapper__DOT__dut__DOT__unnamedblk1__DOT__i),32);
}

void Vtop___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_cleanup\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
