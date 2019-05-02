#!/bin/bash

function OpenRedirectViaURL() {
	URL="${1}"
	SOURCECODE="${2}"

	HOME_DIR="$(cd "$(dirname "$0")/../../" ; pwd -P)"
	TEMPDIR="${HOME_DIR}/bashter-tempdata"
	TEMPFILE="${TEMPDIR}/Open-Redirect-TEST-$(date +%Y%m%d%H%M%S)${RANDOM}.TMP"
	LOGFILE="${HOME_DIR}/scan-logs/$(echo "${URL}" | sed 's|/| |g' | awk '{print $2}')-issues.log"

	if [[ ! -z $(echo ''${URL}'' | grep '=http') ]];
	then
		URL_ATTACK1=$(echo "${URL}" | sed 's/=http.*\&/=https:\/\/bit.ly\/2ZC4elx\&/g')
		URL_ATTACK2=$(echo "${URL}" | sed 's/=http.*$/=https:\/\/bit.ly\/2ZC4elx/g')
		if [[ ${URL_ATTACK1} =~ "2ZC4elx" ]]
		then
			ATTACK=$(curl -vskL --connect-timeout 5 --max-time 5 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${URL_ATTACK1}" &> ${TEMPFILE})
			if [[ ! -z $(cat ${TEMPFILE} | grep -i '< location' | grep 'bit.ly/2ZC4elx') ]]
			then
				echo "$(date +"[%H:%M:%S]") FATAL: Open Redirect! on \"${URL}\""
				echo "$(date +"[%H:%M:%S]") FATAL: Open Redirect! on \"${URL}\"" >> ${LOGFILE}
			fi
			rm ${TEMPFILE}
		elif [[ ${URL_ATTACK2} =~ "2ZC4elx" ]]
		then
			ATTACK=$(curl -vskL --connect-timeout 5 --max-time 5 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${URL_ATTACK2}" &> ${TEMPFILE})
			if [[ ! -z $(cat ${TEMPFILE} | grep -i '< location' | grep 'bit.ly/2ZC4elx') ]]
			then
				echo "$(date +"[%H:%M:%S]") FATAL: Open Redirect! on \"${URL}\""
				echo "$(date +"[%H:%M:%S]") FATAL: Open Redirect! on \"${URL}\"" >> ${LOGFILE}
			fi
			rm ${TEMPFILE}
		fi
	fi
}

OpenRedirectViaURL "${1}" "${2}"
