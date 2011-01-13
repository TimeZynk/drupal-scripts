#!/bin/bash

# Kills all spawned jobs
function killJobs {
    kill -TERM $(jobs -p)
    exit 1
}

syncSite() {
	site="$1"
	# Check if tzintellitime is enabled
	enabled=$($DRUSH -l "$site" php-eval 'print(module_exists("tzintellitime"));')
	if [ "x$enabled" = "x1" ]; then
		echo "Checking $site: enabled"
		nice "$CALL_ROOT/fork_sync.sh" "$DRUPAL_ROOT" "$site"
	else
		echo "Checking $site: disabled"
	fi
}

if [ $# -ne 2 ] || [ $2 -lt 0 ]; then
	echo "usage: $0 <drupal-root> <timeout in seconds>"
	exit 2
fi

export CALL_ROOT=$(dirname "$0")
export DRUPAL_ROOT="$1"
export DRUSH="drush -r $DRUPAL_ROOT"
TIMEOUT="$2"

## Register a trap function to kill all spawned jobs.
trap killJobs INT
trap killJobs TERM

for dir in "$DRUPAL_ROOT"/sites/*; do
	if [ -r "${dir}/settings.php" ]; then
		syncSite $(basename "$dir") &
	fi
done

sync_jobs=$(jobs -p)

# Start monitoring process that kills us if timeout is exceeded
(
	sleep "$TIMEOUT"
	# Check if main process is already dead
	kill -0 $$ || exit 0
	echo "Timeout of $TIMEOUT seconds expired, killing jobs"
	# Timeout expired, kill using SIGTERM
	kill -TERM $$
) 2> /dev/null &

wait $sync_jobs