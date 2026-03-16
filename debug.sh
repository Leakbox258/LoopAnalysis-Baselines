#!/bin/bash

set -euo pipefail

certain_project=$1
PROJECTS=./3rd-party/projects

if [[ ! -z $1 ]]; then
	source "./scripts/projects/${certain_project}.sh"
			fileCollection=()
			topCollection=()
			definitions=()
			includes=()

			echo "collecting files from ${certain_project}.sh"

			collectWithTop  "$PROJECTS" \
							fileCollection \
							topCollection \
							definitions \
							includes

			for (( i=0; i<${#fileCollection[@]}; i++)); do
				printf "top: %s\nsource: %s\n" "${topCollection[i]}" "${fileCollection[i]}"
			done
			printf "defs: %s\nincs: %s\n" "${definitions[*]}" "${includes[*]}"
else 
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
fi
