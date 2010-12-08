#!/bin/bash

# Kills all spawned jobs
function killJobs {
    jobs
    kill -TERM $(jobs -p)
    exit 1
}

function runDrupalSync {
    users=$1
    uri=$2
    for user in ${users//,/ } ; do
	echo "Synching user ${user} @ $uri"
	# Replace w. call to drupal sync..
	sleep 3
    done
}

# Otherwise we will be doing string conversion.
function sync {
    users="$1"
    uri="$2" 
    # TODO: Check users for empty..
    for user_set in ${users//;/ } ; do 
	echo "User set: $user_set"
	runDrupalSync "$user_set" "$uri" &
    done
}

# Main body
if [ $# -ne 1 ] ; then
    echo "Usage: $0 site-URI"
    exit 2
fi

echo "Entering sync paralleliser"

## Register a trap function to kill all spawned jobs.
trap killJobs INT
trap killJobs TERM

# TODO: fetch users from drupal.
users="1,2,3,4,5,6,7,8,9;10,11,12,13,14,15,16;23,41,8438"
sync "${users}" "$1"

## Wait for all children. We rely on our parent to kill us if need be.
wait