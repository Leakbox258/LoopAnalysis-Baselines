import sys

PACKAGE_PATH = sys.argv[1]
BLIF_FILE = sys.argv[2]

sys.path.insert(0, PACKAGE_PATH)

import pyrtl

def eval_wire_sort():
	bad_connection_counts = 0

	with open(BLIF_FILE, 'r') as f:
		blif_design = f.read()
		pyrtl.input_from_blif(blif_design)
		
		try:
			pyrtl.working_block().sanity_check(wire_sort_only=True)
		except PyrtlError as e:
			message = str(e)
			if "Find Bad Connections:" in message:
				bad_connection_counts += int(message[message.find("Find Bad Connections:"):-1], 10)

	return bad_connection_counts

if __name__ == "__main__":
    scc = eval_wire_sort()
    print(f"Wire Sort find Bad Connection Counts: {scc}")
