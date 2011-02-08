#!/bin/bash

drupal_root="${PWD}/../../htdocs"
DRUSH="drush -r ${drupal_root}"

delay=20

setUp() {
	${DRUSH} intellitime-mock-reset-all
	${DRUSH} vset --yes tzintellitime_mock_delay_millis 0 &
	${DRUSH} vset --yes tzintellitime_sync_interval_minutes 0 &
	${DRUSH} vset --yes tzintellitime_mock_enable_comments 1 &
	tmp_url=$(${DRUSH} vget tzintellitime_base_url)
	old_base_url=${tmp_url/tzintellitime_base_url: /}
	${DRUSH} vset --yes tzintellitime_base_url "http://localhost/IntelliplanWeb/Portal/Login.aspx" &

	# Disable any existing users scheduled by live module...(Not needed when site is cleaned between test runs.)
	${DRUSH} intellitime-set-all-active 0 &

	wait
	users=''
	for ((i=0; i<10; i++)) ; do
		user_id=$(${DRUSH} intellitime-mock-add-user "user$i" "userpw$i")
		users+="$user_id "
	done
	wait
	${DRUSH} intellitime-mock-schedule-all
	ASS=$(${DRUSH} intellitime-mock-add-assignment 'assignment')
	echo "Users: $users"
	for user in $users ; do
		${DRUSH} intellitime-mock-add-report $user $ASS 2010 12 05 08:00 16:30 30 comment &
		${DRUSH} intellitime-mock-add-report $user 'leave' 2010 12 06 08:00 16:30 30 another comment &
	done
	wait
}

tearDown() {
	${DRUSH} intellitime-mock-reset-all
	${DRUSH} vset --yes tzintellitime_base_url "${old_base_url//\"/}"

}

testSingleThreadSyncFromMock() {
	${DRUSH} vset --yes tzintellitime_sync_parallel_threads 1
	partition=$(${DRUSH} intellitime-partition)
	echo ${partition} | grep -qv ";"
	assertTrue 'single-thread partition' $?
	assert_successful_sync "$partition"
}

testMultiThreadSyncFromMock() {
	${DRUSH} vset --yes tzintellitime_sync_parallel_threads 2
	partition=$(${DRUSH} intellitime-partition)
	echo ${partition} | grep -q ";"
	assertTrue 'multi-thread partition' $?
	assert_successful_sync "$partition"
}

function assert_successful_sync() {
    partition=$1
    query="SELECT COUNT(n.nid) FROM node n INNER JOIN tzreport t ON n.vid = t.vid WHERE t.flags != 255 AND (t.assignedto = "
    query+="${partition//[,;]/ OR t.assignedto = })"

    drupal_users="${partition//[,;]/ }"
    assertEquals 'must have 10 users' 10 $(echo ${drupal_users} | wc -w) || return

    assert_report_count "$query" 0

    ${DRUSH} vset --yes tzintellitime_mock_delay_millis "$delay"
    run_sync
    
    assert_report_count "$query" 20

    echo "Changing 1 report per user on drupal side"
    for drupal_user in $drupal_users ; do
	report_nid=$(${DRUSH} -u ${drupal_user} tzbase-list-reports |tail -n1)
	${DRUSH} tzbase-edit-report ${report_nid}  09:00 08:35 &
    done
    wait

    run_sync
    
    changed_count=$(${DRUSH} intellitime-mock-list-reports | grep -c "09:00 08:35")
    assertEquals '10 reports should be changed in mock' 10 $changed_count

    assert_report_count "$query" 20
}

function run_sync() {
	echo "Starting sync"
	sync_time=$(../fork_sync.sh "${drupal_root}" "http://localhost/" | grep "finished in")
	sync_time=$(echo "$sync_time" | sed 's/[^0-9]*//g')
	echo "Sync time: $sync_time"
}

function assert_report_count() {
    query=$1
    expected_count=$2
    report_count=$(echo "$query" | ${DRUSH} sqlc | tail -n1)
    assertEquals "should have $expected_count reports" $expected_count "$report_count"
    echo "Report count: $report_count"
}

source ../../../external/shunit/src/shell/shunit2
