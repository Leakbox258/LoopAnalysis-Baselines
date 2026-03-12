#!/bin/bash

set -euo pipefail

PROJECT_NAME="basic_verilog"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}" > /dev/null
	for hdl in $(ls | grep -E '.sv$' | grep -Ev '_tb|_gen'); do
		tops[${#tops[@]}]="${hdl%.*}"
		fileSets[${#fileSets[@]}]="$(pwd)/${hdl}"
	done
	popd > /dev/null
}