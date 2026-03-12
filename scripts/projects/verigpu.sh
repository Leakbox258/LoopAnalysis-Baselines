#!/bin/bash

set -euo pipefail

PROJECT_NAME="verigpu"

preprocess() {
	PROJECTS=$1
  
	if [[ -e build/verigpu ]]; then
		if (( $(wc build/verigpu -l) == 6161 )); then # 6162 with last '\n'
			return
		fi
	fi

  	cat > "build/verigpu_params.sv" << 'EOF'
parameter pos_width = $clog2(data_width);
parameter adder_width = 32;
parameter half_width = adder_width / 2;
parameter width = 32;
EOF

	# shellcheck disable=SC2046
  	cat \
		"${PROJECTS}/${PROJECT_NAME}/src/const.sv" \
		"build/verigpu_params.sv" \
		"${PROJECTS}/${PROJECT_NAME}/src/op_const.sv" \
		"${PROJECTS}/${PROJECT_NAME}/src/assert.sv" \
		"${PROJECTS}/${PROJECT_NAME}/src/float/float_params.sv" \
		"${PROJECTS}/${PROJECT_NAME}/src/mem_large.sv" \
		$(find "${PROJECTS}/${PROJECT_NAME}/src/" -name '*.sv' \
												! -name 'const.sv' \
												! -name 'op_const.sv' \
												! -name 'assert.sv' \
												! -name "float_params.sv" \
												! -name "mem_*" \
			) \
	> build/verigpu.sv
}

collectWithTop() {
	PROJECTS=$1
	declare -n fileSets=$2
	declare -n tops=$3

	preprocess "${PROJECTS}"

	tops[${tops[@]}]="verigpu"
	fileSets[${fileSets[@]}]="build/verigpu.sv"
}