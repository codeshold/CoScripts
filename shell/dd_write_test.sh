#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

TEST_FILE_COUNT=16
TEST_MIN_BLOCK_SIZE=512	# 512 bytes
TEST_FILE_SIZE=$((5 * 1024 * 1024 * 1024)) # 5G

TEST_FILE=${1:-dd_write_test_file}

TEST_FILE_EXISTS=0
if [ -e "$TEST_FILE" ]; then TEST_FILE_EXISTS=1; fi

if [ $EUID -ne 0 ]; then
  echo "NOTE: Kernel cache will not be cleared between tests without sudo. This will likely cause inaccurate results." 1>&2
fi

# Header
PRINTF_FORMAT="%16s : %s\n"
printf "\n$PRINTF_FORMAT" "BLOCK SIZE(byte)" "TRANSFER RATE"

for (( BLOCK_SIZE=$TEST_MIN_BLOCK_SIZE, i=1; i <= $TEST_FILE_COUNT; ++i, BLOCK_SIZE*=2 )); do

    # Calculate number of segments required to copy
    COUNT=$(($TEST_FILE_SIZE / $BLOCK_SIZE))

    if [ $COUNT -le 0 ]; then
        echo "Block size of $BLOCK_SIZE estimated to require $COUNT blocks, aborting further tests."
        break
    fi

    # Clear kernel cache to ensure more accurate test
    [ $EUID -eq 0 ] && [ -e /proc/sys/vm/drop_caches ] && echo 3 > /proc/sys/vm/drop_caches

    # Create a test file with the specified block size
    RESULT=$(dd if=/dev/zero of=$TEST_FILE bs=$BLOCK_SIZE count=$COUNT conv=fsync 2>&1 1>/dev/null)

    # Extract the transfer rate from dd's STDERR output
    TRANSFER_RATE=$(echo $RESULT | grep -o -E '[0-9.]+ ([GgMmKk]?[Bb](ytes)?/s(ec)?)')

    # Clean up the test file if we created one
    if [ $TEST_FILE_EXISTS -ne 0 ]; then rm -rf $TEST_FILE; fi

    # Output the result
    printf "$PRINTF_FORMAT" "$BLOCK_SIZE" "$TRANSFER_RATE"
done
    
if [ $TEST_FILE_EXISTS -ne 0 ]; then rm -rf $TEST_FILE; fi
