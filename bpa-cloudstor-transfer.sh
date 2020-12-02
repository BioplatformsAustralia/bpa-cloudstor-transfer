#!/bin/bash

# bpa-cloudstor-transfer.sh

# Usage: bpa-cloudstor-transfer.sh <folder-to-transfer>

# Internal script configuation
VERSIONCHECK="${VERSIONCHECK:=1}"

# Need the following configuration information from user
# - User details
# - App password

# - Data age
# - Destination to share to (ie BPA CloudStor address)
# - Notification email address (help@bioplatforms.com)

# Logging functions
function warn {
	echo $1
}

function info {
	echo $1
}

function debug {
	echo -n "DEBUG: "
	echo $1
}

function usage {
	echo $1
	echo
	echo "Usage: bpa-cloudstor-transfer.sh <directory>"
	echo
}

# Check we've got config information

# Check we've got rclone installed

if ! command -v rclone &> /dev/null
then
    warn "rclone could not be found"
    warn "Install rclone as appropriate for your environment"
    exit 1
fi

# Check our rclone version, warn if out of date
#Check for latest rclone version
if [ ${VERSIONCHECK} -eq 1 ]; then
        if [ "$(rclone version --check | grep -e 'yours\|latest' | sed 's/  */ /g' | cut -d' ' -f2 | uniq | wc -l)" -gt 1 ]; then
                rclone version --check
                warn "Upgrade rclone to latest version as appropriate for your environment"
        else
                debug "rclone is latest version."
        fi
fi

# Check we've got mail installed

# (Re) generate rclone config

debug "Script name: $0"
debug "$# arguments"

# Check number of arguments
if [ $# -ne 1 ]; then
	usage "Incorrect number of arguments"
	exit 1
fi

# It should be a directory

TRANSFER_FOLDER=$1

if [ ! -d "$TRANSFER_FOLDER" ]; then
	usage "Argument must be a directory"
	exit 1
fi

TRANSFER_NAME=`basename $TRANSFER_FOLDER`


# Check argument is directory

# Check directory is named correctly

# Test if folder is present on CloudStor

# Test if we've got enough space on CloudStor

# Rclone to folder on CloudStor

# Use owncloud API to share to BPA CloudStor address

# Generate email to notification email address

# Report to user
