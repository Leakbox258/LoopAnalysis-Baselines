#!/bin/bash

set -euo pipefail

PROJECT_NAME="biriscv"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/src" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="biriscv"
	source=$(find "." -name "*.v" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')

	fileSets[${#fileSets[@]}]="$source"
	popd > /dev/null
}