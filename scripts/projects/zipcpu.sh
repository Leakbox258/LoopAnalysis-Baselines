#!/bin/bash

set -euo pipefail

PROJECT_NAME="zipcpu"

# find -wholename has to begin with './'
VERILOG_FILES=(
	./zipsystem.v 
  	./core/*.v 
  	./zipdma/*.v 
  	./ex/*.v 
  	./peripherals/*.v
  )

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}/rtl" > /dev/null
	path=$(pwd)
	
	tops[${#tops[@]}]="zipcpu"

	source=()
	for regex in "${VERILOG_FILES[@]}"; do
		source+=("$(find . -wholename "${regex}" | awk -v pwd="$path" '{printf "%s/%s", pwd, $1}' )")
	done

	fileSets[${#fileSets[@]}]="${source[*]}"
	popd > /dev/null
}