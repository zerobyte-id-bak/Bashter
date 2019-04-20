#!/bin/bash

BASHTER_CONFIG="/path-to/CONFIG.bash"

NC=$(command -v nc)
WGET=$(command -v wget)


. ${BASHTER_CONFIG}
echo -ne "" > ${TMPFILE}/form-lists.tmp.bshtr

function GetLinks() {
	WEBSOURCECODE="${1}"
	cat ${WEBSOURCECODE} | grep -o 'href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^href=["'"'"']//' -e 's/["'"'"']$//'
	cat ${WEBSOURCECODE} | grep -o 'src=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^src=["'"'"']//' -e 's/["'"'"']$//'
}

function UrlSelector() {
	WEBSOURCECODE="${1}"
	URL="${2}"
	MARK=$(echo "${3}" | sed 's/\//\\\n/g' | head -3 | tail -1 | sed 's/\\//g' | sed 's|www.||g')
	HTTP=$(echo ${3} | sed 's|://| |g' | awk '{print $1}')
	if [[ ! -z $(echo "${URL}" | grep -i "[.]pdf\|[.]doc\|docx\|[.]png\|[.]gif\|[.]jpg\|[.]jpeg\|[.]ico\|[.]svg\|[.]css\|[.]js\|[.]woff") ]]
	then
		echo -ne ""
	elif [[ $(echo ${URL} | grep "${MARK}" | grep ^'http') ]]
	then
		echo "[GET] ${URL}"
	elif [[ $(echo "${URL}" | grep ^"[a-zA-Z0-9]*[:]" | grep -v 'http') ]]
	then 
		echo -ne ""
	elif [[ $(echo "${URL}" | grep ^'#'$) ]]
	then 
		echo -ne ""
	elif [[ $(echo "${URL}" | grep ^"[/][/][a-zA-Z0-9]") ]]
	then
		if [[ $(echo "${HTTP}" | grep ^"https"$) ]] && [[ $(echo "${URL}" | grep "${MARK}") ]];
		then
			echo "[GET] https:${URL}"
		elif [[ $(echo "${HTTP}" | grep ^"http"$) ]];
		then
			echo "[GET] ${3}$(echo "${URL}" | sed 's/^\///g')"
		else
			echo -ne ""
		fi
	elif [[ $(echo "${URL}" | grep ^"[/][a-zA-Z0-9#?]") ]]
	then
		echo "[GET] ${3}${URL}"
	elif [[ $(echo "${URL}" | grep ^"[a-zA-Z0-9]" | grep -v 'http://' | grep -v 'https://' | grep -v 'ios-app://' | grep -v 'android-app://') ]]
	then
		CUTHERE=$(echo "${3}" | awk -F '/' '{print $NF}' | grep "[.]")
		if [[ ! -z ${CUTHERE} ]]
		then
			DOMAIN=$(echo "${3}" | sed 's/\/$//g' | sed "s/${CUTHERE}//g")
		else
			DOMAIN=$(echo "${3}" | sed 's/\/$//g')
		fi
		echo "[GET] ${DOMAIN}/${URL}"
	else
		echo -ne ""
	fi
}

function CheckForm() {
	URL="${1}"
	WEBSOURCECODE="${2}"

	IFS=$'\n'
	for FORM in $(cat ${WEBSOURCECODE} | grep -Po '<form\K.*?(?=>)' | sed 's/^/<form/g' | sed 's/$/>/g')
	do
		FORMPOST=$(echo $FORM | grep -o 'method=['"'"'"][^"'"'"']*['"'"'"]' | grep -i post)
		if [[ $(cat ${TMPFILE}/form-lists.tmp.bshtr | grep ''$FORM'') ]]
		then
			echo -ne ""
		elif [[ -z ${FORMPOST} ]]
		then
			echo "$(date +"[%H:%M:%S]") INFO: Form GET on \"${URL}\""
				for FORM_TEST in $(find ${PARTSPATH}/form | grep bash$)
				do
					if [[ ! -z ${FORM_TEST} ]]
					then
						bash ${FORM_TEST} ${URL} ${TMPFILE}/sourcecode.tmp.bshtr
					fi
				done
		else 
			echo "$(date +"[%H:%M:%S]") INFO: Form POST on \"${URL}\""
				for FORM_TEST in $(find ${PARTSPATH}/form | grep bash$)
				do
					if [[ ! -z ${FORM_TEST} ]]
					then
						bash ${FORM_TEST} ${URL} ${TMPFILE}/sourcecode.tmp.bshtr
					fi
				done
		fi
		echo ${FORM} >> ${TMPFILE}/form-lists.tmp.bshtr
	done
}

########## HOME BANNER ##########
echo ""
cat ${BANNERFILE}
echo ""
echo "  ##### Version ${BASHTER_VERSION} released on ${RELEASED_DATE} #####"
echo " [ $(hostname)@BASHTER_HOME : ${BASHTER_HOME} ]"
echo ""

########## INPUT HERE ##########
echo -ne "[?] Input Website : "
read WEBSITE
echo -ne "[?] Verbose mode [y/N] : "
read VERBOSE
VERBOSE=${VERBOSE,,}

echo ""


########## WEBSITE VALIDATION ##########
if [[ -z ${WEBSITE} ]]
then
	echo "ERROR: Website cannot be empty!"
	exit
fi
WEBSITE=${WEBSITE,,}
if [[ ! -z $(echo ${WEBSITE} | grep ^'https://') ]]
then
	WEBSITE=${WEBSITE}
elif [[ ! -z $(echo ${WEBSITE} | grep ^'http://') ]]
then
	WEBSITE=${WEBSITE}
else
	if [[ ! -z $(${NC} -vz -w 5 ${WEBSITE} 443 &> ${TMPFILE}/testconn.bshtr && cat ${TMPFILE}/testconn.bshtr | grep 'https' | grep 'succeeded' && rm ${TMPFILE}/testconn.bshtr) ]]
	then
		echo "$(date +"[%H:%M:%S]") INFO: ${WEBSITE} using port 443 [HTTPS]"
		WEBSITE="https://${WEBSITE}"
	elif [[ ! -z $(${NC} -vz -w 5 ${WEBSITE} 80 &> ${TMPFILE}/testconn.bshtr && cat ${TMPFILE}/testconn.bshtr | grep 'http' | grep 'succeeded' && rm ${TMPFILE}/testconn.bshtr) ]]
	then
		echo "$(date +"[%H:%M:%S]") INFO: ${WEBSITE} using port 80 [HTTP]"
		WEBSITE="http://${WEBSITE}"
	fi
fi
if [[ -z $(${WGET} -S --spider "${WEBSITE}" 2>&1 >/dev/null | grep 'connected') ]]
then
	echo "ERROR: Cannot connect to ${WEBSITE}"
	exit
fi
WEBSITE=$(echo "${WEBSITE}" | sed 's/\/$//g' | sed 's/\/$//g' | sed 's/\/$//g')
echo "$(date +"[%H:%M:%S]") INFO: Scanning ${WEBSITE}..."
if [[ ${VERBOSE} == "y" ]]
then
	VERBOSE_FLAG="Y"
	echo "$(date +"[%H:%M:%S]") INFO: Verbose mode activated!"
fi

########## TAKING SOURCE CODE AT THE FIRST TIME ##########
curl -vskL --connect-timeout 5 --max-time 5 "${WEBSITE}" &> ${TMPFILE}/sourcecode.tmp.bshtr

CheckForm ${WEBSITE} ${TMPFILE}/sourcecode.tmp.bshtr
for HEADER_ANALYZER in $(find ${PARTSPATH}/header | grep bash$)
do
	if [[ ! -z ${HEADER_ANALYZER} ]]
	then
		bash ${HEADER_ANALYZER} ${WEBSITE} ${TMPFILE}/sourcecode.tmp.bshtr
	fi
done
for URL_ANALYZER in $(find ${PARTSPATH}/url | grep bash$)
do
	if [[ ! -z ${URL_ANALYZER} ]]
	then
		bash ${URL_ANALYZER} ${WEBSITE} ${TMPFILE}/sourcecode.tmp.bshtr
	fi
done

if [[ -f ${TMPFILE}/url-lists.tmp.bshtr ]]
then
	rm ${TMPFILE}/url-lists.tmp.bshtr
fi


########## CRAWLING WITH LOOP ##########
for URL in $(GetLinks ${TMPFILE}/sourcecode.tmp.bshtr)
do
	UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${WEBSITE} >> ${TMPFILE}/url-lists.tmp.bshtr
	if [[ ${VERBOSE_FLAG} == "Y" ]] && [[ ! -z $(UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${WEBSITE}) ]]
	then
		echo "$(date +"[%H:%M:%S]") $(UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${WEBSITE})"
	fi
done
echo "${WEBSITE}" > ${TMPFILE}/scanned-link.tmp.bshtr

CMPCHECKPOINT=0
while true
do
	for LINKS in $(cat ${TMPFILE}/url-lists.tmp.bshtr | awk '{print $2}')
	do
		if [[ -z $(cat ${TMPFILE}/scanned-link.tmp.bshtr | grep "${LINKS}") ]]
		then
			curl -vskL --connect-timeout 5 --max-time 5 "${LINKS}" &> ${TMPFILE}/sourcecode.tmp.bshtr

			CheckForm ${LINKS} ${TMPFILE}/sourcecode.tmp.bshtr
			for HEADER_ANALYZER in $(find ${PARTSPATH}/header | grep bash$)
			do
				if [[ ! -z ${HEADER_ANALYZER} ]]
				then
					bash ${HEADER_ANALYZER} ${LINKS} ${TMPFILE}/sourcecode.tmp.bshtr
				fi
			done
			for URL_ANALYZER in $(find ${PARTSPATH}/url | grep bash$)
			do
				if [[ ! -z ${URL_ANALYZER} ]]
				then
					bash ${URL_ANALYZER} ${LINKS} ${TMPFILE}/sourcecode.tmp.bshtr
				fi
			done

			for URL in $(GetLinks ${TMPFILE}/sourcecode.tmp.bshtr)
			do
				URLCHK=$(UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${WEBSITE} | awk '{print $2}')
				if [[ -z $(cat ${TMPFILE}/url-lists.tmp.bshtr | grep "${URLCHK}") ]]
				then
					UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${LINKS} >> ${TMPFILE}/url-lists.tmp.bshtr
					if [[ ${VERBOSE_FLAG} == "Y" ]] && [[ ! -z $(UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${LINKS}) ]]
					then
						echo "$(date +"[%H:%M:%S]") $(UrlSelector ${TMPFILE}/sourcecode.tmp.bshtr ${URL} ${LINKS})"
					fi
				fi
			done
			echo "${LINKS}" >> ${TMPFILE}/scanned-link.tmp.bshtr
			CMPCOMPARISON=$(cat ${TMPFILE}/scanned-link.tmp.bshtr | wc -l)
		fi
	done
	if [[ ${CMPCHECKPOINT} -eq ${CMPCOMPARISON} ]];
	then
		break
	else
		CMPCHECKPOINT=${CMPCOMPARISON}
	fi
done
