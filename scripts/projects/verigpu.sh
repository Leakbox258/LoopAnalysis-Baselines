#!/bin/bash

set -euo pipefail

PROJECT_NAME="verigpu"

preprocess() {
    local PROJECTS=$1
    local BUILD_DIR="build"
    local TARGET="${BUILD_DIR}/verigpu.sv"
    local PARAMS_FILE="${BUILD_DIR}/verigpu_params.sv"

    mkdir -p "$BUILD_DIR"

    if [[ -f "$TARGET" ]]; then
        if (( $(wc -l < "$TARGET") == 6161 )); then
            return
        fi
    fi


    cat > "$PARAMS_FILE" << 'EOF'
parameter pos_width = $clog2(data_width);
parameter adder_width = 32;
parameter half_width = adder_width / 2;
parameter width = 32;
EOF


    local SRC_DIR="${PROJECTS}/${PROJECT_NAME}/src"

    {
        cat "${SRC_DIR}/const.sv"
        cat "$PARAMS_FILE"
        cat "${SRC_DIR}/op_const.sv"
        cat "${SRC_DIR}/assert.sv"
        cat "${SRC_DIR}/float/float_params.sv"
        cat "${SRC_DIR}/mem_large.sv"

        find "$SRC_DIR" -name '*.sv' \
            ! -name 'const.sv' \
            ! -name 'op_const.sv' \
            ! -name 'assert.sv' \
            ! -name "float_params.sv" \
            ! -name "mem_*" \
            -exec cat {} +
    } > "$TARGET"
}

collectWithTop() {
    local PROJECTS=$1
    local -n fileSets=$2
    local -n tops=$3

    preprocess "$PROJECTS"

    local ABS_TARGET
    ABS_TARGET=$(realpath "build/verigpu.sv")

    if [[ -f "$ABS_TARGET" && "$(wc -c < "$ABS_TARGET")" -gt 1 ]]; then
        tops+=("verigpu")

        fileSets+=("$(printf "%q " "$ABS_TARGET")")
    else
        echo "Error: verigpu.sv was not generated correctly at $ABS_TARGET" >&2
        return 1
    fi
}