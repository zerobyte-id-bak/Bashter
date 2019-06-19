#!/bin/bash

HOME_DIR="$(cd "$(dirname "$0")" ; pwd -P)"
BASHTER_VERSION="4.1"
RELEASED_DATE="1 May 2019"

function UrlSelector() {
	WEBSITE="${1}"
	URL="${2}"
	SOURCECODE="${3}"
	URL_SELECTOR_MODE="${4}"

	if [[ ${URL_SELECTOR_MODE} == "y" ]] || [[ ${URL_SELECTOR_MODE} == "Y" ]]
	then
		BASESITE=$(echo "${WEBSITE}" | sed 's|/| |g' | awk '{print $2}' | awk -F '.' '{print $(NF - 1)"."$NF}')
	else
		BASESITE=$(echo "${WEBSITE}" | sed 's|/| |g' | awk '{print $2}')
	fi

	if [[ ! -z $(echo "${URL}" | grep ^"javascript:\|mailto:\|tel:\|data:") ]]
	then
		echo -ne ""
	elif [[ ! -z $(echo "${URL}" | grep -i "[.]pdf\|[.]doc\|docx\|[.]png\|[.]gif\|[.]jpg\|[.]jpeg\|[.]ico\|[.]svg\|[.]css\|[.]js\|[.]woff") ]]
	then
		echo -ne ""
	elif [[ ! -z $(echo "${URL}" | grep ^'//') ]]
	then
		if [[ $(echo "${WEBSITE}" | grep ^'https://') ]] && [[ $(echo "${URL}" | grep ^"//[a-zA-Z0-9.]*.${BASESITE}") ]]
		then
			echo "[GET] https:${URL}"
		fi
	elif [[ ! -z $(echo "${URL}" | grep ^"/") ]]
	then
		WEBSITE=$(echo "${WEBSITE}" | sed 's|://|P12O70COL|g' | sed 's|/| |g' | awk '{print $1}' | sed 's|P12O70COL|://|g')
		FULLURL=$(echo "${WEBSITE}/${URL}" | sed 's|://|P12O70COL|g' | sed 's,/*/,/,g' | sed 's|P12O70COL|://|g')
		echo "[GET] ${FULLURL}"
	elif [[ ! -z $(echo "${URL}" | grep ^'?') ]]
	then
		WEBSITE=$(echo "${WEBSITE}" | sed 's|://|P12O70COL|g' | sed 's|/| |g' | awk '{print $1}' | sed 's|P12O70COL|://|g')
		FULLURL=$(echo "${WEBSITE}/${URL}" | sed 's|://|P12O70COL|g' | sed 's,/*/,/,g' | sed 's|P12O70COL|://|g')
		echo "[GET] ${FULLURL}"
	elif [[ ! -z $(echo "${URL}" | grep ^"\(http\|https\)://[a-zA-Z0-9.]*.${BASESITE}") ]]
	then
		echo "[GET] ${URL}"
	elif [[ ! -z $(echo "${URL}" | grep ^'#') ]]
	then
		echo -ne ""
	elif [[ ! -z $(echo "${URL}" | grep ^"[a-zA-Z0-9-]*://" | grep -v ^'http') ]]
	then
		echo -ne ""
	else
		echo -ne ""
	fi
}

function UrlCrawler() {
	SOURCECODE="${1}"
	cat ${SOURCECODE} | grep -o 'href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^href=["'"'"']//' -e 's/["'"'"']$//'
	cat ${SOURCECODE} | grep -o 'src=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^src=["'"'"']//' -e 's/["'"'"']$//'
}

function CheckForm() {
	URL="${1}"
	SOURCECODE="${2}"
	PROC_ID="${3}"
	HOME_DIR="$(cd "$(dirname "$0")" ; pwd -P)"
	TEMPDIR="${HOME_DIR}/bashter-tempdata"
	CHECKEDFORMFILE="${TEMPDIR}/CHECKED-FORM.BASHTER-${PROC_ID}.TMP"
	IFS=$'\n'
	for FORM in $(cat ${SOURCECODE} | perl -nle'print $& while m{<form\K.*?(?=>)}g' | sed 's/^/<form/g' | sed 's/$/>/g')
	do
		FORMPOST=$(echo $FORM | grep -o 'method=['"'"'"][^"'"'"']*['"'"'"]' | grep -i post)
		if [[ ! -z $(cat ${CHECKEDFORMFILE} 2> /dev/null | grep ''$FORM'') ]]
		then
			echo -ne ""
		elif [[ -z ${FORMPOST} ]]
		then
			echo "$(date +"[%H:%M:%S]") INFO: Form GET on \"${URL}\""
			echo "$(date +"[%H:%M:%S]") FORM [GET]: \"${URL}\"" >> ${HOME_DIR}/scan-logs/${PROC_ID}-info.log
				for FORM_TEST in $(find ${HOME_DIR}/modules/form | grep bash$)
				do
					if [[ ! -z ${FORM_TEST} ]]
					then
						bash ${FORM_TEST} ${URL} ${SOURCECODE}
					fi
				done
		else 
			echo "$(date +"[%H:%M:%S]") INFO: Form POST on \"${URL}\""
			echo "$(date +"[%H:%M:%S]") FORM [POST]: \"${URL}\"" >> ${HOME_DIR}/scan-logs/${PROC_ID}-info.log
				for FORM_TEST in $(find ${HOME_DIR}/modules/form | grep bash$)
				do
					if [[ ! -z ${FORM_TEST} ]]
					then
						bash ${FORM_TEST} ${URL} ${SOURCECODE}
					fi
				done
		fi
		echo ${FORM} >> ${CHECKEDFORMFILE}
	done
}

if [[ -z ${HOME_DIR} ]]
then
	echo "ERROR: Can't define HOME_DIR"
	exit
elif [[ ! -d ${HOME_DIR} ]]
then
	echo "ERROR: ${HOME_DIR} not found"
	exit
fi

cat ${HOME_DIR}/BANNER.file
echo ""
echo "  ##### Version ${BASHTER_VERSION} released on ${RELEASED_DATE} #####"
echo " [ $(hostname)@HOME_DIR : ${HOME_DIR} ]"
echo ""

echo " Please enter the URL you want to scan..."
echo " Example: https://website.com/[optional-path]/"
echo -ne " >>> "
read WEBSITE
echo ""
echo " Crawling site based on main domain or domain which you scan only"
echo " If you want to scan *.domain.com you can enter: [Y/y]"
echo " But If you want to scan sub.domain.com only (let it empty)"
echo -ne " >>> "
read URL_SELECTOR_MODE
echo ""

if [[ -z ${WEBSITE} ]]
then
	echo "ERROR: Website can't empty!"
	exit
elif [[ -z $(echo "${WEBSITE}" | grep ^"\(http\|https\)://") ]]
then
	echo "ERROR: ${WEBSITE} must using [HTTP/HTTPS]"
	exit
fi
TEMPDIR="${HOME_DIR}/bashter-tempdata"
if [[ ! -d ${TEMPDIR} ]]
then
	mkdir ${TEMPDIR}
fi
if [[ ! -d ${TEMPDIR} ]]
then
	echo "ERROR: Can't make directory \"${TEMPDIR}\" on \"$(pwd)\""
	exit
fi

PROC_ID="$(echo "${WEBSITE}" | sed 's|/| |g' | awk '{print $2}')"
CURRENT_TEMPFILE="${TEMPDIR}/"$(echo "SOURCECODE.BASHTER-PROC_$(date +%Y%m%d%H%M%S)${RANDOM}.TMP")
URL_LIST="${TEMPDIR}/URL-LISTS.BASHTER-${PROC_ID}.TMP"
SCANNED_URL="${TEMPDIR}/SCANNED-URL.BASHTER-${PROC_ID}.TMP"

curl -vskL --connect-timeout 5 --max-time 5 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${WEBSITE}" &> ${CURRENT_TEMPFILE}

if [[ ! -z $(cat ${CURRENT_TEMPFILE} | grep ^'* Could not resolve host:') ]]
then
	echo "ERROR: Could not resolve host: ${WEBSITE}"
	exit
fi

echo "$(date +"[%H:%M:%S]")(Scan) ${WEBSITE}..."
LOGNAME=$(echo "${WEBSITE}" | sed 's|/| |g' | awk '{print $2}')
echo "$(date +"[%H:%M:%S]") URL [Scanned]: \"${WEBSITE}\"" >> ${HOME_DIR}/scan-logs/${LOGNAME}-info.log
CheckForm "${WEBSITE}" "${CURRENT_TEMPFILE}" "${PROC_ID}"
for HEADER_ANALYZE in $(find ${HOME_DIR}/modules/header | grep bash$)
do
	if [[ ! -z ${HEADER_ANALYZE} ]]
	then
		bash ${HEADER_ANALYZE} "${WEBSITE}" "${CURRENT_TEMPFILE}" "${PROC_ID}"
	fi
done
for URL_ANALYZE in $(find ${HOME_DIR}/modules/url | grep bash$)
do
	if [[ ! -z ${URL_ANALYZE} ]]
	then
		bash ${URL_ANALYZE} "${WEBSITE}" "${CURRENT_TEMPFILE}" "${PROC_ID}"
	fi
done

echo -ne "" > ${URL_LIST}
for URL in $(UrlCrawler ${CURRENT_TEMPFILE})
do
	URLTEMP=$(UrlSelector ${WEBSITE} ${URL} ${CURRENT_TEMPFILE} ${URL_SELECTOR_MODE} | awk '{print $2}')
	if [[ ! -z ${URLTEMP} ]]
	then
		if [[ -z $(cat ${URL_LIST} | grep "${URLTEMP}"$) ]]
		then
			UrlSelector ${WEBSITE} ${URL} ${CURRENT_TEMPFILE} ${URL_SELECTOR_MODE} >> ${URL_LIST}
		fi
	fi
done
cat ${URL_LIST} | sort -nr | uniq > ${URL_LIST}.XTMP
cat ${URL_LIST}.XTMP > ${URL_LIST}
rm ${URL_LIST}.XTMP
rm ${CURRENT_TEMPFILE}
echo "${WEBSITE}" > ${SCANNED_URL}

########## INFINITE LOOP CRAWLING ##########
CMPCHECKPOINT=0
while true
do
	for WEBSITE in $(cat ${URL_LIST} | awk '{print $2}')
	do
		if [[ -z $(cat ${SCANNED_URL} | grep "${WEBSITE}"$) ]]
		then
			echo "$(date +"[%H:%M:%S]")(Scan) ${WEBSITE}..."
			LOGNAME=$(echo "${WEBSITE}" | sed 's|/| |g' | awk '{print $2}')
			echo "$(date +"[%H:%M:%S]") URL [Scanned]: \"${WEBSITE}\"" >> ${HOME_DIR}/scan-logs/${LOGNAME}-info.log
			CURRENT_TEMPFILE="${TEMPDIR}/"$(echo "SOURCECODE.BASHTER-PROC_$(date +%Y%m%d%H%M%S)${RANDOM}.TMP")
			curl -vskL --connect-timeout 5 --max-time 5 -A "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" "${WEBSITE}" &> ${CURRENT_TEMPFILE}
			CheckForm "${WEBSITE}" "${CURRENT_TEMPFILE}" "${PROC_ID}"
			for HEADER_ANALYZE in $(find ${HOME_DIR}/modules/header | grep bash$)
			do
				if [[ ! -z ${HEADER_ANALYZE} ]]
				then
					bash ${HEADER_ANALYZE} "${WEBSITE}" "${CURRENT_TEMPFILE}" "${PROC_ID}"
				fi
			done
			for URL_ANALYZE in $(find ${HOME_DIR}/modules/url | grep bash$)
			do
				if [[ ! -z ${URL_ANALYZE} ]]
				then
					bash ${URL_ANALYZE} "${WEBSITE}" "${CURRENT_TEMPFILE}" "${PROC_ID}"
				fi
			done
			for URL in $(UrlCrawler ${CURRENT_TEMPFILE})
			do
				URLTEMP=$(UrlSelector ${WEBSITE} ${URL} ${CURRENT_TEMPFILE} ${URL_SELECTOR_MODE} | awk '{print $2}')
				if [[ ! -z ${URLTEMP} ]]
				then
					if [[ -z $(cat ${URL_LIST} | grep "${URLTEMP}"$) ]]
					then
						UrlSelector ${WEBSITE} ${URL} ${CURRENT_TEMPFILE} ${URL_SELECTOR_MODE} >> ${URL_LIST}
					fi
				fi
			done
			cat ${URL_LIST} | sort -nr | uniq > ${URL_LIST}.XTMP
			cat ${URL_LIST}.XTMP > ${URL_LIST}
			rm ${URL_LIST}.XTMP
			echo "${WEBSITE}" >> ${SCANNED_URL}
			rm ${CURRENT_TEMPFILE}
			if [[ $(cat ${URL_LIST} | wc -l) -eq $(cat ${URL_LIST} | sort -nr | uniq | wc -l) ]]
			then
				echo -ne ""
			else
				cat ${URL_LIST} | sort -nr | uniq > ${URL_LIST}.XTMP
				cat ${URL_LIST}.XTMP > ${URL_LIST}
				rm ${URL_LIST}.XTMP
				break
			fi
		fi
	done
	CMPCOMPARISON=$(cat ${SCANNED_URL} | wc -l)
	if [[ ${CMPCHECKPOINT} -eq ${CMPCOMPARISON} ]];
	then
		break
	else
		CMPCHECKPOINT=${CMPCOMPARISON}
	fi
done

rm ${SCANNED_URL}
