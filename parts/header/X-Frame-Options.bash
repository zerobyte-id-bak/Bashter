#!/bin/bash

function XFrameOptions() {
	URL=${1}
	WEBSOURCECODE=${2}
	if [[ -z $(cat ${WEBSOURCECODE} | grep ^'<' | grep -i x-frame-options) ]];
	then
		echo "$(date +"[%H:%M:%S]") WARN: X-Frame-Options on \"${URL}\" is not present"
	fi
}

XFrameOptions "${1}" "${2}"
