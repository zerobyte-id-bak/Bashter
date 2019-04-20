#!/bin/bash

function CORS_Attack() {
	URL="${1}"
	WEBSOURCECODE="${2}"
	if [[ ! -z $(cat ${WEBSOURCECODE} | grep ^'<' | grep -i "access-control-allow") ]]
	then
		curl -vskL -H "Origin: http://evil-example.com/" ${URL} &> CORS-Test.tmp.bshtr
		if [[ ! -z $(cat CORS-Test.tmp.bshtr | grep -i "Access-Control-Allow-Origin") ]] && [[ ! -z $(cat CORS-Test.tmp.bshtr | grep -i " 200 OK") ]];
		then
			echo "$(date +"[%H:%M:%S]") WARN: CORS Missconfiguration on ${URL}"
		fi
		rm CORS-Test.tmp.bshtr
	fi
}

CORS_Attack "${1}" "${2}"
