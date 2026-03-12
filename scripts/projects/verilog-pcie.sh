#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-pcie"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/rtl" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="verilog_pcie"
	source=$(find . -name "*.v" \
  					! -name "pcie_s10_if*" \
  					! -name "pcie_ptile_if*"\
  					! -name "pcie_us_if*"\
  					! -name "pcie_tlp_demux_bar*" \
  					! -name "pcie_tlp_fifo_mux*" \
					| awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')

	fileSets[${#fileSets[@]}]="$source"
	popd > /dev/null
}