#!/bin/bash

set -euo pipefail

PYRTL_PACKAGE_PATH=$(find ./3rd-party -name "pyrtl-*.egg" -type d -o -name "pyrtl-*.egg" -type f | head -n 1)

if [[ $PYRTL_PACKAGE_PATH == "" ]]; then
	printf "Didn't find pyrtl package, run setup.sh to build and install.\n"
	exit 1
fi

VERILATOR=./3rd-party/analyzer/verilator/build/bin/verilator

if command -v "$($VERILATOR --help)" &> /dev/null; then
	printf "Didn't find built verilator, run setup.sh to build.\n"
	exit 1
fi

PROJECTS=./3rd-party/projects

args=("$@")
modes=()
contain_projects=()
skip_projects=()
yosys="yosys"

current_opt=""
for (( i=0; i<"${#args[@]}"; i+=1 )); do
	arg=${args[$i]}
	
	if [[ $arg == "--help" || $arg == "-h" ]]; then
		printf "Usage: %s [OPTIONS]\n" "$0"
        printf "Options:\n"
        printf "  -h, --help             Show this help message and exit\n"
        printf "  --skip <project>       Add a project to the skip list (can be used multiple times)\n"
        printf "  --mode <mode>          Specify run modes: eval-verilator, eval-wiresort, eval-yosys, eval-all\n"
        printf "  --projects <project>   Specify certain projects to run\n"
        printf "  --yosys <path>         Path to your yosys executable\n"
        exit 0
	fi


	if [[ $arg =~ --.* ]]; then
		# if [[ $current_opt != "" ]]; then
		# 	printf "Error: Option [%s] wasn't given.\n" "$current_opt"
		# 	exit 1
		# fi
		current_opt=$arg
	else
		case $current_opt in
		"--skip")
			skip_projects+=("$arg")
			;;
		"--mode")
			modes+=("$arg")
			;;
		"--projects")
			contain_projects+=("$arg")
			;;
		"--yosys")
			yosys="$arg"
			;;
		*)
			printf "Error: Unknown Option %s" "$current_opt"
			exit 1
		esac
	fi
done

# Get projects for evaluations
EVAL_PROJECTS=()

for script in ./scripts/projects/*.sh; do
	file=$(basename "$script")
	project=${file%.sh}
	
	skip=0
	contain=0
	for skipped in "${skip_projects[@]}"; do
		if [[ $skipped == "$project" ]]; then
			skip=1
			break
		fi
	done
	
	if (( ${#contain_projects[@]} == 0 )); then
		# Default as eval all
		contain=1
	else
		for contained in "${contain_projects[@]}"; do
			if [[ $contained == "$project" ]]; then
				contain=1
				break
			fi
		done
	fi

	if (( "$skip" == 0 && "$contain" == 1 )); then
		EVAL_PROJECTS+=("$script")
	fi
done

mkdir -p build/blif
mkdir -p build/yosys

verilatorReport=""
wireSortReport=""
yosysReport=""

for mode in "${modes[@]}"; do

	case $mode in
		"eval-verilator")
			source ./scripts/verilator5.0.sh
			verilatorReport+=$(verilatorEval "$VERILATOR"\
											 "$PROJECTS" \
											 EVAL_PROJECTS
											 )
			;;
		"eval-wiresort")
			source ./scripts/wireSort.sh
			wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" \
											"./scripts/implWireSort.py" \
											"$yosys" \
											"$PROJECTS" \
											EVAL_PROJECTS
											)
			;;
		"eval-yosys")
			source ./scripts/yosys.sh
			yosysReport+=$(yosysEval "$yosys" \
									"$PROJECTS" \
									EVAL_PROJECTS
									)
			;;
		"eval-all")
			source ./scripts/verilator5.0.sh
			source ./scripts/wireSort.sh
			source ./scripts/yosys.sh

			verilatorReport+=$(verilatorEval "$VERILATOR"\
											 "$PROJECTS" \
											 EVAL_PROJECTS
											 )
			wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" \
											"./scripts/wireSort.py" \
											"$yosys" \
											"$PROJECTS" \
											EVAL_PROJECTS
											)
			yosysReport+=$(yosysEval "$yosys" \
									"$PROJECTS" \
									EVAL_PROJECTS
									)
			;;
		*)
			echo "Mode Usage: $0 [eval-verilator|eval-wireSort|eval-yosys|eval-all]"
			exit 1
	esac
done

# Debug
printf "%s\n%s\n%s\n" "$verilatorReport" "$wireSortReport" "$yosysReport"