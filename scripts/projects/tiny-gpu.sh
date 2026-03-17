#!/bin/bash

set -euo pipefail

PROJECT_NAME="tiny-gpu"

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

	local SRC_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/src")
	pushd "$SRC_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find "." -name "*.sv" -print0)

	if (( ${#current_files[@]} > 0 )); then
		tops+=("${PROJECT_NAME}")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi
	popd > /dev/null
}