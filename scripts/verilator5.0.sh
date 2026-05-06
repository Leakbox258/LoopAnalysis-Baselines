#!/bin/bash

set -euo pipefail

count_project_source_lines() {
	local total_lines=0
	local file

	for file in "$@"; do
		total_lines=$(( total_lines + $(wc -l < "$file") ))
	done

	printf "%d\n" "$total_lines"
}

printTestScope() {
	SCRIPTS_PATH=$1
	local -n projects=$2
	for boot in "$SCRIPTS_PATH"/projects/*.sh; do
		source "$boot"
		
		if qualify "eval-verilator"; then
			projects+=("$(basename "$boot" .sh)")
		fi
	done
}

verilatorEval() {

	VERILATOR=$1
	PROJECTS_PATH=$2
	local -n EVAL_PROJECT=$3
	sccNum=0 # Data/AstNode level SCC
	timeConsume=0 # ms
	report="TopName    Project    SCC    Time(ms)    SourceFileLines"

	for boot in "${EVAL_PROJECT[@]}"; do
		source "$boot"

		echo "Evaluation on ${boot}" 1>&2

		if ! qualify "eval-verilator"; then
			echo "Skip evaluation on ${boot}" 1>&2
			continue
		fi

		basename=$(basename "$boot")
		project_name=${basename%.sh}

		fileCollection=()
		topCollection=()
		definitions=()
		includes=()

		collectWithTopVerilator  "$PROJECTS_PATH" \
						fileCollection \
						topCollection \
						definitions \
						includes
		
		sizeFiles=${#fileCollection[@]}
		sizeTops=${#topCollection[@]}

		if [ "$sizeFiles" -ne "$sizeTops" ]; then
			echo "size of file collection don't match size of top collection"
		fi

		eval "incs=( ${includes[*]})"
		eval "defs=( ${definitions[*]})"
		for (( i=0; i<"$sizeFiles"; i++ )); do
			eval "files=( ${fileCollection[$i]} )"
			top=${topCollection[i]}
			projectSourceLines=$(count_project_source_lines "${files[@]}")
			
			begin=$(date '+%s%N')
			verilatorOutput=$(${VERILATOR} --lint-only --stats --debug \
									--Wwarn-ASSIGNIN --Wwarn-MODMISSING -Wno-fatal -Wno-ZEROREPL -Wno-PINNOTFOUND \
									"${incs[@]}" \
									"${defs[@]}" \
									"${files[@]}" 2>&1)
			SCC=$(echo "$verilatorOutput" | awk '
				/UnOptimized: Find [0-9]+ SCCs/ {
					for (i = 1; i < NF; ++i) {
						if ($i == "Find" && $(i + 1) ~ /^[0-9]+$/) {
							sum += $(i + 1)
						}
					}
				}
				END { print sum + 0 }')

			end=$(date '+%s%N')
			consume=$(( (end - begin) / 1000000 ))
			timeConsume=$(( timeConsume + consume ))

			sccNum=$(( sccNum + SCC ))
			report=$(printf "%s\n%s\t%s\t%d\t%d\t%d\t" "$report" "$top" "$project_name" "$SCC" "$consume" "$projectSourceLines")
		done
	done

	# printf "Verilator5.0 find %d SCCs in %d ms\n" "$sccNum" "$timeConsume"

	printf "%s\n" "$report"
}
