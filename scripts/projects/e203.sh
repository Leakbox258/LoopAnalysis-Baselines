#!/bin/bash

set -euo pipefail

PROJECT_NAME="e203"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3
	declare -n defs=$4
	declare -n incs=$5

	pushd "${PROJECTS}/${PROJECT_NAME}/rtl/e203" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="e203"
	source=$(find "." -name "*.v" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')
	
	fileSets[${#fileSets[@]}]="$source"
	defs[${#defs[@]}]="-DFPGA_SOURCE"
	incs[${#incs[@]}]="-I${PROJECTS}/${PROJECT_NAME}/rtl/e203/core"
	popd > /dev/null
}