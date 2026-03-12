#!/bin/bash

set -euo pipefail

PYRTL_PACKAGE_PATH=./3rd-party/analyzer/WireSorts/build/lib/pyrtl
VERILATOR=./3rd-party/analyzer/WireSorts/build/lib/pyrtl
YOSYS=yosys
PROJECTS=./3rd-party/projects

command=$1
verilatorReport=""
wireSortReport=""
yosysReport=""

case $command in
	"eval-verilator")
		source ./scripts/verilator5.0.sh
		verilatorReport+=$(verilatorEval "$VERILATOR" "$PROJECTS")
		;;
	"eval-wireSort")
		source ./scripts/wireSort.sh
		wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" "./scripts/wireSort.py" "$YOSYS" "$PROJECTS")
		;;
	"eval-yosys")
		source ./scripts/yosys.sh
		yosysReport+=$(yosysEval "$YOSYS" "$PROJECTS")
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