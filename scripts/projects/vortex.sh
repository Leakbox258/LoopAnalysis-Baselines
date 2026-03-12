#!/bin/bash

set -euo pipefail

PROJECT_NAME="vortex"

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3
	declare -n defs=$4
	declare -n incs=$5

	source=("$(find "${PROJECTS}/${PROJECT_NAME}/hw/rtl" -name "*.sv") \
				| awk '{printf "%s " $1}'")
	source+=("$(find "${PROJECTS}/${PROJECT_NAME}/third_party/hardfloat/source" \
					 -name "*.v" \
					 | grep -vE "8086|ARM") \
					 | awk '{printf "%s " $1}'")
	
	includes=()
	while IFS= read -r dir; do
		includes+=("-I" "$dir")
	done < <(find "${PROJECTS}/${PROJECT_NAME}/hw/rtl" \
					-name "*.vh" \
					-exec dirname {} \; \
					| sort -u \
					)

	while IFS= read -r dir; do
		includes+=("-I" "$dir")
	done < <(find "${PROJECTS}/${PROJECT_NAME}/third_party/hardfloat/source" \
					-name "*.vi" \
					-exec dirname {} \; \
					| sort -u \
					| grep -vE "8086|ARM" \
					)

	tops[${#tops[@]}]="vortex"
	fileSets[${#fileSets[@]}]="${source[*]}"
	defs[${#defs[@]}]="-DNOPAE -DEXT_TCU_ENABLE"
	incs[${#incs[@]}]="${includes[*]}"
}