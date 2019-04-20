#!/bin/bash

function PushAlert() {
	URL="${1}"
	echo "$(date +"[%H:%M:%S]") FATAL: XSS! (Potential), URL injectable with (\") on \"${URL}\""
}

function XSS_UrlReflected() {
	URL="${1}"
	WEBSOURCECODE="${2}"
	if [[ $(echo "${URL}" | grep '?' | grep '&') ]]
	then
		TESTATTACK=$(echo "${URL}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
		if [[ ! -z $(curl -skL --connect-timeout 5 --max-time 5 "${TESTATTACK}" | grep 'Bashter"XSS') ]]
		then
			PushAlert "${URL}"
		fi
	else
		if [[ ! -z $(curl -skL --connect-timeout 5 --max-time 5 "${URL}/Bashter%22XSS" | grep 'Bashter"XSS') ]]
		then
			PushAlert "${URL}"
		fi
	fi
}

XSS_UrlReflected "${1}" "${2}"
