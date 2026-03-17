#!/bin/bash

set -euo pipefail

PROJECT_NAME="riffa"

VERILOG_FILES=(
	fpga/riffa_hdl/functions.vh
	fpga/riffa_hdl/tx_port_writer.v 
  	fpga/riffa_hdl/tx_multiplexer.v 
  	fpga/riffa_hdl/syncff.v 
  	fpga/riffa_hdl/async_fifo.v 
  	fpga/riffa_hdl/async_fifo_fwft.v 
  	fpga/riffa_hdl/channel.v 
  	fpga/riffa_hdl/chnl_tester.v 
  	fpga/riffa_hdl/counter.v 
  	fpga/riffa_hdl/cross_domain_signal.v 
  	fpga/riffa_hdl/demux.v 
  	fpga/riffa_hdl/engine_layer.v 
  	fpga/riffa_hdl/ff.v 
  	fpga/riffa_hdl/fifo.v 
  	fpga/riffa_hdl/interrupt.v 
  	fpga/riffa_hdl/interrupt_controller.v 
  	fpga/riffa_hdl/mux.v 
  	fpga/riffa_hdl/offset_flag_to_one_hot.v 
  	fpga/riffa_hdl/offset_to_mask.v 
  	fpga/riffa_hdl/one_hot_mux.v 
  	fpga/riffa_hdl/pipeline.v 
  	fpga/riffa_hdl/ram_1clk_1w_1r.v 
  	fpga/riffa_hdl/ram_2clk_1w_1r.v 
  	fpga/riffa_hdl/recv_credit_flow_ctrl.v 
  	fpga/riffa_hdl/register.v 
  	fpga/riffa_hdl/registers.v 
  	fpga/riffa_hdl/reorder_queue.v 
  	fpga/riffa_hdl/reorder_queue_input.v 
  	fpga/riffa_hdl/reorder_queue_output.v 
  	fpga/riffa_hdl/reset_controller.v 
  	fpga/riffa_hdl/reset_extender.v 
  	fpga/riffa_hdl/riffa.v 
  	fpga/riffa_hdl/rotate.v 
  	fpga/riffa_hdl/rx_port_channel_gate.v 
  	fpga/riffa_hdl/rx_port_reader.v 
  	fpga/riffa_hdl/rx_port_requester_mux.v 
  	fpga/riffa_hdl/scsdpram.v 
  	fpga/riffa_hdl/sg_list_requester.v 
  	fpga/riffa_hdl/shiftreg.v 
  	fpga/riffa_hdl/sync_fifo.v 
  	fpga/riffa_hdl/tx_alignment_pipeline.v 
  	fpga/riffa_hdl/tx_data_fifo.v 
  	fpga/riffa_hdl/tx_data_pipeline.v 
  	fpga/riffa_hdl/tx_data_shift.v 
  	fpga/riffa_hdl/tx_engine.v 
  	fpga/riffa_hdl/tx_engine_selector.v 
  	fpga/riffa_hdl/tx_hdr_fifo.v 
  	fpga/riffa_hdl/tx_engine_classic.v 
  	fpga/riffa_hdl/rx_engine_classic.v 
  	fpga/riffa_hdl/rxc_engine_classic.v 
  	fpga/riffa_hdl/rxr_engine_classic.v 
  	fpga/riffa_hdl/txc_engine_classic.v 
  	fpga/riffa_hdl/txr_engine_classic.v 
  	fpga/riffa_hdl/channel_32.v
	fpga/riffa_hdl/channel_128.v  
  	fpga/riffa_hdl/tx_port_32.v 
  	fpga/riffa_hdl/tx_port_128.v 
  	fpga/riffa_hdl/rx_port_32.v 
  	fpga/riffa_hdl/rx_port_128.v 
  	fpga/riffa_hdl/tx_port_buffer_32.v 
  	fpga/riffa_hdl/tx_port_channel_gate_32.v 
  	fpga/riffa_hdl/tx_multiplexer_32.v
	fpga/riffa_hdl/tx_multiplexer_128.v 
  	fpga/riffa_hdl/tx_port_monitor_32.v 
  	fpga/riffa_hdl/sg_list_reader_32.v 
  	fpga/riffa_hdl/fifo_packer_32.v 
  	fpga/riffa_hdl/translation_altera.v
	fpga/riffa_hdl/rx_engine_ultrascale.v
  	)

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
			return 1
			;;
	esac
}

collectWithTop() {
	local PROJECTS=$1
	local -n fileSets=$2
	local -n tops=$3
	local -n incs=$5

	pushd "${PROJECTS}/${PROJECT_NAME}"> /dev/null
	local hdls=()
	for file in "${VERILOG_FILES[@]}"; do
		local abs_f=$(realpath "$file")
		if [[ -f "$abs_f" && "$(wc -c < "$abs_f")" -gt 1 ]]; then
			hdls+=("$abs_f")
		fi
	done
	
	if (( ${#hdls[@]} > 0 )); then
		tops+=("${PROJECT_NAME}")
		fileSets+=("$(printf "%q " "${hdls[@]}")")
	fi

	incs+=("-I${PROJECTS}/${PROJECT_NAME}/fpga/riffa_hdl")

	popd > /dev/null
}