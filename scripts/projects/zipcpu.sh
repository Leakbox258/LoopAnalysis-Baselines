#!/bin/bash

set -euo pipefail

PROJECT_NAME="zipcpu"

VERILOG_FILES=(
	"./zipsystem.v" 
  	"./core/*.v" 
  	"./zipdma/*.v" 
  	"./ex/*.v" 
  	"./peripherals/*.v"
)

collectWithTop() {
	local PROJECTS=$1
	local -n fileSets=$2
	local -n tops=$3

	local RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl")
	pushd "$RTL_DIR" > /dev/null
	
	local current_files=()
	for pattern in "${VERILOG_FILES[@]}"; do
		# 展开通配符并检查
		for f in $pattern; do
			if [[ -f "$f" && "$(wc -c < "$f")" -gt 1 ]]; then
				current_files+=("$(realpath "$f")")
			fi
		done
	done

	if (( ${#current_files[@]} > 0 )); then
		tops+=("zipcpu")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi
	popd > /dev/null
}