#!/bin/bash

set -euo pipefail

PROJECT_NAME="32-Verilog-Mini-Projects"

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


collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3

    local ROOT_DIR
    ROOT_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}")

    while IFS= read -r -d '' dir; do
        local abs_dir
        abs_dir=$(realpath "$dir")
        
        local current_file_list=()
        while IFS= read -r -d '' file; do
			if [[ "$(wc -c < "$file")" -gt 1 ]]; then
    			current_file_list+=("$file")
			fi
        done < <(find "$abs_dir" -maxdepth 1 -name "*.v" ! -name "*_tb*" ! -name "test_*" -print0)

        if (( ${#current_file_list[@]} == 0 )); then
            continue
        fi

        fileSets+=( "$(printf "%q " "${current_file_list[@]}")" )

        local rel_path="$(basename "$abs_dir")"
        local top_name="${rel_path// /_}"
        tops+=( "$top_name" )

    done < <(find "$ROOT_DIR" -maxdepth 2 -type d ! -path "$ROOT_DIR" ! -path "*.git*" -print0)
}