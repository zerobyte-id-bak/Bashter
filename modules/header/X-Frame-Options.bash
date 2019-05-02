#!/bin/bash

function XFrameOptions() {
	URL="${1}"
	SOURCECODE="${2}"
	
	HOME_DIR="$(cd "$(dirname "$0")/../../" ; pwd -P)"
	LOGFILE="${HOME_DIR}/scan-logs/$(echo "${URL}" | sed 's|/| |g' | awk '{print $2}')-issues.log"
	if [[ -z $(cat ${SOURCECODE} | grep ^'<' | grep -i x-frame-options) ]];
	then
		echo "$(date +"[%H:%M:%S]") WARN: X-Frame-Options on \"${URL}\" is not present"
		echo "$(date +"[%H:%M:%S]") WARN: X-Frame-Options on \"${URL}\" is not present" >> ${LOGFILE}
	fi
}

XFrameOptions "${1}" "${2}"
