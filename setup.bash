#!/bin/bash
echo -ne "[?] Configure BASHTER_HOME : ${HOME}/"
read BASHTER_HOME
BASHTER_HOME="${HOME}/${BASHTER_HOME}"

if [[ -d ${BASHTER_HOME} ]]
then
	echo "WARN: \"${BASHTER_HOME}\" already exists, please remove it before install!"
	exit
fi

mkdir ${BASHTER_HOME}

if [[ ! -d ${BASHTER_HOME} ]]
then
	echo "ERROR: Cannot create directory ${BASHTER_HOME}"
fi

echo "#########################" > ${BASHTER_HOME}/CONFIG.bash
echo "# BASHTER CONFIGURATION #" >> ${BASHTER_HOME}/CONFIG.bash
echo "#########################" >> ${BASHTER_HOME}/CONFIG.bash
echo "BASHTER_HOME=\"${BASHTER_HOME}\"" >> ${BASHTER_HOME}/CONFIG.bash
echo "TMPFILE=\"\${BASHTER_HOME}/.temp\"" >> ${BASHTER_HOME}/CONFIG.bash
echo "BANNERFILE=\"\${BASHTER_HOME}/BANNER.file\"" >> ${BASHTER_HOME}/CONFIG.bash
echo "PARTSPATH=\"\${BASHTER_HOME}/parts\"" >> ${BASHTER_HOME}/CONFIG.bash
echo "BASHTER_VERSION=\"3.0\"" >> ${BASHTER_HOME}/CONFIG.bash
echo "RELEASED_DATE=\"21 April 2019\"" >> ${BASHTER_HOME}/CONFIG.bash
cp -rf $(pwd)/* ${BASHTER_HOME}/
rm ${BASHTER_HOME}/setup.bash
sed -i "s|/path-to/|${BASHTER_HOME}/|g" ${BASHTER_HOME}/bashter.bash
for BASH_FILE in $(find ${BASHTER_HOME}/ | grep bash$)
do
	chmod +x ${BASH_FILE}
done


cat << EOF

[+] INSTALL DONE! [+]

Run script:
# bash ${BASHTER_HOME}/bashter.bash
OR
# ${BASHTER_HOME}/bashter.bash

OR YOU CAN CREATE A SYMLINK LIKE THIS! (run as root)
# ln -sf ${BASHTER_HOME}/bashter.bash /usr/bin/bashter
And then
# bashter

EOF
