#!/bin/bash

# This script lists all opened ports on the system. User can specify
# whether to list only ipv4 or ipv6 ports (default is to list boht).
# Also, user can specify whether to list only TCP or UDP ports (default is to list both).

# show usage information
usage() { 
	echo "Usage: ${0} [-t] [-u] [-4] [-6]."
	echo "	-t	list only TCP ports." >&2
	echo "	-u	list only UDP ports." >&2
	echo "	-4 	list only IPv4 ports." >&2
	echo "	-6	list only IPv6 ports." >&2
	echo "Each option needs to be prepended with -" >&2 
	exit 1	
}

for OPTION in "${@}"; do
	if [[ "${OPTION}" != "-t" && "${OPTION}" != "-u" && "${OPTION}" != "-6" && "${OPTION}" != "-4" ]]; then
		usage
	fi
done

netstat -nl "${@}" | grep ':' | awk '{print $4}' | awk -F ':' '{print $NF}' | sort -n | uniq

exit 0
