#!/bin/bash

set -euo pipefail

PROJECT_NAME="serv"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/rtl" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="serv"
	source=$(find "." -name "*.v" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')

	fileSets[${#fileSets[@]}]="$source"
	popd > /dev/null
}