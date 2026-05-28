#!/bin/bash

set -euo pipefail

VERILATOR=./3rd-party/analyzer/verilator/build/bin/verilator

PROJECTS=./3rd-party/projects
PYRTL_PACKAGE_PATH=""

args=("$@")
modes=()
contain_projects=()
skip_projects=()
yosys="yosys"
blif_only="false"
list_mode=""

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
        printf "  -blif-only=<bool>      Only generate BLIF files for WireSort and skip eval\n"
        printf "  --list=<mode>          List projects that support a mode without running evaluation\n"
        exit 0
	fi

	if [[ $arg == -blif-only=* || $arg == --blif-only=* ]]; then
		blif_only=${arg#*=}
		continue
	fi

	if [[ $arg == --list=* ]]; then
		list_mode=${arg#*=}
		continue
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
		"--list")
			list_mode="$arg"
			;;
		*)
			printf "Error: Unknown Option %s" "$current_opt"
			exit 1
		esac
	fi
done

project_selected() {
	local project=$1
	local skipped
	local contained

	for skipped in "${skip_projects[@]}"; do
		if [[ $skipped == "$project" ]]; then
			return 1
		fi
	done

	if (( ${#contain_projects[@]} == 0 )); then
		return 0
	fi

	for contained in "${contain_projects[@]}"; do
		if [[ $contained == "$project" ]]; then
			return 0
		fi
	done

	return 1
}

qualify_list_mode() {
	local mode=$1

	case $mode in
		"eval-verilator"|"eval-wiresort"|"eval-yosys")
			qualify "$mode"
			;;
		"eval-yosys-netlist")
			qualify "eval-yosys"
			;;
		"eval-all")
			qualify "eval-verilator" || qualify "eval-wiresort" || qualify "eval-yosys"
			;;
		*)
			printf "Error: Unknown list mode %s\n" "$mode" 1>&2
			printf "Mode Usage: --list=[eval-verilator|eval-wiresort|eval-yosys|eval-yosys-netlist|eval-all]\n" 1>&2
			exit 1
			;;
	esac
}

list_projects_for_mode() {
	local mode=$1
	local matched_projects=()
	local script
	local file
	local project

	for script in ./scripts/projects/*.sh; do
		file=$(basename "$script")
		project=${file%.sh}

		if ! project_selected "$project"; then
			continue
		fi

		source "$script"

		if qualify_list_mode "$mode"; then
			matched_projects+=("$project")
		fi
	done

	printf "%s\n" "${matched_projects[*]}"
}

if [[ -n "$list_mode" ]]; then
	list_projects_for_mode "$list_mode"
	exit 0
fi

require_pyrtl_package() {
	if [[ -n "$PYRTL_PACKAGE_PATH" ]]; then
		return
	fi

	PYRTL_PACKAGE_PATH=$(find ./3rd-party \( -name "pyrtl-*.egg" -type d -o -name "pyrtl-*.egg" -type f \) -print -quit)

	if [[ $PYRTL_PACKAGE_PATH == "" ]]; then
		printf "Didn't find pyrtl package, run setup.sh to build and install.\n"
		exit 1
	fi
}

require_verilator() {
	if [[ ! -x "$VERILATOR" ]]; then
		printf "Didn't find built verilator, run setup.sh to build.\n"
		exit 1
	fi
}

# Get projects for evaluations
EVAL_PROJECTS=()

for script in ./scripts/projects/*.sh; do
	file=$(basename "$script")
	project=${file%.sh}
	
	if project_selected "$project"; then
		EVAL_PROJECTS+=("$script")
	fi
done

mkdir -p build/blif
mkdir -p build/yosys

verilatorReport=""
wireSortReport=""
yosysReport=""
yosysNetListReport=""

for mode in "${modes[@]}"; do

	case $mode in
		"eval-verilator")
			require_verilator
			source ./scripts/verilator5.0.sh
			verilatorReport+=$(verilatorEval "$VERILATOR"\
											 "$PROJECTS" \
											 EVAL_PROJECTS
											 )
			;;
		"eval-wiresort")
			require_pyrtl_package
			source ./scripts/wireSort.sh
			wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" \
											"./scripts/implWireSort.py" \
											"$yosys" \
											"$PROJECTS" \
											EVAL_PROJECTS \
											"$blif_only"
											)
			;;
		"eval-yosys")
			source ./scripts/yosys.sh
			yosysReport+=$(yosysEval "$yosys" \
									"$PROJECTS" \
									EVAL_PROJECTS
									)
			;;
		"eval-yosys-netlist")
			source ./scripts/yosys-netlist.sh
			yosysNetListReport+=$(yosysNetListEval "$yosys" \
									"$PROJECTS" \
									EVAL_PROJECTS
									)
			;;
		"eval-all")
			require_verilator
			require_pyrtl_package
			source ./scripts/verilator5.0.sh
			source ./scripts/wireSort.sh
			source ./scripts/yosys.sh
			source ./scripts/yosys-netlist.sh
			verilatorReport+=$(verilatorEval "$VERILATOR"\
											 "$PROJECTS" \
											 EVAL_PROJECTS
											 )
			wireSortReport+=$(wireSortEval "$PYRTL_PACKAGE_PATH" \
											"./scripts/wireSort.py" \
											"$yosys" \
											"$PROJECTS" \
											EVAL_PROJECTS \
											"$blif_only"
											)
			yosysReport+=$(yosysEval "$yosys" \
									"$PROJECTS" \
									EVAL_PROJECTS
									)
			yosysNetListReport+=$(yosysEval "$yosys" \
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
    
    {
        echo "# ${title} Evaluation Report (${DATE})"
        echo ""
        
        echo "$raw_data" | awk '
        function display_header(header) {
            if (header == "Time(ms)") return "Time (ms)";
            if (header == "AlgorithmTime(ms)") return "Algorithm Time (ms)";
            return header;
        }

        function emit_summary(label, second_col, metric_value, time_value, algorithm_time_value, source_lines_value, i, value) {
            printf("|");
            for (i = 1; i <= col_count; ++i) {
                value = "-";
                if (i == 1) {
                    value = label;
                } else if (i == 2) {
                    value = second_col;
                } else if (i == 3) {
                    value = metric_value;
                } else if (i == time_idx) {
                    value = time_value;
                } else if (i == algorithm_time_idx) {
                    value = algorithm_time_value;
                } else if (i == source_lines_idx) {
                    value = source_lines_value;
                }
                printf(" %s |", value);
            }
            printf("\n");
        }

        !header_seen && NF {
            header_seen = 1;
            col_count = NF;

            printf("|");
            for (i = 1; i <= col_count; ++i) {
                headers[i] = $i;
                if ($i == "Time(ms)") time_idx = i;
                if ($i == "AlgorithmTime(ms)") algorithm_time_idx = i;
                if ($i == "SourceFileLines") source_lines_idx = i;
                printf(" %s |", display_header($i));
            }
            printf("\n|");
            for (i = 1; i <= col_count; ++i) {
                if (i <= 2) {
                    printf(" :--- |");
                } else {
                    printf(" :---: |");
                }
            }
            printf("\n");
            next;
        }

        {
            if ($1 == "TopName" || NF < col_count) next;
            printf("|");
            for (i = 1; i <= col_count; ++i) {
                printf(" %s |", $i);
            }
            printf("\n");

            total_metric += $3 + 0;
            if (time_idx > 0) total_time += $time_idx + 0;
            if (algorithm_time_idx > 0) total_algorithm_time += $algorithm_time_idx + 0;
            if (source_lines_idx > 0) total_source_lines += $source_lines_idx + 0;
            row_count += 1;

            if (!($2 in project_seen)) {
                project_seen[$2] = 1;
                project_count += 1;
            }
        }
        END {
            if (row_count > 0) {
                avg_time = project_count > 0 ? total_time / project_count : 0;
                avg_algorithm_time = project_count > 0 ? total_algorithm_time / project_count : 0;
                avg_source_lines = row_count > 0 ? total_source_lines / row_count : 0;

                emit_summary("Total", sprintf("%d entries", row_count), sprintf("%d", total_metric), sprintf("%d", total_time), sprintf("%d", total_algorithm_time), sprintf("%d", total_source_lines));
                emit_summary("Project Count", "-", "-", "-", "-", sprintf("%d", project_count));
                emit_summary("Average Time", "-", "-", sprintf("%.2f", avg_time), "-", "-");
                if (algorithm_time_idx > 0) {
                    emit_summary("Average Algorithm Time", "-", "-", "-", sprintf("%.2f", avg_algorithm_time), "-");
                }
                emit_summary("Average Source File lines", "-", "-", "-", "-", sprintf("%.2f", avg_source_lines));
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
		"eval-yosys-netlist")
            convert_to_md "$yosysNetListReport" "YosysNetList" "yosysNetList"
            ;;
        "eval-all")
            convert_to_md "$verilatorReport" "Verilator" "verilator"
            convert_to_md "$wireSortReport" "WireSort" "wiresort"
            convert_to_md "$yosysReport" "Yosys" "yosys"
            convert_to_md "$yosysNetListReport" "YosysNetList" "yosysNetList"
            ;;
        *)
    esac
done
