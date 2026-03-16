#!/bin/bash

set -euo pipefail

BUILD="./build"

yosysEval() {
	YOSYS=$1
	PROJECTS=$2
	sccNum=0 # on netlist
	timeConsume=0 # ms
	report="TopName\tSCCNum\tTime(ms)"
	
	for boot in scripts/projects/*sh; do
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

		quoted_includes=""
		for inc in "${includes[@]}"; do
			quoted_includes+=" \"$inc\""
		done

		quoted_definitions=""
		for def in "${definitions[@]}"; do
			quoted_definitions+=" \"$def\""
		done

		for (( i=0; i<"$sizeFiles"; i++ )); do
			eval "files=( ${fileCollection[$i]} )"
			top=${topCollection[i]}
			
			echo "$top" 1>&2
			tmp_ys="${BUILD}/yosys_${top}_${i}.ys"
			touch "$tmp_ys"

		{
			echo "verilog_defaults -add -sv"

			for def in "${definitions[@]}"; do
				echo "verilog_defaults -add $def"
			done

			for inc in "${includes[@]}"; do
				echo "verilog_defaults -add $inc"
			done

			for f in "${files[@]}"; do
				echo "read_verilog \"$f\""
			done

			echo "hierarchy -check -auto-top"
			echo "proc"
			echo "scc"
		} > "$tmp_ys"

			begin=$(date "+%s%N")
			
			echo "Running Yosys script: $tmp_ys" 1>&2
			yosysOutput=$(${YOSYS} -s "$tmp_ys")
			end=$(date "+%s%N")

			consume=$(( end - begin ))
			yosysSCCNum=$(echo "$yosysOutput" | awk '/Found [0-9]+ SCCs/ {sum += "$2"} END {print sum}')

			sccNum=$(( sccNum + yosysSCCNum ))
			timeConsume=$(( timeConsume + consume ))

			echo "$yosysOutput" > "${BUILD}/yosys_${top}_${i}.out"

			report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$yosysSCCNum" "$consume")
		done
	done

	printf "Yosys find %d SCCs in %d ms" "$sccNum" "$timeConsume"
	printf "%s\n" "$report"
}

yosysEvalOne() {
	YOSYS=$1
	PROJECTS=$2
	PROJECT_NAME=$3
	sccNum=0 # on netlist
	timeConsume=0 # ms
	report="TopName\tSCCNum\tTime(ms)"
	
	source "scripts/projects/${PROJECT_NAME}.sh"
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

	quoted_includes=""
	for inc in "${includes[@]}"; do
		quoted_includes+=" \"$inc\""
	done

	quoted_definitions=""
	for def in "${definitions[@]}"; do
		quoted_definitions+=" \"$def\""
	done

	for (( i=0; i<"$sizeFiles"; i++ )); do
		eval "files=( ${fileCollection[$i]} )"
		top=${topCollection[i]}
		
		echo "$top" 1>&2
		tmp_ys="${BUILD}/yosys_${top}_${i}.ys"
		touch "$tmp_ys"

	{
		echo "verilog_defaults -add -sv"

		for def in "${definitions[@]}"; do
			echo "verilog_defaults -add $def"
		done

		for inc in "${includes[@]}"; do
			echo "verilog_defaults -add $inc"
		done

		for f in "${files[@]}"; do
			echo "read_verilog \"$f\""
		done

		echo "hierarchy -check -auto-top"
		echo "proc"
		echo "scc"
	} > "$tmp_ys"

		begin=$(date "+%s%N")
		
		echo "Running Yosys script: $tmp_ys" 1>&2
		yosysOutput=$(${YOSYS} -s "$tmp_ys")
		end=$(date "+%s%N")

		consume=$(( end - begin ))
		yosysSCCNum=$(echo "$yosysOutput" | awk '/Found [0-9]+ SCCs/ {sum += "$2"} END {print sum}')

		sccNum=$(( sccNum + yosysSCCNum ))
		timeConsume=$(( timeConsume + consume ))

		echo "$yosysOutput" > "${BUILD}/yosys_${top}_${i}.out"

		report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$yosysSCCNum" "$consume")
	done

	printf "Yosys find %d SCCs in %d ms\n" "$sccNum" "$timeConsume"
	printf "%s\n" "$report"
}