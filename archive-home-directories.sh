#!/bin/bash
#
# This script archives home directories to supply location. 
# User can supply user accounts for which the archive will be created.
# By default, all user accounts are processed if no usernames are supplied.

# Default archive location.
ARCHIVE_DIR='/archive'

# Show usage information.
usage() {
	echo "Usage: ${0} [-a ARCHIVE_DIR] [-v] [USERNAME...]" >&2
	echo "	-a 	ARCHIVE_DIR	location where output of this script will be stored (default is /archive)." >&2
	echo "	-v 	increase verbosity." >&2
	echo >&2 
	echo "If no username is supplied, all user accounts are processed." >&2
	exit 1
}

# Print out information based on verbosity level.
print_info() {
	local MESSAGE="${@}"
	if [[ "${VERBOSE}" = 'true' ]]; then
		echo "${MESSAGE}"
	fi
}

# This script requires root privileges.
if [[ "${UID}" -ne 0 ]]; then
	echo "Root privileges are required to execute this script." >&2
	exit 1
fi

# Process options.
while getopts a:v OPTION; do
	case "${OPTION}" in
		a) ARCHIVE_DIR="${OPTARG}" ;;
		v) VERBOSE='true' ;;
		?) usage ;;
	esac
done

# Check whether any usernames were supplied.
shift "$(( OPTIND - 1 ))"

if [[ "${#}" -eq 0 ]]; then
	SHOULD_ARCHIVE_ALL='true'
fi

# Check whether the archive directory exists. If not, try to create it.
if [[ ! -d "${ARCHIVE_DIR}" ]]; then
	print_info "Creating ${ARCHIVE_DIR}"
	mkdir -p "${ARCHIVE_DIR}"

	if [[ "${?}" -ne 0 ]]; then
		echo "Failed to create ${ARCHIVE_DIR}" >&2
		exit 1
	fi
fi

# Process all user accounts if none were supplied. Otherwise, process
# only supplied accounts.
if [[ "${SHOULD_ARCHIVE_ALL}" = 'true' ]]; then
	USERNAMES="$( awk -F ':' '{print $1}' /etc/passwd )"
else
	USERNAMES="${@}"
fi

for USERNAME in ${USERNAMES}; do
	print_info "Processing ${USERNAME}"

	USER_ID="$( id -u ${USERNAME} )"

	if [[ "${USER_ID}" -lt 1000 ]]; then
		# Skip accounts with UID less than 1000
		print_info "	Skipping user ${USERNAME} with UID ${USER_ID} - UID is less than 1000."
	elif [[ ! -d "/home/${USERNAME}" ]]; then
		# skip accounts with no home directory
		print_info "	Skipping user ${USERNAME} - no home directory."
	else 
		USER_HOME="/home/${USERNAME}"
		ARCHIVE_FILE="${USERNAME}.tar.gz"
		print_info "	Archiving ${USER_HOME} to ${ARCHIVE_DIR}/${ARCHIVE_FILE}"

		tar -zcf "${ARCHIVE_DIR}/${ARCHIVE_FILE}" "${USER_HOME}" &> /dev/null		 		

		if [[ "${?}" -ne 0 ]]; then
			echo "	Failed to create archive for ${USER_HOME}"
			exit 1
		else
			print_info "	${ARCHIVE_DIR}/${ARCHIVE_FILE} was created." 
		fi
	fi
done

exit 0
