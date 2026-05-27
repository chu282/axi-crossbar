# Simulator settings
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

TOPLEVEL ?= axi_mux

# Automatically append _wrapper to TOPLEVEL if not already present
ifeq ($(filter %_wrapper,$(TOPLEVEL)),)
    override TOPLEVEL := $(TOPLEVEL)_wrapper
endif

COCOTB_TEST_MODULES ?= tb_$(subst _wrapper,,$(TOPLEVEL))

export PYTHONPATH := $(PWD)/testbench:$(PYTHONPATH)
export COCOTB_WAVES_FILE = waves/fst/$(COCOTB_TEST_MODULES).fst
export COCOTB_WAVES ?= 1

VERILOG_SOURCES += $(filter-out %_wrapper.sv, $(wildcard $(PWD)/source/*.sv))
VERILOG_SOURCES += $(PWD)/tb_wrappers/$(TOPLEVEL).sv

EXTRA_ARGS += -Wall --trace --trace-fst --trace-structs
SIM_BUILD = sim_builds/$(subst _wrapper,,$(TOPLEVEL))

include $(shell cocotb-config --makefiles)/Makefile.sim

view:
	surfer $(COCOTB_WAVES_FILE) --state-file waves/$(COCOTB_TEST_MODULES).surf.ron > /dev/null 2>&1 &

%_sim:
	$(MAKE) sim TOPLEVEL=$* ; \
	RET=$$? ; \
	if [ -f dump.fst ]; then \
		mv dump.fst waves/fst/tb_$*.fst ; \
	fi ; \
	exit $$RET

%_view:
	$(MAKE) view TOPLEVEL=$*

%_run:
	$(MAKE) $*_sim ; \
	RET=$$? ; \
	$(MAKE) $*_view ; \
	exit $$RET

clean::
	rm -rf sim_builds