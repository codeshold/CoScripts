#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

TEST_FILE_COUNT=2
TEST_MIN_BLOCK_SIZE=512
TEST_FILE_SIZE=$((5 * 1024 * 1024 * 1024))

TEST_FILE=${1:-dd_write_test_file}

TEST_FILE_EXISTS=0
if [ -e "$TEST_FILE" ]; then TEST_FILE_EXISTS=1; fi

if [ $EUID -ne 0 ]; then
  echo "NOTE: Kernel cache will not be cleared between tests without sudo. This will likely cause inaccurate results." 1>&2
fi

# Header
PRINTF_FORMAT="%8s : %s\n"
printf "$PRINTF_FORMAT" "block size" "transfer rate"

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
    DD_RESULT=$(dd if=/dev/zero of=$TEST_FILE bs=$BLOCK_SIZE count=$COUNT conv=fsync 2>&1 1>/dev/null)

    # Extract the transfer rate from dd's STDERR output
    TRANSFER_RATE=$(echo $DD_RESULT | grep -o -E '[0-9.]+ ([MGk]?[Bb]ytes)/s(ec)?')

    # Clean up the test file if we created one
    if [ $TEST_FILE_EXISTS -ne 0 ]; then rm -rf $TEST_FILE; fi

    # Output the result
    printf "$PRINTF_FORMAT" "$BLOCK_SIZE" "$TRANSFER_RATE"
done
