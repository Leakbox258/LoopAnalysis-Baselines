#!/bin/bash

set -euo pipefail

PROJECT_NAME="basic_verilog"

collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3
    local -n defs=$4
    local -n incs=$5

    local ROOT_DIR
    ROOT_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}")
    
    local all_sv_files=()
    while IFS= read -r -d '' file; do
        if [[ "$(wc -c < "$file")" -gt 1 ]]; then
            all_sv_files+=("$(realpath "$file")")
        fi
    done < <(find "$ROOT_DIR" -maxdepth 1 -name "*.sv" ! -name "*_tb*" ! -name "*_gen*" -print0)

    if (( ${#all_sv_files[@]} == 0 )); then
        return
    fi

    for hdl_path in "${all_sv_files[@]}"; do
        local filename
        filename=$(basename "$hdl_path")
        
        tops+=("${filename%.*}")
        
        fileSets+=("$(printf "%q " "${all_sv_files[@]}")")
    done

    defs+=("-DAXI_ADDR_WIDTH=32")
    defs+=("-DAXI_DATA_WIDTH=32")
    defs+=("-DAXI_SIZE_WIDTH=32")
    defs+=("-DAXI_LEN_WIDTH=32")
    defs+=("-DAXI_DATA_BYTES=4")

    incs+=("-I${ROOT_DIR}")
}