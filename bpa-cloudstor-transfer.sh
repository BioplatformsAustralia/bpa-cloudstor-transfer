#!/bin/bash

# bpa-cloudstor-transfer.sh

# Usage: bpa-cloudstor-transfer.sh <folder-to-transfer>

# Don't forget to run shellcheck (https://github.com/koalaman/shellcheck) after making edits.

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT
set -euo pipefail

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

# CTC settings

#default values
BACKLOG=36
CHECK=1
CHECKERS=36
EXTRAVARS=0
HELP=0
PUSHFIRST=0
VERSIONCHECK=1
SHOWDIFF=""
TIMEOUT=0
TRANSFERS=6
# Do the transfer with these settings (from copyToCloudStor.sh)
PUSHFIRST=1
CHECK=0

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

# Check we've got curl installed
if ! command -v curl &> /dev/null
then
    warn "curl not found"
    warn "Install curl as appropriate for your environment"
    exit 1
else
    debug "curl found"
fi

debug "Script name: $0"
debug "$# arguments"

# Check number of arguments
if [ $# -ne 1 ]; then
	usage "Incorrect number of arguments"
	exit 1
fi

# Check argument is directory

TXFR_FOLDER=$1

if [ ! -d "$TXFR_FOLDER" ]; then
	usage "Argument must be a directory"
	exit 1
fi

TXFR_NAME=`basename $TXFR_FOLDER`

# Check directory is named correctly
# In the format - 20201202_TESTPROJ_TESTFACILITY_ABCD1234
# =~ operator is a bashism

if [[ ! $TXFR_NAME =~ ^[0-9]{8}_[A-Za-z]+_[A-Za-z]+_[A-Za-z0-9]{8}$ ]]; then
	usage "Directory must be named correctly <datestamp>_<project>_<facility>_<flowcell ID>"
	exit 1
else
	debug "Directory $TXFR_NAME meets criteria"
fi

# (Re) generate rclone config

CLOUDSTOR_URL=https://cloudstor.aarnet.edu.au/plus/remote.php/webdav/
rclone config create bpa-cloudstor-transfer webdav \
	url $CLOUDSTOR_URL \
	vendor owncloud \
	user "$CLOUDSTOR_LOGIN" \
	pass "$CLOUDSTOR_APP_PASSWORD"
debug "Created rclone configuration"

# Check if password is an app password.  If not, output a warning

# Test if folder is present on CloudStor.  If not, create?

if [ \
	curl -u "$CLOUDSTOR_LOGIN:$CLOUDSTOR_APP_PASSWORD" \
	-f -s -I --head \
	"$CLOUDSTOR_URL/$TXFR_NAME" \
   ]; then
	# not there, create
	info "Creating folder $TXFR_NAME"
	curl -u "$CLOUDSTOR_LOGIN:$CLOUDSTOR_APP_PASSWORD" \
		-X MKCOL \
		"$CLOUDSTOR_URL/$TXFR_NAME"
else 
	info "Folder $TXFR_NAME present"
fi

# Test if we've got enough space on CloudStor

# Get size of directory we are transferring
TXFR_SIZE=$(du -sb "$TXFR_FOLDER" | awk '{print $1}')
info "Need to transfer $TXFR_SIZE bytes from $TXFR_FOLDER"

# Get total space on CloudStor

# FIXME: Need info from AARNet

# Get used space on CloudStor

# FIXME: Need info from AARNet

# Calculate remaining space

# FIXME: Need info from AARNet

# Compare to see if we've got enough space left to transfer this

info "FIXME: Currently crossing fingers that we have enough space for the transfer"

# Rclone to folder on CloudStor
# Logic/etc from copyToCloudstor.sh



destination="bpa-cloudstor-transfer:$TXFR_NAME"

#Do the transfer
SECONDS=0
source_absolute_path=$(readlink -m "$TXFR_FOLDER")

rcloneoptions="--transfers ${TRANSFERS} --checkers ${CHECKERS} --timeout ${TIMEOUT} --max-backlog ${BACKLOG}"

echo "Copying ${source_absolute_path} to ${destination}. Starting at $(date)"

counter=1
if [ ${PUSHFIRST} -eq 1 ] || [ ${CHECK} -eq 0 ]; then
	echo "Starting run ${counter} at $(date) without checks"
	rclone copy --progress --no-check-dest --no-traverse ${rcloneoptions} "${source_absolute_path}" "${destination}"
	echo "Done with run ${counter} at $(date)"
	counter=$((counter+1))
	CHECK=1
fi
if [ ${CHECK} -eq 1 ]; then
	while ! rclone check --one-way ${SHOWDIFF} ${rcloneoptions} "${source_absolute_path}" "${destination}" 2>&1 | tee /dev/stderr | grep ': 0 differences found'; do
		echo "Starting run ${counter} at $(date)"
		rclone copy --progress "${rcloneoptions}" "${source_absolute_path}" "${destination}"
		echo "Done with run ${counter} at $(date)"
		counter=$((counter+1))
	done
fi

duration=${SECONDS}
echo "Copied '${source_absolute_path}' to '${destination}'. Finished at $(date), in $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."

# Use owncloud API to share to BPA CloudStor address

# Generate email to notification email address
FILELIST=$(find $TXFR_FOLDER)

$SENDMAIL $NOTIFY_EMAIL <<- END
	To: Bioplatforms Australia Data Team <$NOTIFY_EMAIL>
	Subject: Dataset $TXFR_NAME uploaded to Cloudstor

	The following dataset has been been uploaded to Cloudstor.

	$TXFR_NAME

	It contains the following files:

	$FILELIST

	It can be downloaded from CloudStor with the following rclone command
END

if [ ${CLEANUPCONFIG} -eq 1 ]; then
	rclone config delete bpa-cloudstor-transfer
	debug "Removed rclone configuration"
fi

# Report to user

info "Notification email sent to $NOTIFY_EMAIL"

trap - DEBUG
trap - EXIT

info "Complete."
