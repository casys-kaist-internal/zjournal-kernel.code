#!/bin/bash
set -ex

E2FSPROG_PATH="/home/yulistic/e2fsprog-zj" # Set proper path of e2fsprog-zj.

printUsage()
{
	echo "$(basename $0) <journal_size_per_core_in_MB> <dev_path>"
	echo "Example of 5GB journal per core: $(basename $0) 5120 /dev/nvmeXnY"
	exit
}

if [ "$#" -ne 2 ]; then
	echo "Invalid arguments."
	printUsage
fi

PER_CORE_JOURNAL_SIZE="$1"
TOTAL_JOURNAL_SIZE=$(echo "$1 * $(nproc)" | bc)
DEV_PATH=$2

if [ -z "$E2FSPROG_PATH" ]; then
	echo "Set proper e2fsprog-zj path."
	printUsage
fi

echo "Per core journal size: $1 MB"
echo "Total journal size: $TOTAL_JOURNAL_SIZE MB ($(nproc) cores)"
echo "Device path: $DEV_PATH"

sudo $E2FSPROG_PATH/misc/mke2fs -t ext4 -J size=$PER_CORE_JOURNAL_SIZE,multi_journal -F -G 1 $DEV_PATH
sudo $E2FSPROG_PATH/misc/tune2fs -o journal_data $DEV_PATH
