#!/bin/bash

set -euo pipefail

PROJECTS=./3rd-party/projects

for boot in ./scripts/projects/*.sh; do
	source "$boot"
	fileCollection=()
	topCollection=()
	definitions=()
	includes=()

	echo "collecting files from ${boot}"

	collectWithTop  "$PROJECTS" \
					fileCollection \
					topCollection \
					definitions \
					includes

	for (( i=0; i<${#fileCollection[@]}; i++)); do
		printf "top: %s\nsource: %s\n" "${topCollection[i]}" "${fileCollection[i]}"
	done
	printf "defs: %s\nincs: %s\n" "${definitions[*]}" "${includes[*]}"

done