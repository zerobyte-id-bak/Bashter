#!/bin/bash

function CORS_Attack() {
	URL="${1}"
	SOURCECODE="${2}"

	HOME_DIR="$(cd "$(dirname "$0")/../../" ; pwd -P)"
	TEMPDIR="${HOME_DIR}/bashter-tempdata"
	TEMPFILE="${TEMPDIR}/CORS-TEST-$(date +%Y%m%d%H%M%S)${RANDOM}.TMP"
	LOGFILE="${HOME_DIR}/scan-logs/$(echo "${URL}" | sed 's|/| |g' | awk '{print $2}')-issues.log"

	if [[ ! -z $(cat ${SOURCECODE} | grep ^'<' | grep -i "access-control-allow") ]]
	then
		curl -vskL -H "Origin: http://evil-example.com/" -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" ${URL} &> ${TEMPFILE}
		if [[ ! -z $(cat ${TEMPFILE} | grep ^'<' | grep -i "Access-Control-Allow-Origin") ]] && [[ ! -z $(cat ${TEMPFILE} | grep -i " 200 OK") ]];
		then
			echo "$(date +"[%H:%M:%S]") WARN: CORS Missconfigured on \"${URL}\""
			echo "$(date +"[%H:%M:%S]") WARN: CORS Missconfigured on \"${URL}\"" >> ${LOGFILE}
		fi
		rm ${TEMPFILE}
	fi
}

CORS_Attack "${1}" "${2}"
