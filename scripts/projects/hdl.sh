#!/bin/bash

set -euo pipefail

PROJECT_NAME="hdl"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/library" > /dev/null
	
	while read -r dir; do
		pushd "$dir" > /dev/null
		
		path=$(pwd)
		source=()
		for hdl in ./*.v; do
			if [[ $hdl =~ (.*_tb.* | .*tb_.*) ]]; then
				continue
			fi

			if [[ ! -f $hdl ]]; then
				continue
			fi
			
			source+=("$(echo "$hdl" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')")
		done

		if (( ${#source[@]} != 0 )); then
			top_name=${dir#./}
			tops+=("${top_name////_}")
			fileSets+=("${source[*]}")
		fi
		
		popd > /dev/null
	done < <(find . -type d ! -path . \
							! -path "*/tb/*" \
							! -path "*/intel/*" \
							! -path "*xilinx/axi_adcfifo*"  \
							! -path "*jesd204*" \
							! -path "*corundum*"
							)
	popd > /dev/null
}