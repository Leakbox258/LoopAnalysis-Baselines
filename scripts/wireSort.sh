#!/bin/bash

set -euo pipefail

wireSortEval() {
	PYRTL_PACKAGE_PATH=$1
	WIRE_SORT_SCRIPT=$2
	YOSYS=$3
	PROJECTS=$4
	PYTHON3=/usr/bin/python3
	badConnectionNum=0 # module-port level
	timeConsume=0 # ms
	report="TopName\tSCC\tTime(ms)"

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
			blif="${top}.blif"

			begin=$(date "+%s%N")
			${YOSYS} -p "read_verilog -sv ${files}; hierarchy -check -top ${top}; synth; write_blif ${blif}"
			end=$(date "+%s%N")

			badConnections="${PYTHON3} ${WIRE_SORT_SCRIPT} ${PYRTL_PACKAGE_PATH} ${blif}"
			consume=$(( end - begin ))

			badConnectionNum=$(( badConnectionNum + badConnections ))
			timeConsume=$(( timeConsume + consume ))
			report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$badConnections" "$consume")
		done
	done

	printf "Wire Sort find %d bad connections in %d ms" "$badConnectionNum" "$timeConsume"
	printf "%s\n" "$report"
}