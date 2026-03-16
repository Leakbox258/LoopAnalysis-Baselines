#!/bin/bash

set -euo pipefail

PROJECT_NAME="e203"

collectWithTop() {
	local PROJECTS=$1
	local -n fileSets=$2
	local -n tops=$3
	local -n defs=$4
	local -n incs=$5

	local RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl/e203")
	pushd "$RTL_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find "." -name "*.v" -print0)
	
	if (( ${#current_files[@]} > 0 )); then
		tops+=("e203")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		defs+=("-DFPGA_SOURCE")
		incs+=("-I$(realpath "core")")
		incs+=("-I$(realpath "perips/apb_i2c")")
	fi
	popd > /dev/null
}