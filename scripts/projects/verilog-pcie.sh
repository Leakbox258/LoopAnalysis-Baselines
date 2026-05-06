#!/bin/bash

set -euo pipefail

PROJECT_NAME="verilog-pcie"

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

	local RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl")
	pushd "$RTL_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find . -name "*.v" \
  					! -name "pcie_s10_if*" \
  					! -name "pcie_ptile_if*"\
  					! -name "pcie_us_if*"\
  					! -name "pcie_tlp_demux_bar*" \
  					! -name "pcie_tlp_fifo_mux*" -print0)

	if (( ${#current_files[@]} > 0 )); then
		tops+=("verilog-pcie")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi
	popd > /dev/null
}

collectWithTop() {
	local PROJECTS=$1
	local -n fileSets=$2
	local -n tops=$3

	local RTL_DIR=$(realpath "${PROJECTS}/${PROJECT_NAME}/rtl")
	pushd "$RTL_DIR" > /dev/null
	
	local current_files=()
	while IFS= read -r -d '' file; do
		if [[ "$(wc -c < "$file")" -gt 1 ]]; then
			current_files+=("$(realpath "$file")")
		fi
	done < <(find . -name "*.v" \
  					! -name "pcie_s10_if*" \
  					! -name "pcie_ptile_if*"\
  					! -name "pcie_us_if*"\
  					! -name "pcie_tlp_demux_bar*" \
  					! -name "pcie_tlp_fifo_mux*" -print0)

	if (( ${#current_files[@]} > 0 )); then
		tops+=("axis_arb_mux")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		# tops+=("pcie_us_msi") # wrong latch inferred
		# fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_us_cfg")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_us_axis_rc_demux")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_us_axil_master")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_us_axi_dma")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_tlp_mux")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_tlp_fc_count")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_s10_msi")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_s10_cfg")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_ptile_fc_counter")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_ptile_cfg")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_msix")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_axil_master_minimal")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_axil_master")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("pcie_axi_master")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("\pcie_axi_dma_desc_mux")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("irq_rate_limit")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("dma_ram_demux")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("dma_psdpram_async")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("dma_psdpram")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		# tops+=("dma_if_pcie_us") # Latch
		# fileSets+=("$(printf "%q " "${current_files[@]}")")
		# tops+=("dma_if_pcie") # Latch
		# fileSets+=("$(printf "%q " "${current_files[@]}")")
		# tops+=("dma_if_axi") # Latch
		# fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("dma_client_axis_source")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
		tops+=("dma_client_axis_sink")
		fileSets+=("$(printf "%q " "${current_files[@]}")")
	fi
	popd > /dev/null
}