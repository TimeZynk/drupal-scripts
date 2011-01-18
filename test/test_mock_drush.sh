#!/bin/bash

DRUSH="drush -r ${PWD}/../../htdocs"

setUp() {
	${DRUSH} intellitime-mock-reset-all
}

testAddUser() {
	USER_ID=$(${DRUSH} intellitime-mock-add-user 'kalle' 'kallepw')
	assertNotEquals 'USER_ID not zero' 0 "$USER_ID"
	ALL_USERS=$(${DRUSH} intellitime-mock-list-users)
	assertEquals 'single user' "$USER_ID 'kalle' 'kallepw'" "${ALL_USERS}"
}

testAddAssignment() {
	AID=$(${DRUSH} intellitime-mock-add-assignment 'assignment')
	assertNotEquals 'AID not zero' 0 "$AID"
	ALL_ASSIGNMENTS=$(${DRUSH} intellitime-mock-list-assignments)
	assertEquals 'single assignment' "$AID 'assignment' 0" "${ALL_ASSIGNMENTS}"
}

testAddReport() {
	USER_ID=$(${DRUSH} intellitime-mock-add-user 'kalle' 'kallepw')
	AID=$(${DRUSH} intellitime-mock-add-assignment 'assignment')	
	RID=$(${DRUSH} intellitime-mock-add-report $USER_ID $AID 2010 12 05 08:00 16:30 30 comment with spaces)
	assertTrue 'RID not zero' "[ 0 -lt $RID ]"
	ALL_REPORTS=$(${DRUSH} intellitime-mock-list-reports)
	assertEquals 'single report' "$RID $USER_ID $AID 2010-12-05 08:00 16:30 30 'comment with spaces'" "${ALL_REPORTS}"
}

testAddReportWithoutAssignment() {
	USER_ID=$(${DRUSH} intellitime-mock-add-user 'kalle' 'kallepw')
	RID=$(${DRUSH} intellitime-mock-add-report $USER_ID title 2010 12 05 08:00 16:30 30 comment with spaces)
	assertTrue 'RID not zero' "[ 0 -lt $RID ]"
	ALL_REPORTS=$(${DRUSH} intellitime-mock-list-reports)
	assertEquals 'single report' "$RID $USER_ID 'title' 2010-12-05 08:00 16:30 30 'comment with spaces'" "${ALL_REPORTS}"
}

source ../../../external/shunit/src/shell/shunit2