#!/bin/bash

set -euo pipefail

PROJECT_NAME="32-Verilog-Mini-Projects"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}" > /dev/null
	
	while read -r dir; do
		pushd "$dir" > /dev/null
		path=$(pwd)
		verilog_files=$(find . -maxdepth 1 -name "*.v" ! -name "*_tb*" ! -name "test_*" \
							| awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')
		
		if [[ ! -n $verilog_files ]]; then
			popd > /dev/null
			continue
		fi
		
		top="${dir// /_}"
		tops[${#tops[@]}]="${top#./}"
		fileSets[${#fileSets[@]}]=$verilog_files
		popd > /dev/null
  	done < <(find . -maxdepth 2 -type d ! -path . ! -path "*.git*")

	echo "${#fileSets[@]}"

	popd > /dev/null
}