// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"


class Vtop__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(valid,0,0);
    VL_OUT8(slave_select,3,0);
    VL_OUT8(decerr,0,0);
    CData/*0:0*/ axi_addr_decoder_wrapper__DOT__valid;
    CData/*3:0*/ axi_addr_decoder_wrapper__DOT__slave_select;
    CData/*0:0*/ axi_addr_decoder_wrapper__DOT__decerr;
    CData/*0:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__valid;
    CData/*3:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__slave_select;
    CData/*0:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__decerr;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __VactContinue;
    VL_IN16(addr,15,0);
    SData/*15:0*/ axi_addr_decoder_wrapper__DOT__addr;
    SData/*15:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__addr;
    IData/*31:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__unnamedblk1__DOT__i;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // PARAMETERS
    static constexpr IData/*31:0*/ axi_addr_decoder_wrapper__DOT__ADDR_WIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ axi_addr_decoder_wrapper__DOT__NUM_SLAVES = 4U;
    static constexpr IData/*31:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_WIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ axi_addr_decoder_wrapper__DOT__dut__DOT__NUM_SLAVES = 4U;
    static constexpr VlUnpacked<SData/*15:0*/, 4> axi_addr_decoder_wrapper__DOT__BASE_ADDRS = {{
        0x0000U, 0x0080U, 0x2000U, 0x8000U
    }};
    static constexpr VlUnpacked<SData/*15:0*/, 4> axi_addr_decoder_wrapper__DOT__ADDR_MASKS = {{
        0xfff0U, 0xff80U, 0xe000U, 0x8000U
    }};
    static constexpr VlUnpacked<SData/*15:0*/, 4> axi_addr_decoder_wrapper__DOT__dut__DOT__BASE_ADDRS = {{
        0x0000U, 0x0080U, 0x2000U, 0x8000U
    }};
    static constexpr VlUnpacked<SData/*15:0*/, 4> axi_addr_decoder_wrapper__DOT__dut__DOT__ADDR_MASKS = {{
        0xfff0U, 0xff80U, 0xe000U, 0x8000U
    }};

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
