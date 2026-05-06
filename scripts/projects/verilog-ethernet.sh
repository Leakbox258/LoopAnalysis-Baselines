#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-ethernet"

# parameter bug find in axis_baser_rx_64.v:313
# verilator will never end analyze it and slang will exit after detecting the bug
# but original read_verilog from yosys will ignore the bug

# 3rd-party/projects/verilog-ethernet/rtl/axis_baser_rx_64.v:313:40: error: cannot select range of 96 elements from 'reg[0:0]' [-Wrange-width-oob]
#                 m_axis_tuser_next[1 +: PTP_TS_WIDTH] = (!PTP_TS_FMT_TOD || ptp_ts_borrow_reg) ? ptp_ts_reg : ptp_ts_adj_reg;
#                                        ^~~~~~~~~~~~
# 3rd-party/projects/verilog-ethernet/rtl/axis_xgmii_rx_64.v:241:40: error: cannot select range of 96 elements from 'reg[0:0]' [-Wrange-width-oob]
#                 m_axis_tuser_next[1 +: PTP_TS_WIDTH] = (!PTP_TS_FMT_TOD || ptp_ts_borrow_reg) ? ptp_ts_reg : ptp_ts_adj_reg;
#                                        ^~~~~~~~~~~~

qualify() {
	mode=$1

	case $mode in
		"eval-verilator")
			return 1
			;;
		"eval-wiresort")
			return 1
			;;
		"eval-yosys")
			return 1
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

	local ROOT_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}")
	pushd "$ROOT_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find ./lib/axis/rtl/ ./rtl/ -name "*.v" -print0)

	if (( ${#current_files[@]} > 0 )); then
		tops+=("verilog_ethernet")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi
	popd > /dev/null
}