# LoopAnalysis-Benchmark
This repo is benchmark testing of [verilator](https://github.com/verilator/verilator), [PLDI 21 Wire Sort](https://pldi21.sigplan.org/details/pldi-2021-papers/12/Wire-Sorts-A-Language-Abstraction-for-Safe-Hardware-Composition) and [yosys](https://github.com/YosysHQ/yosys) on detecting combinational or asynchronous loop.
# Measure
## Loop Amount
To ensure consistency across disparate diagnostic outputs, the analysis of **Yosys** and **Verilator** is standardized around **SCC** identification. In the case of **Wire Sort**, the detection of **bad connections** facilitated by pin-level classification and formal type-checking—is treated as a diagnostic proxy, where a single connection failure is postulated to represent a minimum of one **combinational loop**.

## Time Consuming
To quantify computational overhead, we utilize the native Linux `date` command to achieve **millisecond-level** resolution. It is noted that the recorded latency includes the latency of process spawning and context loading by the OS. Despite potential variances introduced by heterogeneous memory architectures and tool-specific implementations, the temporal results are posited to provide a valid benchmark for evaluating differences at the **algorithmic design level**.

# Test Scope


# Requirments
- `verilator`: fork from https://github.com/verilator/verilatorm, slighty modified to collect SCC, instead of just warnings.
- `PyRTL package`: for from https://github.com/pllab/PyRTL, slighty modified to only lint for bad connections.
- `YoSys`: part of OSS CAD Suite
- [`yosys-slang`](https://github.com/povik/yosys-slang): worked as SystemVerilog frontend plugin for yosys