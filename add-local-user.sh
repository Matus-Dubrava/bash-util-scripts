#!/bin/bash
#
# This script creates one or more users on the system with randomly generated passwords
# that expire on the first login. User of this script can specify the length of the password.
# Once the script is done, list of the users generated by this script is printed out 
# with their usernames, passwords, and hostname in CSV format to STDOUT. Optionally, 
# user can specify output file.

# NOTE: This scripts was tested on CentOS. Ubuntu doesn't support --stdin option for passwd
#	Required change for Ubuntu
# 	
#	FROM: 	echo "${PASSWORD}" | passwd --stdin "${USERNAME}" &> /dev/null
# 	TO: 	echo "${PASSWORD}" | chpasswd "${USERNAME}" &> /dev/null

# Default password length is 48
LENGTH=48

# Prints out usage instructions
usage() {
	echo "Usage: ${0} [-s] [-l LENGTH] [-f OUTPUT_FILE ] USERNAME [USERNAME...]" >&2
	echo "	-l	LENGTH	password length" >&2
	echo "	-s	include special character in the password" >&2
	echo "	-f	OUTPUT_FILE	use output file instead of STDOUT." >&2
	exit 1
}

# Generates random password based on selected options.
generate_password() {
	if [[ "${USE_SPECIAL_CHARACTER}" = 'true' ]]; then
		LENGTH="$(( LENGTH - 1 ))"
	fi
	
	PASSWORD="$( date +%s%N${RANDOM} | sha256sum | head -c ${LENGTH})"

	if [[ "${USE_SPECIAL_CHARACTER}" = 'true' ]]; then
		SPECIAL_CHARACTER="$( echo '!@#$%^&*()_+-=' | fold -w1 | shuf | head -c 1 )"
		PASSWORD="${PASSWORD}${SPECIAL_CHARACTER}"
	fi

	echo "${PASSWORD}"
}

# Checks return code of the last command.
# Display message if the status code is non-zero.
check_return_code() {
	if [[ "${?}" -ne 0 ]]; then
		echo "${1}" >&2
		exit 1
	fi
}

# Check whether the script is executed with root privileges.
if [[ "${UID}" -ne 0 ]]; then
	echo "Use sudo to execute this script." >&2
	exit 1
fi

# parse options 
while getopts l:f:s OPTION; do
	case "${OPTION}" in
		l) LENGTH="${OPTARG}" ;;
		s) USE_SPECIAL_CHARACTER='true' ;;
		f) 
			OUTPUT_FILE="${OPTARG}" 
			USE_OUTPUT_FILE='true'
			;;
		?) usage ;;
	esac
done

# strip options 
shift "$(( OPTIND - 1 ))"

# at least one USERNAME must be supplied
if [[ "${#}" -eq 0 ]]; then
	usage
fi

# Check for already existing users on the system. Print list
# of already existing users, terminate script, and ask user to 
# provide only usernames that don't already exist.

USERS_THAT_EXIST=""
SHOULD_TERMINATE='false'

for USERNAME in "${@}"; do 	
	id "${USERNAME}" &> /dev/null
	
	if [[ "${?}" -eq 0 ]]; then
		SHOULD_TERMINATE='true'
		if [[ "${USERS_THAT_EXIST}" = '' ]]; then
			USERS_THAT_EXIST="${USERNAME}"
		else
			USERS_THAT_EXIST="${USERS_THAT_EXIST}, ${USERNAME}"
		fi
	fi	
done

if [[ "${SHOULD_TERMINATE}" = 'true' ]]; then
	echo "Please supply only usernames that don't already exist." >&2
	echo "These users already exist:" >&2
	echo >&2
	echo "${USERS_THAT_EXIST}" >&2
	exit 1
fi

# Print out CSV header.
if [[ "${USE_OUTPUT_FILE}" = 'true' ]]; then
	echo "Username,Password,Hostname" > "${OUTPUT_FILE}"
	check_return_code "Failed to write to ${OUTPUT_FILE}"
else 
	echo "Username,Password,Hostname"
fi

# Process each username. 
for USERNAME in "${@}"; do
	PASSWORD="$( generate_password )"
	
	useradd -m "${USERNAME}" &> /dev/null
	check_return_code "Failed to create user ${USERNAME}" 

	echo "${PASSWORD}" | passwd --stdin "${USERNAME}" &> /dev/null
	check_return_code "Failed to set password for username ${USERNAME}"

	# expire password on first login
	passwd -e "${USERNAME}" &> /dev/null

	# Printout username, password, hosname in CSV format
	if [[ "${USE_OUTPUT_FILE}" = 'true' ]]; then
		echo "${USERNAME},${PASSWORD},${HOSTNAME}" >> "${OUTPUT_FILE}"
		check_return_code "Failed to write to ${OUTPUT_FILE}"
	else
		echo "${USERNAME},${PASSWORD},${HOSTNAME}" 
	fi
done

exit 0


