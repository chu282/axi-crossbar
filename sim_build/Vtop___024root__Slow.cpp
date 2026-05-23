// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"
#include "Vtop__Syms.h"
#include "Vtop___024root.h"

// Parameter definitions for Vtop___024root
constexpr IData/*31:0*/ Vtop___024root::axi_addr_decoder_wrapper__DOT__ADDR_WIDTH;
constexpr IData/*31:0*/ Vtop___024root::axi_addr_decoder_wrapper__DOT__NUM_SLAVES;
constexpr IData/*31:0*/ Vtop___024root::axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_WIDTH;
constexpr IData/*31:0*/ Vtop___024root::axi_addr_decoder_wrapper__DOT__dut__DOT__NUM_SLAVES;
constexpr VlUnpacked<SData/*15:0*/, 4> Vtop___024root::axi_addr_decoder_wrapper__DOT__BASE_ADDRS;
constexpr VlUnpacked<SData/*15:0*/, 4> Vtop___024root::axi_addr_decoder_wrapper__DOT__ADDR_MASKS;
constexpr VlUnpacked<SData/*15:0*/, 4> Vtop___024root::axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS;
constexpr VlUnpacked<SData/*15:0*/, 4> Vtop___024root::axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS;


void Vtop___024root___ctor_var_reset(Vtop___024root* vlSelf);

Vtop___024root::Vtop___024root(Vtop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtop___024root___ctor_var_reset(this);
}

void Vtop___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vtop___024root::~Vtop___024root() {
}
