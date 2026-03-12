#!/bin/bash

set -euo pipefail

PROJECT_NAME="hazard3"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3
	declare -n incs=$5

	pushd "${PROJECTS}/${PROJECT_NAME}/hdl" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="hazard3"
	source=()
	for hdl in ./*.v; do
		source+=("$(echo "$hdl" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')")
	done

	pushd ./arith > /dev/null
	path=$(pwd)

	for hdl in ./*.v; do
		source+=("$(echo "$hdl" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')")
	done

	popd > /dev/null

	fileSets[${#fileSets[@]}]="${source[*]}"
	incs[${#incs[@]}]="-I${PROJECTS}/${PROJECT_NAME}/hdl"
	popd > /dev/null
}