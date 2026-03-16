#!/bin/bash

set -euo pipefail

verilatorEval() {
	VERILATOR=$1
	PROJECTS_PATH=$2
	local -n EVAL_PROJECT=$3
	sccNum=0 # Data/AstNode level SCC
	timeConsume=0 # ms
	report="TopName    SCC    Time(ms)"

	for boot in "${EVAL_PROJECT[@]}"; do
		source "$boot"

		echo "Evaluation on ${boot}" 1>&2

		fileCollection=()
		topCollection=()
		definitions=()
		includes=()

		collectWithTop  "$PROJECTS_PATH" \
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
			eval "files=( ${fileCollection[$i]} )"
			top=${topCollection[i]}
			
			begin=$(date '+%s%N')
			SCC=$(${VERILATOR} --lint-only --stats \
								--Wwarn-ASSIGNIN \
								--Wwarn-MODMISSING \
								-Wno-fatal \
								-Wno-ZEROREPL \
								-Wno-PINNOTFOUND \
								"${incs[@]}" \
								"${defs[@]}" \
								"${files[@]}" \
								2>&1 \
								| awk '/Find SCC: / {print $NF}')

			end=$(date '+%s%N')
			consume=$(( (end - begin) / 1000000 ))
			timeConsume=$(( timeConsume + consume ))

			if [[ -z "$SCC" ]]; then
				SCC=0
			fi

			sccNum=$(( sccNum + SCC ))
			report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$SCC" "$consume")
		done
	done

	printf "Verilator5.0 find %d SCCs in %d ms\n" "$sccNum" "$timeConsume"
	printf "%s\n" "$report"
}
