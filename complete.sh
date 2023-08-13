#
# 08-12-2023 v01.00 - Initial version
# 08-12-2023 v01.50 - Added handling of 'Category'
#   Run external program on torrent finished = '/bin/bash /scripts/complete.sh %Z %C "%N" "%D" "%F" "%L" "%R"'
# 08-12-2023 v01.70 - Added logic to delete old log files
# 08-12-2023 v01.75 - Added output during delete old log files
# 08-12-2023 v01.80 - Variables in log clean-up added
# 08-12-2023 v01.82 - Removed unnecessary redirects and cleaed-up LOG logic
#

#!/bin/bash
set -x

#
#Run external program on torrent finished
#Supported parameters (case sensitive):

#    %N: Torrent name
#    %L: Category
#    %G: Tags (separated by comma)
#    %F: Content path (same as root path for multifile torrent)
#    %R: Root path (first torrent subdirectory path) [will be '' if only a single file torrent]
#    %D: Save path
#    %C: Number of files
#    %Z: Torrent size (bytes)
#    %T: Current tracker
#    %I: Info hash v1
#    %J: Info hash v2
#    %K: Torrent ID

#Tip: Encapsulate parameter with quotation marks to avoid text being cut off at whitespace (e.g., "%N")
#

#######
#
# Setup
#
#######

# Logs
DEST="/downloads/complete"
LOG_DATE=$(date +"%Y-%m-%d")
LOG_DIR='/scripts'
LOG_EXT='.log'
LOG_FILE="$LOG_DIR/$LOG_DATE$LOG_EXT"
LOGS_TO_KEEP=7

# Parse parameters passed in
TOR_SIZE="${1}"
NUM_FILES="${2}"
TOR_NAME="${3}"
SAVE_PATH="${4}"
CONTENT_PATH="${5}"
CATEGORY="${6}"
ROOT_PATH="${7}"

###########
#
# Functions
#
###########

function SetupLog()
{
    # Ensure log file exists
    if [[ ! -e "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi

    # Ensure log file is writable
    if [ ! -w "$LOG_FILE" ] ; then
        echo "ERROR:  Cannot write to '$LOG_FILE'"
    exit 1
    fi

    # Remove old log files
    find "${LOG_DIR}" -type f -iname '*$LOG_EXT' -mtime +$LOGS_TO_KEEP -delete -printf "Deleled '%p'\n"
}

function CopyFiles()
{
    local DEST_PATH="$DEST"

    # Add 'Category' to path, if passed in
    if [[ "${CATEGORY}" != "" ]]; then
        DEST_PATH="${DEST}/${CATEGORY}"
    fi

    # Make if it doesn't exist
    if [[ ! -e "$DEST_PATH" ]]; then
        mkdir "$DEST_PATH"
        chown -R abc:abc "$DEST_PATH"
        chmod -R 777 "$DEST_PATH"
    fi

    # Copy the folder/file(s)
    if [[ "$ROOT_PATH" != "" ]]; then
        cp -R "$ROOT_PATH" "$DEST_PATH"
        FINAL_DEST="$DEST_PATH/${ROOT_PATH##*/}"
    else
        # This should be single file TORRENTS
        cp "$CONTENT_PATH" "$DEST_PATH"
        FINAL_DEST="$DEST_PATH/${CONTENT_PATH##*/}"
    fi
}

#####
#
# Log
#
#####

SetupLog

# The following will spit out all processes to the log
exec 3>&1 1>>"$LOG_FILE" 2>&1
trap "echo 'ERROR: An error occurred during execution, check log $LOG_FILE for details.' >&3" ERR
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

# Write to log the variables passed in via the app
echo "Torrent: '$TOR_NAME'"
echo "     Category    : $CATEGORY"
echo "     Files       : $NUM_FILES"
echo "     Size        : $TOR_SIZE"
echo "     Save Path   : $SAVE_PATH"
echo "     Content Path: $CONTENT_PATH"
echo "     Root Path   : $ROOT_PATH"

######
#
# Work
#
######

# Copy files to COMPLETE folder
CopyFiles

# Update permissions
chown -R abc:abc "$FINAL_DEST"
chmod -R 777 "$FINAL_DEST"