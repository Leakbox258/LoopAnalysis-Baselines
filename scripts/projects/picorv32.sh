#!/bin/bash

set -euo pipefail

PROJECT_NAME="picorv32"

qualify() {
	mode=$1

	case $mode in
		"eval-verilator")
			return 0
			;;
		"eval-wiresort")
			return 0
			;;
		"eval-yosys")
			return 0
			;;
	esac
}

collectWithTop() {
	local PROJECTS=$1
	local -n fileSets=$2
	local -n tops=$3

	local TARGET_FILE=$(realpath "${PROJECTS}/${PROJECT_NAME}/picorv32.v")
	
	if [[ -f "$TARGET_FILE" && "$(wc -c < "$TARGET_FILE")" -gt 1 ]]; then
		tops+=("picorv32")
		fileSets+=("$(printf "%q " "$TARGET_FILE")")
	fi
}