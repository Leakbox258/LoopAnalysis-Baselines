#!/bin/bash

set -euo pipefail

PROJECT_NAME="darkriscv"
VERILOG_FILES=(
	rtl/darksocv.v
  	rtl/darkbridge.v 
  	rtl/darkuart.v   
  	rtl/darkriscv.v  
  	rtl/darkpll.v    
  	rtl/darkram.v    
  	rtl/darkio.v     
  	rtl/darkcache.v
  )

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
	local -n incs=$5

	pushd "${PROJECTS}/${PROJECT_NAME}"> /dev/null
	local hdls=()
	for file in "${VERILOG_FILES[@]}"; do
		local abs_f=$(realpath "$file")
		if [[ -f "$abs_f" && "$(wc -c < "$abs_f")" -gt 1 ]]; then
			hdls+=("$abs_f")
		fi
	done
	
	if (( ${#hdls[@]} > 0 )); then
		tops+=("darksocv")
		fileSets+=("$(printf "%q " "${hdls[@]}")")
	fi
	incs+=("-I${PROJECTS}/${PROJECT_NAME}/rtl")
	popd > /dev/null
}