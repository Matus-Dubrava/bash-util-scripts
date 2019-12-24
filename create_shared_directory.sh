#!/bin/bash

# This script creates new directory shared by specified group.

# This script requires root privileges.
if [[ "${UID}" -ne 0 ]]; then
	echo "Root privileges are required to execute this script." >&2
	exit 1
fi

# Show usage information.
usage() {
	echo "Usage: ${0} -g GROUP DIRECTORY" >&2
	echo "	-g GROUP 	Name of the group that will share this directory" >&2
	exit 1
}

# Check return status of previos command.
check_return_code() {
	local MESSAGE="${@}"

	if [[ "${?}" -ne 0 ]]; then
		echo "${MESSAGE}" >&2
		exit 1
	fi
}	

# Parse options
while getopts g: OPTION; do
	case "${OPTION}" in
		g) GROUP="${OPTARG}" ;;
		?) usage ;;
	esac
done

if [[ "${GROUP}" = '' ]]; then
	usage
fi

# Extract arguments.
shift $(( OPTIND - 1 ))

if [[ "${#}" -eq 0 ]]; then
	usage
fi

DIR="${@}"

# Check whether the supplied directory exists or not.
if [[ -d "${DIR}" ]]; then
	echo "Directory ${DIR} already exists. Please specify another one." >&2
	exit 1
fi

# Create specified group.
groupadd "${GROUP}" &> /dev/null
check_return_code "ERROR: Failed to create group ${GROUP}"

# Set correct permissions and ownership.
mkdir -p "${DIR}" 
check_return_code "ERROR: Failed to create ${DIR}"

chmod 3775 "${DIR}"
check_return_code "ERROR: Failed to set permissions ${DIR}"

chown ."${GROUP}" "${DIR}"
check_return_code "ERROR: Failed to change ownership of ${DIR}"

exit 0
