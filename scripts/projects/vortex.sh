#!/bin/bash

set -euo pipefail

PROJECT_NAME="vortex"

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
	local -n defs=$4
	local -n incs=$5

	local current_files=()
	while IFS= read -r -d '' f; do
		[[ "$(wc -c < "$f")" -gt 1 ]] && current_files+=("$(realpath "$f")")
	done < <(find "${PROJECTS}/${PROJECT_NAME}/hw/rtl" -name "*.sv" -name "*.vh" -print0)

	while IFS= read -r -d '' f; do
		if [[ ! $f =~ (8086|ARM) ]] && [[ "$(wc -c < "$f")" -gt 1 ]]; then
			current_files+=("$(realpath "$f")")
		fi
	done < <(find "${PROJECTS}/${PROJECT_NAME}/third_party/hardfloat/source" -name "*.v" -print0)
	
	incs+=("-I${PROJECTS}/${PROJECT_NAME}/hw/rtl/afu/xrt/")
	while IFS= read -r dir; do
		incs+=("-I$(realpath "$dir")")
	done < <(find "${PROJECTS}/${PROJECT_NAME}/hw/rtl" -name "*.vh" -exec dirname {} \; | sort -u)

	while IFS= read -r dir; do
		if [[ ! $dir =~ (8086|ARM) ]]; then
			incs+=("-I$(realpath "$dir")")
		fi
	done < <(find "${PROJECTS}/${PROJECT_NAME}/third_party/hardfloat/source" -name "*.vi" -exec dirname {} \; | sort -u)

	tops+=("vortex")
	fileSets+=("$(printf "%q " "${current_files[@]}")")
	defs+=("-DNOPAE" "-DEXT_TCU_ENABLE" "-DexpWidth=8")
}