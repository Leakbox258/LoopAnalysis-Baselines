#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-axi"

qualify() {
	mode=$1

	case $mode in
		"eval-verilator")
			return 0
			;;
		"eval-wiresort")
			return 1
			;;
		"eval-yosys")
			return 0
			;;
	esac
}

collectWithTopVerilator() {
        local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3

    local RTL_DIR
    RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl")
    
    if [[ ! -d "$RTL_DIR" ]]; then
        return
    fi

    pushd "$RTL_DIR" > /dev/null
    
    local all_v_files=()
    while IFS= read -r -d '' file; do
        if [[ "$(wc -c < "$file")" -gt 1 ]]; then
            all_v_files+=("$(realpath "$file")")
        fi
    done < <(find . -name "*.v" \
                ! -name "*adapter*" \
                ! -name "*vfifo*" \
                ! -name "*_tb.v" \
                ! -name "tb_*.v" -print0)

    if (( ${#all_v_files[@]} > 0 )); then
        tops+=("verilog-axi")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
    fi
    popd > /dev/null
}

collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3

    local RTL_DIR
    RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl")
    
    if [[ ! -d "$RTL_DIR" ]]; then
        return
    fi

    pushd "$RTL_DIR" > /dev/null
    
    local all_v_files=()
    while IFS= read -r -d '' file; do
        if [[ "$(wc -c < "$file")" -gt 1 ]]; then
            all_v_files+=("$(realpath "$file")")
        fi
    done < <(find . -name "*.v" \
                ! -name "*adapter*" \
                ! -name "*vfifo*" \
                ! -name "*_tb.v" \
                ! -name "tb_*.v" -print0)

    if (( ${#all_v_files[@]} > 0 )); then
        tops+=("axi_cdma")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axil_register")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axil_reg_if")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axil_interconnect")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axil_dp_ram")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axil_crossbar")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axil_cdc")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axi_register")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axi_ram")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axi_interconnect")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axi_fifo")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axi_dp_ram")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")
        tops+=("axi_dma_desc_mux")
        fileSets+=("$(printf "%q " "${all_v_files[@]}")")

    fi

    popd > /dev/null
}