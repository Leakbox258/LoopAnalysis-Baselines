#!/bin/bash

set -euo pipefail

PROJECT_NAME="hazard3"

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

collectWithTopVerilator() {
    collectWithTop "$1" "$2" "$3" "$4" "$5"
}

collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3
    local -n incs=$5

    local BASE=$(realpath "${PROJECTS}/${PROJECT_NAME}/hdl")
    local current_files=()

    for d in "$BASE" "${BASE}/arith"; do
        [ -d "$d" ] || continue
        while IFS= read -r -d '' f; do
            if [[ "$(wc -c < "$f")" -gt 1 ]]; then
                current_files+=("$f")
            fi
        done < <(find "$d" -maxdepth 1 -name "*.v" -print0)
    done

    if (( ${#current_files[@]} > 0 )); then
        local file_list_str=$(printf "%q " "${current_files[@]}")

        tops+=("hazard3_cpu_1port")
        fileSets+=("$file_list_str")
        incs+=("-I$BASE")

        tops+=("hazard3_cpu_2port")
        fileSets+=("$file_list_str")
        incs+=("-I$BASE")
    fi
}