#!/bin/bash
# Main function for FS_microbench.
set -ex

source ../micro/scripts/run_tput_all.sh || { echo "Run in the project root directory."; exit 1;}

MOUNT_PATH="/mnt/zj"

# Set nvme device path.
# DEV_PATH="/dev/nvme2n1"
#
# Or, get it automatically. nvme-cli is required. (sudo apt install nvme-cli)
DEV_PATH="$(sudo nvme list | grep "SAMSUNG MZPLJ3T2HBJR-00007" | xargs | cut -d " " -f 1)"
echo Device path: "$DEV_PATH"


############# Overriding configurations of run_tput_all.sh
DIRS="$MOUNT_PATH/zj_journal"
OPS="sw"
TOTAL_WRITE_SIZE=$((40 * 1024)) # in MB
IO_SIZES="4K 16K 64K 1M"
NUM_THREADS="1 4 16"

resetCPUCores() {

	# Turning on all cores in NUMA 1.
	python3 tools/cpu-onlining.py -s16 -e31
}

umountFS() {
	sudo umount $MOUNT_PATH || true
}

##### Configuration for the different number of threads. Called in run_tput_all.sh
configCPU () {

	# Adjust the number of CPU cores and reformat to adjust the total journal size.

	umountFS
	resetCPUCores

	case "$NUM_THREAD" in
		"1")
			# Enable 4 cores in NUMA 1. (Each core has 5GB journal space.)
			python3 tools/cpu-offlining.py -s 19 -e 31
			./format.sh 5120 $DEV_PATH
			;;
		"4")
			# Enable 8 cores in NUMA 1. (Each core has 5GB/4 = 1280MB journal space.)
			python3 tools/cpu-offlining.py -s 24 -e 31
			./format.sh 1280 $DEV_PATH
			;;
		"16")
			# Enable all (16 cores) in NUMA 1. (Each core has 5GB/16 = 320MB journal space.)
			python3 tools/cpu-offlining.py # Only showing the current state.
			./format.sh 320 $DEV_PATH
			;;
	esac

	sudo mount -t ext4mj $DEV_PATH $MOUNT_PATH
	sudo mkdir -p $DIR
}

###### File system specific main function. Should be declared. Called in run_tput_all.sh
runFileSystemSpecific() {

	echo "z-journal main function."

	CMD="$PERF_PREFIX $PINNING $BENCH_MICRO/build/tput_micro -d $DIR -s $OP ${FILE_SIZE}M $IO_SIZE $NUM_THREAD"

	# Print command.
	echo Command: "$CMD" | tee ${OUT_FILE}.out

	# Execute
	$CMD | tee -a ${OUT_FILE}.out

}

# Execute only this script is directly executed. (Not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

	## Turning off most of cores in NUMA 0.
	python3 tools/cpu-offlining.py -s 2 -e 15

	# fixCPUFreq

	loopMicroTput
	echo "Output files are in 'results' directory."

	## Wrap up
	umountFS
	resetCPUCores

	## Turning off most of cores in NUMA 0.
	python3 tools/cpu-onlining.py -s 2 -e 15
fi
