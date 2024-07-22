#!/bin/bash
# Z-journal main function for Filebench.
set -ex

source ../filebench/scripts/run_all.sh || { echo "Run in the directory where this script is."; exit 1;}

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

############# Overriding configurations.
# NUM_THREADS="16 8 4 2 1"

umountFS() {
	sudo umount $MOUNT_PATH || true
}

configMultiThread() {
	# Set nthread of the workload file.
	sed -i "/set \$nthreads=*/c\set \$nthreads=${NUM_THREAD}" $WORKLOAD

	# Reformat to adjust the total journal size.
	umountFS

	percore_journal_size="$(echo "$TOTAL_JOURNAL_SIZE / $NUM_THREAD" | bc)"
	echo "Journal size: Total = $TOTAL_JOURNAL_SIZE MB, Per-core = $percore_journal_size MB"
	./format.sh $percore_journal_size $DEV_PATH

	sudo mount -t ext4mj $DEV_PATH $MOUNT_PATH
	sudo chown -R $USER:$USER $MOUNT_PATH
	mkdir -p $DIR
}

###### File system specific main function. Should be declared.
runFileSystemSpecific() {

	echo "z-journal main function."

	# dump file system configs.
	sudo $E2FSPROG_PATH/misc/dumpe2fs -h $DEV_PATH > ${OUT_FILE}.fsconf

	# dump workload.
	echo $WORKLOAD > ${OUT_FILE}.wkld
	cat $WORKLOAD >> ${OUT_FILE}.wkld

	CMD="$PERF_PREFIX sudo $PINNING filebench -f $WORKLOAD"

	# Print command.
	echo Command: "$CMD" | tee ${OUT_FILE}.out

	# Execute
	$CMD | tee -a ${OUT_FILE}.out
}

# Execute only this script is directly executed. (Not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# fixCPUFreq

	umountFS

	DIR="$MOUNT_PATH/zj_journal"
	loopFilebench

	umountFS

	echo "Output files are in 'results' directory."
fi
