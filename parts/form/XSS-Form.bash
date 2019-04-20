#!/bin/bash

URL="${1}"
WEBSOURCECODE="${2}"

function PushAlert() {
	URL="${1}"
	echo "$(date +"[%H:%M:%S]") FATAL: XSS! (Potential), FORM injectable with (\") on \"${URL}\""
}

function XSSFormBased() {
	PATHTARGET="${1}"
	IFS=$'\n'
	for FORM in $(curl -skL "${PATHTARGET}" | sed ':a;N;$!ba;s/\n/ /g' | grep -Po '<form\K.*?(?=<\/form>)')
	do
		if [[ ! -z $(echo $FORM | grep -o 'method=['"'"'"][^"'"'"']*['"'"'"]' | grep -i post) ]]
		then
			echo "Method: POST" > formlisttmp.bshtr
		else
			echo "Method: GET" > formlisttmp.bshtr
		fi

		ACTION=$(echo $FORM | grep -o 'action=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^action=["'"'"']//' -e 's/["'"'"']$//')
		if [[ ! -z ${ACTION} ]]
		then
			echo "Action: ${ACTION}" > formattacktmp.bshtr
		else
			echo "Action: ${PATHTARGET}" > formattacktmp.bshtr
		fi
		i=0
		> forminputtmp.bshtr
		IFS=$'\n'
		for INPUT in $(echo $FORM | sed 's/>/\\\n/g' | grep '<input')
		do
			NAME=$(echo "${INPUT}" | grep -o 'name=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^name=["'"'"']//' -e 's/["'"'"']$//')
			VALUE=$(echo "${INPUT}" | grep -o 'value=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^value=["'"'"']//' -e 's/["'"'"']$//')
			if [[ -z ${VALUE} ]]
			then
				VALUE="Bashter%22XSS"
			fi
			echo "${NAME}=${VALUE}&" >> forminputtmp.bshtr
		done
		cat formlisttmp.bshtr >> formattacktmp.bshtr
		cat forminputtmp.bshtr | sed ':a;N;$!ba;s/\n//g' | sed 's/&$//g' | sed 's/ /%20/g' >> formattacktmp.bshtr

		#################### Method GET ####################
		if [[ $(cat formattacktmp.bshtr | grep 'Method: GET') ]]
		then
			if [[ $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}') =~ "${PATHTARGET}" ]] || [[ $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}') == "#" ]]
			then
				GETURL=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}')
				PARAMS=$(cat formattacktmp.bshtr | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}?${PARAMS}"
				ATTACK_2="${GETURL}?${PARAMSNOTNULL}"
				if [[ $(curl -skL "${ATTACK_1}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${PATHTARGET}" "GET"
				elif [[ $(curl -skL "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${PATHTARGET}" "GET"
				fi
			elif [[ ! -z $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}' | grep ^"[a-zA-Z0-9]" | grep -v ^'http') ]]
			then
				if [[ $(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]") ]]
				then
					CUTHERE=$(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]")
					GETURL=$(echo "${PATHTARGET}" | sed "s/${CUTHERE}//g")
					PATHINJECT=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat formattacktmp.bshtr | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}${PATHINJECT}?${PARAMS}"
					ATTACK_2="${GETURL}${PATHINJECT}?${PARAMSNOTNULL}"
					if [[ $(curl -skL "${ATTACK_1}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${PATHTARGET}" "GET"
					elif [[ $(curl -skL "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${PATHTARGET}" "GET"
					fi
				else
					GETURL="$(echo "${PATHTARGET}" | sed 's/\/$//g')"
					PATHINJECT=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat formattacktmp.bshtr | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}/${PATHINJECT}?${PARAMS}"
					ATTACK_2="${GETURL}/${PATHINJECT}?${PARAMSNOTNULL}"
					if [[ $(curl -skL "${ATTACK_1}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${PATHTARGET}" "GET"
					elif [[ $(curl -skL "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${PATHTARGET}" "GET"
					fi
				fi
			elif [[ ! -z $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}' | grep ^"/") ]]
			then
				GETURL=$(echo "${PATHTARGET}" | sed 's/:\/\//2DOT2SLASH/g' | sed 's/\// /g' | awk '{print $1}' | sed 's/2DOT2SLASH/:\/\//g')
				PATHINJECT=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}' | grep ^"/")
				PARAMS=$(cat formattacktmp.bshtr | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}${PATHINJECT}?${PARAMS}"
				ATTACK_2="${GETURL}${PATHINJECT}?${PARAMSNOTNULL}"
				if [[ $(curl -skL "${ATTACK_1}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${PATHTARGET}" "GET"
				elif [[ $(curl -skL "${ATTACK_2}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${PATHTARGET}" "GET"
				fi
			fi

		#################### Method POST ####################
		elif [[ $(cat formattacktmp.bshtr | grep 'Method: POST') ]]
		then
			if [[ $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}') =~ "${PATHTARGET}" ]] || [[ $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}') == "#" ]]
			then
				GETURL=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}')
				PARAMS=$(cat formattacktmp.bshtr | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}"
				ATTACK_2="${GETURL}"
				if [[ ! -z $(curl -skL -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${PATHTARGET}" "POST"
				elif [[ ! -z $(curl -skL -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${PATHTARGET}" "POST"
				fi
			elif [[ ! -z $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}' | grep ^"[a-zA-Z0-9]" | grep -v ^'http') ]]
			then
				if [[ $(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]") ]]
				then
					CUTHERE=$(echo "${PATHTARGET}" | awk -F '/' '{print $NF}' | grep "[.]")
					GETURL=$(echo "${PATHTARGET}" | sed "s/${CUTHERE}//g")
					PATHINJECT=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat formattacktmp.bshtr | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}${PATHINJECT}"
					ATTACK_2="${GETURL}${PATHINJECT}"
					if [[ ! -z $(curl -skL -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${PATHTARGET}" "POST"
					elif [[ ! -z $(curl -skL -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${PATHTARGET}" "POST"
					fi
				else
					GETURL="$(echo "${PATHTARGET}" | sed 's/\/$//g')"
					PATHINJECT=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}')
					PARAMS=$(cat formattacktmp.bshtr | tail -1)
					PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
					ATTACK_1="${GETURL}/${PATHINJECT}?${PARAMS}"
					ATTACK_2="${GETURL}/${PATHINJECT}?${PARAMSNOTNULL}"
					if [[ ! -z $(curl -skL -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
					then
						PushAlert "${PATHTARGET}" "POST"
					elif [[ ! -z $(curl -skL -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
						PushAlert "${PATHTARGET}" "POST"
					fi
				fi
			elif [[ ! -z $(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}' | grep ^"/") ]]
			then
				GETURL=$(echo "${PATHTARGET}" | sed 's/:\/\//2DOT2SLASH/g' | sed 's/\// /g' | awk '{print $1}' | sed 's/2DOT2SLASH/:\/\//g')
				PATHINJECT=$(cat formattacktmp.bshtr | grep 'Action:' | awk '{print $2}' | grep ^"/")
				PARAMS=$(cat formattacktmp.bshtr | tail -1)
				PARAMSNOTNULL=$(echo "${PARAMS}" | sed 's/=\([a-zA-Z0-9]*\)$/=\1Bashter%22XSS/g' | sed 's/=\([a-zA-Z0-9]*\)\&/=\1Bashter%22XSS\&/g')
				ATTACK_1="${GETURL}${PATHINJECT}?${PARAMS}"
				ATTACK_2="${GETURL}${PATHINJECT}?${PARAMSNOTNULL}"
				if [[ ! -z $(curl -skL -X POST "${ATTACK_1}" --data "${PARAMS}" | grep 'Bashter"XSS') ]]
				then
					PushAlert "${PATHTARGET}" "POST"
				elif [[ ! -z $(curl -skL -X POST "${ATTACK_2}" --data "${PARAMSNOTNULL}" | grep 'Bashter"XSS') ]]; then
					PushAlert "${PATHTARGET}" "POST"
				fi
			fi
		fi
	done
	rm formlisttmp.bshtr
	rm forminputtmp.bshtr
	rm formattacktmp.bshtr
}

XSSFormBased "${URL}" "${WEBSOURCECODE}"
