#!/bin/bash

URL="${1}"
SOURCECODE="${2}"

function PushAlert() {
	URL="${1}"
	METHOD="${2}"
	PARAMS="${3}"
	HOME_DIR="$(cd "$(dirname "$0")/../../" ; pwd -P)"
	LOGFILE="${HOME_DIR}/scan-logs/$(echo "${URL}" | sed 's|/| |g' | awk '{print $2}')-issues.log"
	echo "$(date +"[%H:%M:%S]") FATAL: XSS! Potential: Form [${METHOD}] Reflecting (\") on \"${URL}\""
	echo "$(date +"[%H:%M:%S]") HINT: (Form-Data): ${PARAMS}"
	echo "$(date +"[%H:%M:%S]") FATAL: XSS! Potential: Form [${METHOD}] Reflecting (\") on \"${URL}\"" >> ${LOGFILE}
	echo "$(date +"[%H:%M:%S]") HINT: (Form-Data): ${PARAMS}" >> ${LOGFILE}
}

function XSSFormBased() {
	PATHTARGET="${1}"
	SOURCECODE="${2}"

	IFS=$'\n'
	for FORM in $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${PATHTARGET}" | sed ':a;N;$!ba;s/\n/ /g' | perl -nle'print $& while m{<form\K.*?(?=<\/form>)}g')
	do
		TEMPDIR="$(cd "$(dirname "$0")/../../bashter-tempdata" ; pwd -P)"
		PROC_ID=$(echo `date +%Y%m%d%H%M%S`${RANDOM})
		touch "${TEMPDIR}/TESTFORM.TMP"
		FORM_METHOD="${TEMPDIR}/FORM-METHOD_${PROC_ID}.TMP"
		FORM_ACTION="${TEMPDIR}/FORM-ACTION_${PROC_ID}.TMP"
		FORM_INPUTLIST="${TEMPDIR}/FORM-INPUTLIST_${PROC_ID}.TMP"
		if [[ ! -z $(echo $FORM | grep -o 'method=['"'"'"][^"'"'"']*['"'"'"]' | grep -i post) ]]
		then
			echo "Method: POST" > ${FORM_METHOD}
		else
			echo "Method: GET" > ${FORM_METHOD}
		fi
		ACTION=$(echo $FORM | grep -o 'action=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^action=["'"'"']//' -e 's/["'"'"']$//')
		if [[ ! -z ${ACTION} ]]
		then
			echo "Action: ${ACTION}" > ${FORM_ACTION}
		else
			echo "Action: ${PATHTARGET}" > ${FORM_ACTION}
		fi
		i=0
		echo -ne "" > ${FORM_INPUTLIST}
		IFS=$'\n'
		for INPUT in $(echo $FORM | sed 's/>/\\\n/g' | grep '<input')
		do
			NAME=$(echo "${INPUT}" | grep -o 'name=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^name=["'"'"']//' -e 's/["'"'"']$//')
			VALUE=$(echo "${INPUT}" | grep -o 'value=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^value=["'"'"']//' -e 's/["'"'"']$//')
			if [[ -z ${VALUE} ]]
			then
				VALUE="Bashter%22XSS"
			fi
			echo "${NAME}=${VALUE}&" >> ${FORM_INPUTLIST}
		done
		cat ${FORM_METHOD} >> ${FORM_ACTION}
		cat ${FORM_INPUTLIST} | sed ':a;N;$!ba;s/\n//g' | sed 's/&$//g' | sed 's/ /%20/g' >> ${FORM_ACTION}
		#################### Method GET ####################
		if [[ $(cat ${FORM_ACTION} | grep 'Method: GET') ]]
		then
			if [[ $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}') =~ "${PATHTARGET}" ]] || [[ $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}') == "#" ]]
			then
				GETURL=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}')
				PARAMS=$(cat ${FORM_ACTION} | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}?${PARAMS}"
				ATTACK_2="${GETURL}?${PARAMSNOTNULL}"
				if [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_1}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${GETURL}" "GET" "${PARAMS}"
				elif [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${GETURL}" "GET" "${PARAMSNOTNULL}"
				fi
			elif [[ ! -z $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}' | grep ^"[a-zA-Z0-9]" | grep -v ^'http') ]]
			then
				if [[ $(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]") ]]
				then
					CUTHERE=$(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]")
					GETURL=$(echo "${PATHTARGET}" | sed "s/${CUTHERE}//g")
					PATHINJECT=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat ${FORM_ACTION} | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}${PATHINJECT}?${PARAMS}"
					ATTACK_2="${GETURL}${PATHINJECT}?${PARAMSNOTNULL}"
					if [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_1}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${GETURL}${PATHINJECT}" "GET" "${PARAMS}"
					elif [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${GETURL}${PATHINJECT}" "GET" "${PARAMSNOTNULL}"
					fi
				else
					GETURL="$(echo "${PATHTARGET}" | sed 's/\/$//g')"
					PATHINJECT=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat ${FORM_ACTION} | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}/${PATHINJECT}?${PARAMS}"
					ATTACK_2="${GETURL}/${PATHINJECT}?${PARAMSNOTNULL}"
					if [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_1}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${GETURL}/${PATHINJECT}" "GET" "${PARAMS}"
					elif [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${GETURL}/${PATHINJECT}" "GET" "${PARAMSNOTNULL}"
					fi
				fi
			elif [[ ! -z $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}' | grep ^"/") ]]
			then
				GETURL=$(echo "${PATHTARGET}" | sed 's/:\/\//2DOT2SLASH/g' | sed 's/\// /g' | awk '{print $1}' | sed 's/2DOT2SLASH/:\/\//g')
				PATHINJECT=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}' | grep ^"/")
				PARAMS=$(cat ${FORM_ACTION} | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}${PATHINJECT}?${PARAMS}"
				ATTACK_2="${GETURL}${PATHINJECT}?${PARAMSNOTNULL}"
				if [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_1}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${GETURL}${PATHINJECT}" "GET" "${PARAMS}"
				elif [[ $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${GETURL}${PATHINJECT}" "GET" "${PARAMSNOTNULL}"
				fi
			fi
		#################### Method POST ####################
		elif [[ $(cat ${FORM_ACTION} | grep 'Method: POST') ]]
		then
			if [[ $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}') =~ "${PATHTARGET}" ]] || [[ $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}') == "#" ]]
			then
				GETURL=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}')
				PARAMS=$(cat ${FORM_ACTION} | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}"
				ATTACK_2="${GETURL}"
				if [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${GETURL}" "POST" "${PARAMS}"
				elif [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${GETURL}" "POST" "${PARAMSNOTNULL}"
				fi
			elif [[ ! -z $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}' | grep ^"[a-zA-Z0-9]" | grep -v ^'http') ]]
			then
				if [[ $(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]") ]]
				then
					CUTHERE=$(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]")
					GETURL=$(echo "${PATHTARGET}" | sed "s/${CUTHERE}//g")
					PATHINJECT=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat ${FORM_ACTION} | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}${PATHINJECT}"
					ATTACK_2="${GETURL}${PATHINJECT}"
					if [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${ATTACK_1}" "POST" "${PARAMS}"
					elif [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${ATTACK_2}" "POST" "${PARAMSNOTNULL}"
					fi
				else
					GETURL="$(echo "${PATHTARGET}" | sed 's/\/$//g')"
					PATHINJECT=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat ${FORM_ACTION} | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}/${PATHINJECT}?${PARAMS}"
					ATTACK_2="${GETURL}/${PATHINJECT}?${PARAMSNOTNULL}"
					if [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${ATTACK_1}" "POST" "${PARAMS}"
					elif [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${ATTACK_2}" "POST" "${PARAMSNOTNULL}"
					fi
				fi
			elif [[ ! -z $(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}' | grep ^"/") ]]
			then
				GETURL=$(echo "${PATHTARGET}" | sed 's/:\/\//2DOT2SLASH/g' | sed 's/\// /g' | awk '{print $1}' | sed 's/2DOT2SLASH/:\/\//g')
				PATHINJECT=$(cat ${FORM_ACTION} | grep 'Action:' | awk '{print $2}' | grep ^"/")
				PARAMS=$(cat ${FORM_ACTION} | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}${PATHINJECT}?${PARAMS}"
				ATTACK_2="${GETURL}${PATHINJECT}?${PARAMSNOTNULL}"
				if [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${ATTACK_1}" "POST" "${PARAMS}"
				elif [[ ! -z $(curl -skL --connect-timeout 10 --max-time 10 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${ATTACK_2}" "POST" "${PARAMSNOTNULL}"
				fi
			fi
		fi
		rm ${FORM_METHOD}
		rm ${FORM_INPUTLIST}
		rm ${FORM_ACTION}
	done
}

XSSFormBased "${URL}" "${SOURCECODE}"
