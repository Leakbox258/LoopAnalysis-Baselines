#!/bin/bash

set -euo pipefail

PROJECT_NAME="picorv32"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="picorv32"
	fileSets[${#fileSets[@]}]="${path}/picorv32.v"
	popd > /dev/null
}
