#!/bin/bash

set -euo pipefail

BUILD="./build"

printTestScope() {
	SCRIPTS_PATH=$1
	local -n projects=$2
	for boot in "$SCRIPTS_PATH"/projects/*.sh; do
		source "$boot"

		if qualify "eval-yosys"; then
			projects+=("$(basename "$boot" .sh)")
		fi
	done
}

yosysEval() {
	YOSYS=$1
	PROJECTS_PATH=$2
	local -n EVAL_PROJECT=$3
	sccNum=0 # on netlist
	timeConsume=0 # ms
	report="TopName    Project    SCCNum    Time(ms)"
	
	for boot in "${EVAL_PROJECT[@]}"; do
		source "$boot"

		echo "Evaluation on ${boot}" 1>&2

		if ! qualify "eval-yosys"; then
			echo "Skip evaluation on ${boot}" 1>&2
			continue
		fi

		basename=$(basename "$boot")
		project_name=${basename%.sh}

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
			
			tmp_ys="${BUILD}/yosys/${project_name}_yosys_${top}_${i}.ys"
			touch "$tmp_ys"

		{

			# Deprecated, read_slang will force flatten design after reading
			# echo "verilog_defaults -add -sv"

			# for def in "${definitions[@]}"; do
			# 	echo "verilog_defaults -add $def"
			# done

			# for inc in "${includes[@]}"; do
			# 	echo "verilog_defaults -add $inc"
			# done

			echo "plugin -i ${BUILD}/slang.so"
			echo "read_slang --ignore-timing ${definitions[*]} ${includes[*]} ${files[*]}"
			echo "hierarchy -check -auto-top" # use -auto-top for an overall checking
			echo "flatten" # https://github.com/YosysHQ/yosys/issues/3411
			echo "scc"
		} > "$tmp_ys"

			begin=$(date "+%s%N")
			
			echo "Running Yosys script: $tmp_ys" 1>&2
			yosysOutput=$(${YOSYS} -s "$tmp_ys" 2> /dev/null)
			end=$(date "+%s%N")

			consume=$(( (end - begin) / 1000000 ))
			yosysSCCNum=$(echo "$yosysOutput" | awk '/Found [0-9]+ SCCs in module/ {sum += $2} END {print sum+0}')

			sccNum=$(( sccNum + yosysSCCNum ))
			timeConsume=$(( timeConsume + consume ))

			echo "$yosysOutput" > "${BUILD}/yosys_out/${project_name}_yosys_${top}_${i}.out"

			report=$(printf "%s\n%s\t%s\t%d\t%d\t" "$report" "$top" "$project_name" "$yosysSCCNum" "$consume")
		done
	done

	# printf "Yosys find %d SCCs in %d ms\n" "$sccNum" "$timeConsume"

	printf "%s\n" "$report"
}
