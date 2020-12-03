#!/bin/bash

# bpa-cloudstor-transfer.sh

# Usage: bpa-cloudstor-transfer.sh <folder-to-transfer>

# Internal script configuation
VERSIONCHECK="${VERSIONCHECK:=1}"
CLEANUPCONFIG="${CLEANUPCONFIG:=1}"

# Need the following configuration information from user
# - User details
# - App password

# - Data age
# - Destination to share to (ie BPA CloudStor address)
# - Notification email address (help@bioplatforms.com)
NOTIFY_EMAIL="${NOTIFY_EMAIL:=mark.tearle@qcif.edu.au}"
SENDMAIL="${SENDMAIL:=/usr/sbin/sendmail}"

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

if [ -z "$CLOUDSTOR_LOGIN" ]; then
    warn "Please set CLOUDSTOR_LOGIN environment variable with your Cloudstore username"
    warn " For example:"
    warn " export CLOUDSTOR_LOGIN=user@institute.edu.au"
    exit 1
else
    debug "Login $CLOUDSTOR_LOGIN found"
fi

if [ -z "$CLOUDSTOR_APP_PASSWORD" ]; then
    warn "Please set CLOUDSTOR_APP_PASSWORD environment variable with your Cloudstore app password"
    warn " See https://support.aarnet.edu.au/hc/en-us/articles/236034707-How-do-I-manage-change-my-passwords"
    warn ""
    warn " For example:"
    warn "  export CLOUDSTOR_APP_PASSWORD=CREKT-HORSE-BATRY-STAPL"
    exit 1
else
    debug "App password found"
fi

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
if ! command -v $SENDMAIL &> /dev/null
then
    warn "sendmail not found"
    warn "Install a mail transfer agent to provide sendmail as appropriate for your environment"
    warn "For example: sstmp, msmtp"
    exit 1
else
    debug "sendmail found"
fi


debug "Script name: $0"
debug "$# arguments"

# Check number of arguments
if [ $# -ne 1 ]; then
	usage "Incorrect number of arguments"
	exit 1
fi

# Check argument is directory

TRANSFER_FOLDER=$1

if [ ! -d "$TRANSFER_FOLDER" ]; then
	usage "Argument must be a directory"
	exit 1
fi

TRANSFER_NAME=`basename $TRANSFER_FOLDER`

# Check directory is named correctly
# In the format - 20201202_TESTPROJ_TESTFACILITY_ABCD1234
# =~ operator is a bashism

if [[ ! $TRANSFER_NAME =~ ^[0-9]{8}_[A-Za-z]+_[A-Za-z]+_[A-Za-z0-9]{8}$ ]]; then
	usage "Directory must be named correctly <datestamp>_<project>_<facility>_<flowcell ID>"
	exit 1
else
	debug "Directory $TRANSFER_NAME meets criteria"
fi

# (Re) generate rclone config

CLOUDSTOR_URL=https://cloudstor.aarnet.edu.au/plus/remote.php/webdav/
rclone config create bpa-cloudstor-transfer webdav \
	url $CLOUDSTOR_URL \
	vendor owncloud \
	user "$CLOUDSTOR_LOGIN" \
	pass "$CLOUDSTOR_APP_PASSWORD"
debug "Created rclone configuration"

# Test if folder is present on CloudStor

# Test if we've got enough space on CloudStor

# Rclone to folder on CloudStor

# Use owncloud API to share to BPA CloudStor address

# Generate email to notification email address
FILELIST=$(find $TRANSFER_FOLDER)

$SENDMAIL $NOTIFY_EMAIL <<- END
	To: Bioplatforms Australia Data Team <$NOTIFY_EMAIL>
	Subject: Dataset $TRANSFER_NAME uploaded to Cloudstor

	The following dataset has been been uploaded to Cloudstor.

	$TRANSFER_NAME

	It contains the following files:

	$FILELIST

	It can be downloaded from CloudStor with the following rclone command
END

if [ ${CLEANUPCONFIG} -eq 1 ]; then
	rclone config delete bpa-cloudstor-transfer
	debug "Removed rclone configuration"
fi

# Report to user
