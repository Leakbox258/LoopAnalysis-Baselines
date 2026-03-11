#!/bin/bash

set -euo pipefail

git submodule update --init --recursive

printf "\033[33mBuild Verilator5.0 from source...\033[0m"
cd ./3rd-party/analyzer/verilator
autoconf
./configure --prefix="$(pwd)"/build
make -j 16
make install
cd -
printf "\033[32mIntall Verialtor on Path: 3rd-party/analyzer/verilator/build/bin/verilator\033[0m"

if [ ! -x "./3rd-party/analyzer/verilator/build/bin/verilator" ]; then
	printf "\033[31mError: Verilator executable not found at ./3rd-party/analyzer/verilator/build/bin/verilator\033[0m"
	exit 1
fi

printf "\033[33mBuild PyRTL(WireSorts) package from source \033[0m"
cd ./3rd-party/analyzer/WireSorts/
python3 setup.py build
python3 setup.py install --prefix="$(pwd)"/build
cd -
printf "\033[32mInstall PyRTL(WireSorts) package on Path: 3rd-party/analyzer/WireSorts/build/lib/pyrtl\033[0m"

if [ ! -d "./3rd-party/analyzer/WireSorts/build/lib/pyrtl" ]; then
	printf "\033[31mError: PyRTL(WireSorts) package not found at ./3rd-party/analyzer/WireSorts/build/lib/pyrtl\033[0m"
	exit 1
fi

if command -v yosys &> /dev/null; then
	printf "\033[32mYosys is already installed on your system.\033[0m\n"
else
	printf "\033[31mError: Yosys is not installed. Please install oss-cad-suite manually.\033[0m\n"
	exit 1
fi

printf "\033[32mSetup complete!.\033[0m\n"