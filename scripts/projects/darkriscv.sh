#!/bin/bash

set -euo pipefail

PROJECT_NAME="darkriscv"
VERILOG_FILES=(
	rtl/darksocv.v
  	rtl/darkbridge.v 
  	rtl/darkuart.v   
  	rtl/darkriscv.v  
  	rtl/darkpll.v    
  	rtl/darkram.v    
  	rtl/darkio.v     
  	rtl/darkcache.v
  )

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	pushd "${PROJECTS}/${PROJECT_NAME}"> /dev/null
	tops[${#tops[@]}]="darkriscv"
	hdls=()
	for file in "${VERILOG_FILES[@]}"; do
		hdls[${#hdls[@]}]="$(pwd)/${file}"
	done
	fileSets[${#fileSets[@]}]="${hdls[*]}"
	popd > /dev/null
}