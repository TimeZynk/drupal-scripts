#!/bin/bash

# Kills all spawned jobs
function killJobs {
    kill -TERM $(jobs -p)
    FINISH=$(date +%s)
    echo "Synchronization killed after" $(( FINISH - START )) "seconds"
    exit 1
}

function runDrupalSync {
    users=$1
    now=$(date +%s)
    if ! $DRUSH_CMD intellitime-sync "$users"; then
		echo "  synchronization command failed!"
    fi
}

# Otherwise we will be doing string conversion.
function sync {
    users="$1"
    nbr_of_threads=0
    # TODO: Check users for empty..
    for user_set in ${users//;/ } ; do 
        runDrupalSync "$user_set" &
        (( nbr_of_threads++ ))
    done
    echo "  started $nbr_of_threads threads"
}

# Main body
if [ $# -ne 2 ] ; then
    echo "Usage: $0 drupal-root site-URI"
    exit 2
fi

START=$(date +%s)
echo "Starting sync in $1 for $2"

## Register a trap function to kill all spawned jobs.
trap killJobs INT
trap killJobs TERM

DRUSH_CMD="drush -r $1 -l $2"

# TODO: fetch users from drupal.
users=$($DRUSH_CMD intellitime-partition)
sync "${users}"

## Wait for all children. We rely on our parent to kill us if need be.
wait
FINISH=$(date +%s)
echo "Synchronization finished in" $(( FINISH - START )) "seconds"