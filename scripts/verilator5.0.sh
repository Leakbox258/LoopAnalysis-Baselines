#!/bin/bash

set -euo pipefail

verilatorEval() {
	VERILATOR=$1
	PROJECTS=$2
	sccNum=0 # Data/AstNode level SCC
	timeConsume=0 # ms
	report="TopName\tSCC\tTime(ms)"

	for boot in "$PROJECTS"/*.sh; do
		source "$boot"
		fileCollection=()
		topCollection=()
		definitions=()
		includes=()

		collectWithTop  "$PROJECTS" \
						fileCollection \
						topCollection \
						definitions \
						includes
		
		sizeFiles=${#fileCollection[@]}
		sizeTops=${#topCollection[@]}

		if [ "$sizeFiles" -ne "$sizeTops" ]; then
			echo "size of file collection don't match size of top collection"
		fi

		for (( i=0; i<"$sizeFiles"; i++ )); do
			file=${fileCollection[i]}
			top=${topCollection[i]}
			
			begin=$(date '+%s%N')
			SCC=$(${VERILATOR} --lint-only --stats \
								"${definitions[*]}" \
								"${includes[*]}" \
								"${file}" | awk '/Find SCC: / {print $NF}')
			end=$(date '+%s%N')
			consume=$(( (end - begin) / 1000_000 ))

			timeConsume=$(( timeConsume + consume ))
			sccNum=$(( sccNum + SCC ))
			report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$SCC" "$consume")
		done
	done

	printf "Verilator5.0 find %d SCCs in %d ms\n" "$sccNum" "$timeConsume"
	printf "%s\n" "$report"
}
