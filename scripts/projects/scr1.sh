#!/bin/bash

set -euo pipefail

PROJECT_NAME="scr1"

VERILOG_FILES=(
	core/pipeline/scr1_pipe_hdu.sv
	core/pipeline/scr1_pipe_tdu.sv
	core/pipeline/scr1_ipic.sv
	core/pipeline/scr1_pipe_csr.sv
	core/pipeline/scr1_pipe_exu.sv
	core/pipeline/scr1_pipe_ialu.sv
	core/pipeline/scr1_pipe_idu.sv
	core/pipeline/scr1_pipe_ifu.sv
	core/pipeline/scr1_pipe_lsu.sv
	core/pipeline/scr1_pipe_mprf.sv
	core/pipeline/scr1_pipe_top.sv
	core/primitives/scr1_reset_cells.sv
	core/primitives/scr1_cg.sv
	core/scr1_clk_ctrl.sv
	core/scr1_tapc_shift_reg.sv
	core/scr1_tapc.sv
	core/scr1_tapc_synchronizer.sv
	core/scr1_core_top.sv
	core/scr1_dm.sv
	core/scr1_dmi.sv
	core/scr1_scu.sv
	top/scr1_dmem_router.sv
	top/scr1_imem_router.sv
	top/scr1_dp_memory.sv
	top/scr1_tcm.sv
	top/scr1_timer.sv
	top/scr1_dmem_ahb.sv
	top/scr1_imem_ahb.sv
	top/scr1_top_ahb.sv	
	)

qualify() {
	mode=$1

	case $mode in
		"eval-verilator")
			return 0
			;;
		"eval-wiresort")
			return 1
			;;
		"eval-yosys")
			return 0
			;;
	esac
}

collectWithTopVerilator() {
    collectWithTop "$1" "$2" "$3" "$4" "$5"
}

collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3
    local -n defs=$4
    local -n incs=$5

    local SRC_ROOT
    SRC_ROOT=$(realpath "${PROJECTS}/${PROJECT_NAME}/src")
    
    local current_files=()

    for hdl in "${VERILOG_FILES[@]}"; do
        local abs_file="${SRC_ROOT}/${hdl}"
        
		file_name=$(basename "$abs_file")

		if [[ -f "$abs_file" && "$(wc -c < "$abs_file")" -gt 1 ]] \
			&& [[ ! "$file_name" =~ (^|[_-])tb([._-]|$) ]] \
			&& [[ ! "$file_name" =~ testbench ]]; then
			current_files+=("$abs_file")
		fi
    done

    if (( ${#current_files[@]} > 0 )); then
        tops+=("scr1_top_ahb")
        fileSets+=("$(printf "%q " "${current_files[@]}")")

		# tops+=("scr1_top_axi")        
        # fileSets+=("$(printf "%q " "${current_files[@]}")")

        defs+=("-DSCR1_CFG_RV32IMC_MAX")
        incs+=("-I${SRC_ROOT}/includes")
    fi
}