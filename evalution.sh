#!/bin/bash

set -euo pipefail

PYRTL_PACKAGE_PATH=./3rd-party/analyzer/WireSorts/build/lib/pyrtl
VERILATOR=./3rd-party/analyzer/verilator/build/bin/verilator
YOSYS=yosys
PROJECTS=./3rd-party/projects

command=$1
certain_project=$2
verilatorReport=""
wireSortReport=""
yosysReport=""

case $command in
	"eval-verilator")
		source ./scripts/verilator5.0.sh
		if [[ ! -z "$certain_project" ]]; then
			verilatorReport+=$(verilatorEvalOne "$VERILATOR" \
												"$PROJECTS" \
												"$certain_project")
		else
			verilatorReport+=$(verilatorEval "$VERILATOR" "$PROJECTS")
		fi
		;;
	"eval-wiresort")
		source ./scripts/wireSort.sh
		if [[ ! -z "$certain_project" ]]; then
		wireSortReport+=$(wireSortEvalOne "$PYRTL_PACKAGE_PATH" \
										"scripts/wireSort.py" \
										"$YOSYS" \
										"$PROJECTS" \
										"$certain_project")
		else
		wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" \
										"./scripts/wireSort.py" \
										"$YOSYS" \
										"$PROJECTS")
		fi
		;;
	"eval-yosys")
		source ./scripts/yosys.sh
		if [[ ! -z "$certain_project" ]]; then
			yosysReport+=$(yosysEvalOne "$YOSYS" "$PROJECTS" "$certain_project")
		else
			yosysReport+=$(yosysEval "$YOSYS" "$PROJECTS")
		fi
		;;
	"eval-all")
		source ./scripts/verilator5.0.sh
		source ./scripts/wireSort.sh
		source ./scripts/yosys.sh
		verilatorReport+=$(verilatorEval "$VERILATOR" "$PROJECTS")
		wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" "./scripts/wireSort.py" "$YOSYS" "$PROJECTS")
		yosysReport+=$(yosysEval "$YOSYS" "$PROJECTS")
		;;
	*)
		echo "Usage: $0 [eval-verilator|eval-wireSort|eval-yosys|eval-all]"
		exit 1
esac

# Debug
printf "%s\n%s\n%s\n" "$verilatorReport" "$wireSortReport" "$yosysReport"