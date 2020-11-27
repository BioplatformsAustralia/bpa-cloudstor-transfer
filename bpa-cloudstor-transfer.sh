#!/bin/bash

# bpa-cloudstor-transfer.sh

# Usage: bpa-cloudstor-transfer.sh <folder-to-transfer>

# Initial pseudocode for script

# Need the following configuration information
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
	echo $1
}

# Check we've got config information

# Check we've got rclone installed
# Check we've got mail installed

# (Re) generate rclone config

# Check number of arguments

# Check argument is directory

# Check directory is named correctly

# Test if folder is present on CloudStor

# Test if we've got enough space on CloudStor

# Rclone to folder on CloudStor

# Use owncloud API to share to BPA CloudStor address

# Generate email to notification email address

# Report to user
