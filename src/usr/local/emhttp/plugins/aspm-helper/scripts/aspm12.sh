#!/bin/bash

source /boot/config/plugins/aspm-helper/aspmhelpersettings

###############

if [ "$syslog" == "yes" ]; then

log_message() {
  while IFS= read -r line; do
    logger "aspm-helper: ${line}"
  done
}
exec > >(log_message) 2>&1

fi

###############

ENDPOINT="$aspm_12_head"
ROOT_COMPLEX="$aspm_12_root"
ASPM_SETTING="$aspm_12_mode"

###############

#############################################################

function aspm_setting_to_string()
{
	case $1 in
	0)
		echo -e "\tL0 only, ASPM disabled"
		;;
	1)
		;;
	2)
		echo -e "\tL1 only"
		;;
	3)
		echo -e "\tL1 and L0s"
		;;
	*)
		echo -e "\tInvalid"
		;;
	esac
}

###################################################################

# we can surely read the spec to get a better value
MAX_SEARCH=30
SEARCH_COUNT=1
ASPM_BYTE_ADDRESS="INVALID"

ROOT_PRESENT=$(lspci | grep -c "$ROOT_COMPLEXT")
ENDPOINT_PRESENT=$(lspci | grep -c "$ENDPOINT")

if [[ $(id -u) != 0 ]]; then
	echo "This needs to be run as root"
	exit 1
fi

if [[ $ROOT_PRESENT -eq 0 ]]; then
	echo "Root complex $ROOT_COMPLEX is not present"
	exit
fi

if [[ $ENDPOINT_PRESENT -eq 0 ]]; then
	echo "Endpoint $ENDPOINT is not present"
	exit
fi

# XXX: lspci -s some_device_not_existing does not return positive
# if the device does not exist, fix this upstream
function device_present()
{

	PRESENT=$(lspci | grep -c "$1")
	COMPLAINT="not present"

	if [[ $PRESENT -eq 0 ]]; then
		if [[ $2 != "present" ]]; then
			COMPLAINT="disappeared"
		fi

		echo -e "Device ${1} $COMPLAINT" 
		return 1
	fi
	return 0
}

function find_aspm_byte_address()
{
	device_present $ENDPOINT present
	if [[ $? -ne 0 ]]; then
		exit
	fi

	SEARCH=$(setpci -s $1 34.b)
	# We know on the first search $SEARCH will not be
	# 10 but this simplifies the implementation.
	while [[ $SEARCH != 10 && $SEARCH_COUNT -le $MAX_SEARCH ]]; do
		END_SEARCH=$(setpci -s $1 ${SEARCH}.b)

		# Convert hex digits to uppercase for bc
		SEARCH_UPPER=$(printf "%X" 0x${SEARCH})

		if [[ $END_SEARCH = 10 ]]; then
			ASPM_BYTE_ADDRESS=$(echo "obase=16; ibase=16; $SEARCH_UPPER + 10" | bc)
			break
		fi

		SEARCH=$(echo "obase=16; ibase=16; $SEARCH_UPPER + 1" | bc)
		SEARCH=$(setpci -s $1 ${SEARCH}.b)

		let SEARCH_COUNT=$SEARCH_COUNT+1
	done

	if [[ $SEARCH_COUNT -ge $MAX_SEARCH ]]; then
		echo -e "Long loop while looking for ASPM word for $1"
		return 1
	fi
	return 0
}

function enable_aspm_byte()
{
	device_present $1 present
	if [[ $? -ne 0 ]]; then
		exit
	fi

	find_aspm_byte_address $1
	if [[ $? -ne 0 ]]; then
		return 1
	fi

	ASPM_BYTE_HEX=$(setpci -s $1 ${ASPM_BYTE_ADDRESS}.b)
	ASPM_BYTE_HEX=$(printf "%X" 0x${ASPM_BYTE_HEX})
	# setpci doesn't support a mask on the query yet, only on the set,
	# so to verify a setting on a mask we have no other optoin but
	# to do do this stuff ourselves.
	DESIRED_ASPM_BYTE_HEX=$(printf "%X" $(( (0x${ASPM_BYTE_HEX} & ~0x7) |0x${ASPM_SETTING})))

	if [[ $ASPM_BYTE_ADDRESS = "INVALID" ]]; then
		echo -e "No ASPM byte could be found for $(lspci -s $1)"
		return
	fi

	echo -e "$(lspci -s $1)"
	echo -en "\t0x${ASPM_BYTE_ADDRESS} : 0x${ASPM_BYTE_HEX} --> 0x${DESIRED_ASPM_BYTE_HEX} ... "

	device_present $1 present
	if [[ $? -ne 0 ]]; then
		exit
	fi

	# Avoid setting if already set
	if [[ $ASPM_BYTE_HEX = $DESIRED_ASPM_BYTE_HEX ]]; then
		echo -e "[SUCESS] (already set)"
		aspm_setting_to_string $ASPM_SETTING
		return 0
	fi

	# This only writes the last 3 bits
	setpci -s $1 ${ASPM_BYTE_ADDRESS}.b=${ASPM_SETTING}:3

	sleep 3

	ACTUAL_ASPM_BYTE_HEX=$(setpci -s $1 ${ASPM_BYTE_ADDRESS}.b)
	ACTUAL_ASPM_BYTE_HEX=$(printf "%X" 0x${ACTUAL_ASPM_BYTE_HEX})

	# Do not retry this if it failed, if it failed to set.
	# Likey if it failed its a good reason and you should look
	# into that.
	if [[ $ACTUAL_ASPM_BYTE_HEX != $DESIRED_ASPM_BYTE_HEX ]]; then
		echo -e "\t[FAIL] (0x${ACTUAL_ASPM_BYTE_HEX})"
		return 1
	fi

	echo -e "\t[SUCCESS]]"
	aspm_setting_to_string $ASPM_SETTING

	return 0
}

device_present $ENDPOINT not_sure
if [[ $? -ne 0 ]]; then
	exit
fi

echo -e "Root complex:"
enable_aspm_byte $ROOT_COMPLEX
echo

echo -e "Endpoint:"
enable_aspm_byte $ENDPOINT
echo

sleep 1

lspci -vv | awk '/ASPM/{print $0}' RS= | grep --color -P '(^[a-z0-9:.]+|ASPM |Disabled;|Enabled;)' > /usr/local/emhttp/plugins/aspm-helper/result/aspm_current.txt
