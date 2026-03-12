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

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3
	declare -n defs=$4
	declare -n incs=$5

	tops[${#tops[@]}]="scr1"

	source=()
	path="${PROJECTS}/${PROJECT_NAME}/src"
	for hdl in "${VERILOG_FILES[@]}"; do
		source+=("${path}/${hdl}")
	done

	fileSets[${#fileSets[@]}]="${source[*]}"
	defs[${#defs[@]}]="-DSCR1_CFG_RV32IMC_MAX"
	incs[${#incs[@]}]="-I${PROJECTS}/${PROJECT_NAME}/src/includes"
}