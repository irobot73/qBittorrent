# 08-12-2023 - Initial version

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

# Setup
DEST="/downloads/complete"
TODAY=$(date +"%d-%m-%Y")
LOG="/scripts/${TODAY}_log.txt"

TOR_SIZE="${1}"
NUM_FILES="${2}"
TOR_NAME="${3}"
SAVE_PATH="${4}"
CONTENT_PATH="${5}"
ROOT_PATH="${6}"

function SetupLog()
{
    # Ensure log file exists
    if [[ ! -e "$LOG" ]]; then
        touch "$LOG"
    fi

    if [ ! -w "$LOG" ] ; then
        echo "Cannot write to '$LOG'" >&3
    exit 1
    fi
}

SetupLog
exec 3>&1 1>>"$LOG" 2>&1
trap "echo 'ERROR: An error occurred during execution, check log $LOG for details.' >&3" ERR
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

echo "Torrent: '$TOR_NAME'" >&3
echo "     Files       : $NUM_FILES" >&3
echo "     Size        : $TOR_SIZE" >&3
echo "     Save Path   : $SAVE_PATH" >&3
echo "     Content Path: $CONTENT_PATH" >&3
echo "     Root Path   : $ROOT_PATH" >&3

#
# Work
#

FINAL_DEST="";

# Copy files to COMPLETE folder
if [[ "$ROOT_PATH" != "" ]]; then
        cp -R "$ROOT_PATH" /downloads/complete
        FINAL_DEST="/downloads/complete/${ROOT_PATH##*/}"
    else
        # This should be single file TORRENTS
        cp "$CONTENT_PATH" /downloads/complete
        FINAL_DEST="/downloads/complete/${CONTENT_PATH##*/}"
    fi
# Update permissions
chown -R abc:abc "$FINAL_DEST"
chmod -R 777 "$FINAL_DEST"


