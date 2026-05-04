#!/bin/bash

set -euo pipefail

PROJECT_NAME="riscv"

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
	local -n incs=$4

	local SRC_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/core")
	pushd "$SRC_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find "." -name "*.v" -print0)

	if (( ${#current_files[@]} > 0 )); then
		tops+=("riscv_core")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi

	incs+=("-I${PROJECTS}/${PROJECT_NAME}/core/riscv/")

	popd > /dev/null
}