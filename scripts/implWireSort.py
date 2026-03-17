# !/bin/python3

import sys
import os
import re
import collections
import collections.abc
import time

PACKAGE_PATH = os.path.abspath(sys.argv[1])
BLIF_FILE = os.path.abspath(sys.argv[2])

# Adding package.egg path
if PACKAGE_PATH not in sys.path:
    sys.path.insert(0, PACKAGE_PATH)

# Roll back `collections` attrs in high-level python
if not hasattr(collections, 'Mapping'):
    collections.Mapping = collections.abc.Mapping
if not hasattr(collections, 'MutableMapping'):
    collections.MutableMapping = collections.abc.MutableMapping
if not hasattr(collections, 'Sequence'):
    collections.Sequence = collections.abc.Sequence
    
import pyrtl

EXTERN_CELL_LIB='''
.model $logic_or
.inputs A B
.outputs Y
.names A B Y
1- 1
-1 1
.end

.model $logic_and
.inputs A B
.outputs Y
.names A B Y
11 1
.end

.model $mux
.inputs A B S
.outputs Y
.names S A B Y
01- 1
1-1 1
.end

.model $fa
.inputs A B CI
.outputs Y CO
.names A B CI Y
111 1
100 1
010 1
001 1
.names A B CI CO
11- 1
1-1 1
-11 1
.end

.model $demux
.inputs A S
.outputs Y0 Y1
.names A S Y0
10 1
.names A S Y1
11 1
.end

.model $add
.inputs A B CI
.outputs Y CO
.subckt $fa A=A B=B CI=CI Y=Y CO=CO
.end
'''

def aggressive_sanitize(blif_str):
    blif_str = blif_str.replace('\\', '_')
    
    blif_str = re.sub(r"\?s32'[01]+", "_constant_val", blif_str)

    blif_str = blif_str.replace(".names $false\n", ".names _logic0_\n")
    blif_str = blif_str.replace(".names $true\n1\n", ".names _logic1_\n1\n")
    blif_str = blif_str.replace(".names $undef\n", ".names _logic_x_\n")

    blif_str = blif_str.replace('$', 'Y_INTERNAL_')

    return blif_str

def eval_wire_sort():
    bad_connection_counts = 0

    with open(BLIF_FILE, 'r') as f:
        blif_design = f.read()
        clean_blif_design = aggressive_sanitize(blif_design)
        clean_blif_design = EXTERN_CELL_LIB + '\n' + clean_blif_design

        pyrtl.input_from_blif(clean_blif_design)
        
        start_time = time.perf_counter()

        try:
            pyrtl.working_block().sanity_check(wire_sort_only=True)
        except PyrtlError as e:
            message = str(e)
            if "Find Bad Connections:" in message:
                bad_connection_counts += int(message[message.find("Find Bad Connections:"):-1], 10)
        end_time = time.perf_counter()

        elapsed_ms = int((end_time - start_time) * 1000) # ms
  
    return bad_connection_counts, elapsed_ms

if __name__ == "__main__":
    scc, time_consume = eval_wire_sort()
    print(f"Wire Sort find Bad Connection Counts: {scc}")
    print(f"Time Consume: {time_consume} ms")
    exit(0)
