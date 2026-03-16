#!/bin/bash

set -euo pipefail

git submodule update --init --recursive

printf "\033[33mBuild Verilator5.0 from source...\n\033[0m"
pushd ./3rd-party/analyzer/verilator > /dev/null
autoconf
./configure --prefix="$(pwd)"/build
make -j 16
make install
popd > /dev/null
printf "\033[32mIntall Verialtor on Path: 3rd-party/analyzer/verilator/build/bin/verilator\n\033[0m"

if [ ! -x "./3rd-party/analyzer/verilator/build/bin/verilator" ]; then
	printf "\033[31mError: Verilator executable not found at ./3rd-party/analyzer/verilator/build/bin/verilator\033[0m"
	exit 1
fi

printf "\n\033[33mBuild PyRTL(WireSort) package from source \n\033[0m"
pushd ./3rd-party/analyzer/WireSort/ > /dev/null
python3 setup.py build
python3 setup.py install --prefix="$(pwd)"/build
popd > /dev/null
printf "\033[32mInstall PyRTL(WireSort) package on Path: 3rd-party/analyzer/WireSort/build/lib/pyrtl\n\033[0m"

if [ ! -d "./3rd-party/analyzer/WireSort/build/lib/pyrtl" ]; then
	printf "\033[31mError: PyRTL(WireSort) package not found at ./3rd-party/analyzer/WireSort/build/lib/pyrtl\033[0m"
	exit 1
fi

if command -v yosys &> /dev/null; then
	printf "\n\033[32mYosys is already installed on your system.\n\033[0m\n"
else
	printf "\n\033[31mError: Yosys is not installed. Please install oss-cad-suite manually.\033[0m\n"
	exit 1
fi

printf "\033[32mSetup complete!\033[0m\n"