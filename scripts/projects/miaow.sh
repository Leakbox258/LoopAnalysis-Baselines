#!/bin/bash

set -euo pipefail

PROJECT_NAME="miaow"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/src/verilog/rtl" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="miaow"
	source=()
	while read -r dir; do
		pushd "$dir" > /dev/null

		path=$(pwd)
		for hdl in ./*.v; do
			if [[ $hdl =~ (.*_tb.* | .*compute_unit_fpga.*) ]]; then
				continue
			fi
			source+=("$(echo "$hdl" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')")
		done
		popd > /dev/null
	done < <(find . -type d ! -path . )

	fileSets+=("${source[*]}")
	popd > /dev/null
}