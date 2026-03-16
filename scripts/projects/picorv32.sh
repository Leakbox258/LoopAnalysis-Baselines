#!/bin/bash

set -euo pipefail

PROJECT_NAME="picorv32"

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