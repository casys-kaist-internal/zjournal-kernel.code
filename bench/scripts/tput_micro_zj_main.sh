#!/bin/bash
# Main function for FS_microbench.
set -ex

source ../micro/scripts/run_tput_all.sh || { echo "Run in the directory where this script is."; exit 1;}

# To source zjournal's e2fsprog path.
source ./format.sh || { echo "Run in the directory where this script is."; exit 1;}

MOUNT_PATH="/mnt/zj"

# Set nvme device path.
# DEV_PATH="/dev/nvme2n1"
#
# Or, get it automatically. nvme-cli is required. (sudo apt install nvme-cli)
DEV_PATH="$(sudo nvme list | grep "SAMSUNG MZPLJ3T2HBJR-00007" | xargs | cut -d " " -f 1)"
echo Device path: "$DEV_PATH"

# Set total journal size.
# TOTAL_JOURNAL_SIZE=5120 # 5 GB
TOTAL_JOURNAL_SIZE=$((38 * 1024)) # 38 GB

############# Overriding configurations of run_tput_all.sh
DIRS="$MOUNT_PATH/zj_journal"
OPS="sw"
TOTAL_WRITE_SIZE=$((30 * 1024)) # in MB
IO_SIZES="4K 16K 64K 1M"
NUM_THREADS="1 4 8 16"

umountFS() {
	sudo umount $MOUNT_PATH || true
}

##### Configuration for the different number of threads. Called in run_tput_all.sh
configMultiThread () {

	# Reformat to adjust the total journal size.
	umountFS

	percore_journal_size="$(echo "$TOTAL_JOURNAL_SIZE / $NUM_THREAD" | bc)"
	echo "Journal size: Total = $TOTAL_JOURNAL_SIZE MB, Per-core = $percore_journal_size MB"
	./format.sh $percore_journal_size $DEV_PATH

	sudo mount -t ext4mj $DEV_PATH $MOUNT_PATH
	sudo chown -R $USER:$USER $MOUNT_PATH
	mkdir -p $DIR
}

###### File system specific main function. Should be declared. Called in run_tput_all.sh
runFileSystemSpecific() {

	echo "z-journal main function."

	# dump file system configs.
	sudo $E2FSPROG_PATH/misc/dumpe2fs -h $DEV_PATH > ${OUT_FILE}.fsconf

	CMD="$PERF_PREFIX $PINNING $BENCH_MICRO/build/tput_micro -d $DIR -s $OP ${FILE_SIZE}M $IO_SIZE $NUM_THREAD"

	# Print command.
	echo Command: "$CMD" | tee ${OUT_FILE}.out

	# Execute
	$CMD | tee -a ${OUT_FILE}.out

}

# Execute only this script is directly executed. (Not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

	# zj kernel does not support our testbed CPU.
	# fixCPUFreq

	loopMicroTput
	echo "Output files are in 'results' directory."

	## Wrap up
	umountFS

fi
