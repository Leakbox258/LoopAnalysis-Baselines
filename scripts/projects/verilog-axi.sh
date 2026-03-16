#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-axi"

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

    for hdl_path in "${all_v_files[@]}"; do
        local filename
        filename=$(basename "$hdl_path")
        
        tops+=("${filename%.*}")
        
        fileSets+=("$(printf "%q " "$hdl_path")")
    done

    popd > /dev/null
}