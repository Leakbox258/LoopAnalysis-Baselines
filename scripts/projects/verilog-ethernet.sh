#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-ethernet"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="verilog_ethernet"
	source=$(find ./lib/axis/rtl/ ./rtl/ -name "*.v" \
						| awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')

	fileSets[${#fileSets[@]}]="$source"
	popd > /dev/null
}