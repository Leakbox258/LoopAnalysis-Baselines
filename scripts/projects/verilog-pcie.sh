#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-pcie"

qualify() {
	mode=$1

	case $mode in
		"eval-verilator")
			return 0
			;;
		"eval-wiresort")
			return 0
			;;
		"eval-yosys")
			return 0
			;;
	esac
}

collectWithTop() {
	local PROJECTS=$1
	local -n fileSets=$2
	local -n tops=$3

	local RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl")
	pushd "$RTL_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find . -name "*.v" \
  					! -name "pcie_s10_if*" \
  					! -name "pcie_ptile_if*"\
  					! -name "pcie_us_if*"\
  					! -name "pcie_tlp_demux_bar*" \
  					! -name "pcie_tlp_fifo_mux*" -print0)

	if (( ${#current_files[@]} > 0 )); then
		tops+=("verilog_pcie")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi
	popd > /dev/null
}