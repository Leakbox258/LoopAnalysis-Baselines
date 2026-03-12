#!/bin/bash

set -euo pipefail

PROJECT_NAME="hdmi"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/src" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="hdmi"
	source=$(find "." -name "*.sv" | awk -v pwd="$path" '{printf "%s/%s ", pwd, $1}')

	fileSets[${#fileSets[@]}]="$source"
	popd > /dev/null
}