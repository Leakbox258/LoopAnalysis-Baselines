#!/bin/bash

set -euo pipefail

PROJECT_NAME="hdl"

collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3
	local -n incs=$5

    local LIB_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/library")
    
    if [[ ! -d "$LIB_DIR" ]]; then
        return
    fi

    pushd "$LIB_DIR" > /dev/null
    
    while IFS= read -r -d '' dir; do
        local abs_dir
        abs_dir=$(realpath "$dir")
        
        local source=()
        while IFS= read -r -d '' hdl; do
            if [[ -f "$hdl" && "$(wc -c < "$hdl")" -gt 1 ]]; then
                source+=("$(realpath "$hdl")")
            fi
        done < <(find "$abs_dir" -maxdepth 1 -name "*.v" ! -name "*_tb*" ! -name "*tb_*" -print0)

        if (( ${#source[@]} > 0 )); then
            local rel_path=${abs_dir#$LIB_DIR/}
            local top_name="${rel_path//\//_}"
            
            tops+=("$top_name")
            fileSets+=("$(printf "%q " "${source[@]}")")
        fi

    done < <(find . -type d ! -path . \
                ! -path "*/tb/*" \
                ! -path "*/intel/*" \
                ! -path "*xilinx/axi_adcfifo*" \
                ! -path "*jesd204*" \
                ! -path "*corundum*" -print0)
	
	incs+=("-I${PROJECTS}/${PROJECT_NAME}/library/common")
	incs+=("-I${PROJECTS}/${PROJECT_NAME}/library/intel/common")
	incs+=("-I${PROJECTS}/${PROJECT_NAME}/library/axi_dmac")
	while IFS= read -r dir; do
        incs+=("-I$(pwd)/${dir}")
    done < <(find . -type f \( -name "*.vh" -o -name "*.svh" \) -exec dirname {} \; | sort -u)

    popd > /dev/null
}