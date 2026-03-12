#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-axi"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/rtl" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="verilog_axi"
	source=$(find "." -name "*.v" \
  						! -name "*adapter*.v" \
  						! -name "*vfifo*.v" \
						| awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')

	fileSets[${#fileSets[@]}]="$source"
	popd > /dev/null
}