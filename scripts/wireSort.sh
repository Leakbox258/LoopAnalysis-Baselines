#!/bin/bash

set -euo pipefail

BUILD="./build"
PYTHON3=/usr/bin/python3

count_project_source_lines() {
	local total_lines=0
	local -A seen_files=()
	local file_set

	for file_set in "$@"; do
		local files=()
		eval "files=( ${file_set} )"

		for file in "${files[@]}"; do
			if [[ -n ${seen_files["$file"]+x} ]]; then
				continue
			fi

			seen_files["$file"]=1
			total_lines=$(( total_lines + $(wc -l < "$file") ))
		done
	done

	printf "%d\n" "$total_lines"
}

printTestScope() {
	SCRIPTS_PATH=$1
	local -n projects=$2
	for boot in "$SCRIPTS_PATH"/projects/*.sh; do
		source "$boot"
		
		if qualify "eval-wiresort"; then
			projects+=("$(basename "$boot" .sh)")
		fi
	done
}

wireSortEval() {
	PYRTL_PACKAGE_PATH=$1
	WIRE_SORT_SCRIPT=$2
	YOSYS=$3
	PROJECTS_PATH=$4
	declare -n EVAL_PROJECT=$5
	badConnectionNum=0 # module-port level
	timeConsume=0 # ms
	report="TopName    Project    BadConn    Time(ms)    SourceFileLines"

	for boot in "${EVAL_PROJECT[@]}"; do
		source "$boot"

		echo "Evaluation on ${boot}" 1>&2

		if ! qualify "eval-wiresort"; then
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

		projectSourceLines=$(count_project_source_lines "${fileCollection[@]}")

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
            blif="${BUILD}/blif/${project_name}_${top}.blif"
            tmp_ys="${BUILD}/yosys/${project_name}_blifgen_${top}.ys"

            mkdir -p "${BUILD}/blif" "${BUILD}/yosys"

            {
                # echo "plugin -i ${BUILD}/slang.so"
                # echo "read_slang --ignore-timing ${definitions[*]} ${includes[*]} ${files[*]}"
                
				echo "verilog_defaults -add -sv"

				for def in "${definitions[@]}"; do
					echo "verilog_defaults -add $def"
				done

				for inc in "${includes[@]}"; do
					echo "verilog_defaults -add $inc"
				done

				echo "read_verilog ${files[*]}"

				echo "hierarchy -check -top ${top}"

				echo "proc; memory;"

                echo "select -set original_clks w:*clk*"
                echo "rename -enumerate -pattern %_net original_clks"

                echo "write_blif ${blif}"
            } > "$tmp_ys"

            if [[ ! -f $blif ]]; then
                printf "Generating Single BLIF for %s ...\n" "${top}" 1>&2
                ${YOSYS} -q -s "$tmp_ys" 2> /dev/null
            else
                printf "Found BLIF for %s, skipping...\n" "${top}" 1>&2
            fi
        

			wireSortOutput=$(${PYTHON3} "${WIRE_SORT_SCRIPT}" \
										"${PYRTL_PACKAGE_PATH}" "${blif}")

			badConnections=$(echo "$wireSortOutput" | awk '/find Bad Connection Counts: / {print $NF}')
			consume=$(( $(echo "$wireSortOutput" | awk '/Time Consume: / {print $3}') / 1000000 ))

			echo "$wireSortOutput" 1>&2

			badConnectionNum=$(( badConnectionNum + badConnections ))
			timeConsume=$(( timeConsume + consume ))
			report=$(printf "%s\n%s\t%s\t%d\t%d\t%d\t" "$report" "$top" "$project_name" "$badConnections" "$consume" "$projectSourceLines")
		done
	done

	# printf "Wire Sort find %d bad connections in %d ms\n" "$badConnectionNum" "$timeConsume"

	printf "%s\n" "$report"
}
