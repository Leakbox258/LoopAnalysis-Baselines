#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-ethernet"

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