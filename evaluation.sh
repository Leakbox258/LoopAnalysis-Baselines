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
        printf "  --mode <mode>          Specify run modes: test-scope, eval-verilator, eval-wiresort, eval-yosys, eval-all\n"
        printf "  --projects <project>   Specify certain projects to run\n"
        printf "  --yosys <path>         Path to your yosys executable, if not specified, try use \`yosys\` as default \n"
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
		"--project")
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
		"test-scope")
			source ./scripts/verilator5.0.sh
			verilator_test_scope=()
			printTestScope "./scripts" verilator_test_scope
			printf "verilator test scope: %s\n" "${verilator_test_scope[*]}"

			source ./scripts/wireSort.sh
			wiresort_test_scope=()
			printTestScope "./scripts" wiresort_test_scope
			printf "verilator test scope: %s\n" "${wiresort_test_scope[*]}"

			source ./scripts/yosys.sh
			yosys_test_scope=()
			printTestScope "./scripts" yosys_test_scope
			printf "verilator test scope: %s\n" "${yosys_test_scope[*]}"

			exit 0
			;;
		*)
		
			echo "Mode Usage: $0 [eval-verilator|eval-wireSort|eval-yosys|eval-all]"
			exit 1
	esac
done

DATE=$(date +%Y-%m-%d-%H-%M)
REPORT_DIR="./report/${DATE}"

mkdir -p "$REPORT_DIR"

convert_to_md() {
    local raw_data="$1"
    local title="$2"
    local suffix="$3"
    
    if [[ -z "$(echo "$raw_data" | tr -d '[:space:]')" ]]; then
        return
    fi

    local output_file="${REPORT_DIR}/eval-${suffix}.md"
    local metric_header
    metric_header=$(echo "$raw_data" | awk 'NF { print $3; exit }')
    metric_header=${metric_header:-SCC}
    local source_lines_header
    source_lines_header=$(echo "$raw_data" | awk 'NF { print $5; exit }')
    source_lines_header=${source_lines_header:-SourceFileLines}
    
    {
        echo "# ${title} Evaluation Report (${DATE})"
        echo ""
        echo "| TopName | Project | ${metric_header} | Time (ms) | ${source_lines_header} |"
        echo "| :--- | :--- | :---: | :---: | :---: |"
        
        echo "$raw_data" | awk '
        {
            if ($1 == "TopName" || NF < 5) next;
            printf("| %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5);
            total_metric += $3 + 0;
            total_time += $4 + 0;
            row_count += 1;

            if (!($2 in project_seen)) {
                project_seen[$2] = 1;
                project_count += 1;
                total_project_source_lines += $5 + 0;
            }
        }
        END {
            if (row_count > 0) {
                avg_time = project_count > 0 ? total_time / project_count : 0;
                avg_source_lines = project_count > 0 ? total_project_source_lines / project_count : 0;
                printf("| Total | %d entries | %d | %d | %d |\n", row_count, total_metric, total_time, total_project_source_lines);
                printf("| Project Count | - | - | - | %d |\n", project_count);
                printf("| Average Time | - | - | %.2f | - |\n", avg_time);
                printf("| Average Source File lines | - | - | - | %.2f |\n", avg_source_lines);
            }
        }'
    } > "$output_file"
    
    echo "Reported: $output_file"
}

for mode in "${modes[@]}"; do
    case $mode in
        "eval-verilator")
            convert_to_md "$verilatorReport" "Verilator" "verilator"
            ;;
        "eval-wiresort")
            convert_to_md "$wireSortReport" "WireSort" "wiresort"
            ;;
        "eval-yosys")
            convert_to_md "$yosysReport" "Yosys" "yosys"
            ;;
        "eval-all")
            convert_to_md "$verilatorReport" "Verilator" "verilator"
            convert_to_md "$wireSortReport" "WireSort" "wiresort"
            convert_to_md "$yosysReport" "Yosys" "yosys"
            ;;
        *)
    esac
done
