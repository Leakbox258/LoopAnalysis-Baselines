#!/bin/bash

set -euo pipefail

PROJECT_NAME="biriscv"

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

    local SRC_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/src")
    
    incs+=("-I${SRC_DIR}/core")
    
    local current_files=()
    while IFS= read -r -d '' file; do
        if [[ "$(wc -c < "$file")" -gt 1 ]]; then
            current_files+=("$(realpath "$file")")
        fi
    done < <(find "$SRC_DIR" -name "*.v" -print0)

    if (( ${#current_files[@]} > 0 )); then
        tops+=("riscv_top")
        fileSets+=("$(printf "%q " "${current_files[@]}")")
    fi
}