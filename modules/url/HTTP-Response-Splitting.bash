#!/bin/bash

function HTTPResponseSplit() {
	URL="${1}"
	SOURCECODE="${2}"
	HOME_DIR="$(cd "$(dirname "$0")/../../" ; pwd -P)"
	TEMPDIR="${HOME_DIR}/bashter-tempdata"
	TEMPFILE="${TEMPDIR}/CRLF-Injection-TEST-$(date +%Y%m%d%H%M%S)${RANDOM}.TMP"
	LOGFILE="${HOME_DIR}/scan-logs/$(echo "${URL}" | sed 's|/| |g' | awk '{print $2}')-issues.log"

	ATTACK=$(curl -vskL --connect-timeout 5 --max-time 5 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${URL}/%0A%0Dx-evilheader:%20whatever" &> ${TEMPFILE})
	if [[ ! -z $(cat ${TEMPFILE} | grep ^'< x-evilheader:' | grep 'whatever' | grep -v '%0A%0D') ]]
	then
		echo "$(date +"[%H:%M:%S]") FATAL: HTTP Response Splitting! on \"${URL}\""
		echo "$(date +"[%H:%M:%S]") FATAL: HTTP Response Splitting! on \"${URL}\"" >> ${LOGFILE}
	fi
	rm ${TEMPFILE}
}

HTTPResponseSplit "${1}" "${2}"
