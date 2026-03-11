#!/bin/bash

set -euo pipefail

yosysEval() {
	YOSYS=$2
	PROJECTS=$3
	sccNum=0 # on netlist
	timeConsume=0 # ms
	report="TopName\tSCCNum\tTime(ms)"
	
	for boot in "$PROJECTS"/projects/*sh; do
		source "$boot"
		fileCollection=()
		topCollection=()

		collectWithTop "$PROJECTS" "$fileCollection" "$topCollection"
		
		sizeFiles=${#fileCollection[@]}
		sizeTops=${#topCollection[@]}

		if [ "$sizeFiles" -ne "$sizeTops" ]; then
			echo "size of file collection don't match size of top collection"
		fi

		for (( i=0; i<"$sizeFiles"; i++ )); do
			top=${topCollection[i]}
			files=${fileCollection[i]}

			begin=$(date "+%s%N")
			yosysOutput=$(${YOSYS} -p "read_verilog -sv ${files}; hierarchy -check -top ${top}; proc; scc")
			end=$(date "+%s%N")

			consume=$(( end - begin ))
			yosysSCCNum=$(echo "$yosysOutput" | grep -E "Found [0-9]+ SCCs." | awk '{print $2}')
	
			sccNum=$(( sccNum + yosysSCCNum ))
			timeConsume=$(( timeConsume + consume ))
			report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$yosysSCCNum" "$consume")
		done
	done

	printf "Yosys find %d SCCs in %d ms" "$sccNum" "$timeConsume"
	printf "%s\n" "$report"
}