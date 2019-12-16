#!/bin/bash

# This script lists all local disabled user accounts. 

# This script reads /etc/shadow, therefore it needs root privileges.
if [[ "${UID}" -ne 0 ]]; then
	echo "Root privileges are required to execute this script." >&2
	exit 1
fi

while read -r USER; do
	USERNAME="$( echo ${USER} | awk -F ':' '{print $1}' )"
	IS_DISABLED="$( echo ${USER} | awk -F ':' '{print $8}' )"
	
	if [[ "${IS_DISABLED}" = '0' ]]; then
		echo "${USERNAME}"
	fi
done < '/etc/shadow'
