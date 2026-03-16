#!/bin/bash

set -euo pipefail

BUILD="./build"

wireSortEval() {
	PYRTL_PACKAGE_PATH=$1
	WIRE_SORT_SCRIPT=$2
	YOSYS=$3
	PROJECTS=$4
	PYTHON3=/usr/bin/python3
	badConnectionNum=0 # module-port level
	timeConsume=0 # ms
	report="TopName\tSCC\tTime(ms)"

	for boot in ./scripts/projects/*.sh; do
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
			blif="${top}.blif"
			
			echo "$top" 1>&2
			tmp_ys="${BUILD}/blifGen_${top}_${i}.ys"
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
				echo "synth"
				echo "write_blif ${blif}"
			} > "$tmp_ys"

			begin=$(date "+%s%N")
			# ${YOSYS} -p "read_verilog -sv ${definitions[*]} ${includes[*]} ${files}; \
			#  				hierarchy -check -auto-top; \
			# 				synth; \
			# 				write_blif ${blif}"
			${YOSYS} -s "$tmp_ys"
			badConnections="${PYTHON3} ${WIRE_SORT_SCRIPT} ${PYRTL_PACKAGE_PATH} ${blif}"
			end=$(date "+%s%N")

			consume=$(( end - begin ))

			badConnectionNum=$(( badConnectionNum + badConnections ))
			timeConsume=$(( timeConsume + consume ))
			report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$badConnections" "$consume")
		done
	done

	printf "Wire Sort find %d bad connections in %d ms" "$badConnectionNum" "$timeConsume"
	printf "%s\n" "$report"
}

wireSortEvalOne() {
	PYRTL_PACKAGE_PATH=$1
	WIRE_SORT_SCRIPT=$2
	YOSYS=$3
	PROJECTS=$4
	PROJECT_NAME=$5
	PYTHON3=/usr/bin/python3
	badConnectionNum=0 # module-port level
	timeConsume=0 # ms
	report="TopName\tSCC\tTime(ms)"

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
		blif="${top}.blif"
		
		echo "$top" 1>&2
		tmp_ys="${BUILD}/blifGen_${top}_${i}.ys"
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
			echo "synth"
			echo "write_blif ${blif}"
		} > "$tmp_ys"

		begin=$(date "+%s%N")
		# ${YOSYS} -p "read_verilog -sv ${definitions[*]} ${includes[*]} ${files}; \
		#  				hierarchy -check -auto-top; \
		# 				synth; \
		# 				write_blif ${blif}"
		${YOSYS} -s "$tmp_ys"
		badConnections="${PYTHON3} ${WIRE_SORT_SCRIPT} ${PYRTL_PACKAGE_PATH} ${blif}"
		end=$(date "+%s%N")

		consume=$(( end - begin ))

		badConnectionNum=$(( badConnectionNum + badConnections ))
		timeConsume=$(( timeConsume + consume ))
		report=$(printf "%s\n%s\t%d\t%d\t" "$report" "$top" "$badConnections" "$consume")
	done

	printf "Wire Sort find %d bad connections in %d ms" "$badConnectionNum" "$timeConsume"
	printf "%s\n" "$report"
}