#!/bin/bash
app="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
#source "$app/functions.sh"
#set -x

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

###########
#
# Variables
#
###########

# Logs
DEST="/downloads/complete"
LOG_DATE=$(date +"%Y-%m-%d")
LOG_DIR='/scripts'
LOG_EXT='.log'
LOG_FILE="$LOG_DIR/$LOG_DATE$LOG_EXT"
LOG_DAYS_TO_KEEP=3 # NOTE: It's technically N+1

# All possible parameters that can be passed from qBittorrent
TOR_NAME=""
CATEGORY=""
TAGS=""
CONTENT_PATH=""
ROOT_PATH=""
SAVE_PATH=""
NUM_FILES=0
TOR_SIZE=0
CURR_TRACKER=""
HASH_V1=""
HASH_V2=""
TORR_ID=0

# Parse the flags/parameters that were passed from qBittorren
while getopts ":n:l:g:f:r:d:c:z:t:i:j:k:" flag; do
    case "${flag}" in
        n)
            TOR_NAME="$OPTARG"
            ;;
        l)
            CATEGORY="$OPTARG"
            ;;
        g)
            TAGS="$OPTARG"
            ;;
        f)
            CONTENT_PATH="$OPTARG"
            ;;
        r)
            ROOT_PATH="$OPTARG"
            ;;
        d)
            SAVE_PATH="$OPTARG"
            ;;
        c)
            NUM_FILES="$OPTARG"
            ;;
        z)
            TOR_SIZE="$OPTARG"
            ;;
        t)
            CURR_TRACKER="$OPTARG"
            ;;
        i)
            HASH_V1="$OPTARG"
            ;;
        j)
            HASH_V2="$OPTARG"
            ;;
        k)
            TORR_ID="$OPTARG"
            ;;
        *)
            echo "Usage: [script_file] [-f "%F"] [-d "%D"]..."
            exit 1
            ;;
    esac
done

###########
#
# Functions
#
###########

function PrepLogFile
{
    # Ensure log file exists
    if [[ ! -e "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi

    # Ensure log file is writable
    if [ ! -w "$LOG_FILE" ] ; then
        exit 1
    fi
}

function SetupLogging
{
    # The following will spit out all processes to the log
    exec 3>&1 1>>"$LOG_FILE" 2>&1
    trap "echo 'ERROR: An error occurred during execution, check log $LOG_FILE for details.' >&3" ERR
    trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG
}

function PurgeLogFiles
{
    if [[ -z "$LOG_DAYS_TO_KEEP" ]]; then
        echo "INFO:  'LOG_DAYS_TO_KEEP' variable not set.  No clean-up performed."
    else
        if [[ "$LOG_DAYS_TO_KEEP" -gt "0" ]]; then
            # Remove old log files
            # NOTE:  
            find "$LOG_DIR" -maxdepth 1 -daystart -type f -iname "*$LOG_EXT" -mtime +$LOG_DAYS_TO_KEEP -exec rm -v '{}' + 
        else
            echo "WARNING:  'LOG_DAYS_TO_KEEP' must be greater than 0 to perform any work."
        fi
    fi
}

function DebugToLog
{
    # Echo the variables passed in via the app
    echo "Torrent: '$TOR_NAME'"
    echo "     Category    : $CATEGORY"
    echo "     Content Path: $CONTENT_PATH"
    echo "     Curr Tracker: $CURR_TRACKER"
    echo "     Identifier  : $TORR_ID"
    echo "     Info Hash v1: $HASH_V1"
    echo "     Info Hash v2: $HASH_V2"
    echo "     Number Files: $NUM_FILES"
    echo "     Root Path   : $ROOT_PATH"
    echo "     Size        : $TOR_SIZE"
    echo "     Save Path   : $SAVE_PATH"
    echo "     Tags        : $TAGS"
}

function CopyFiles
{
    local DEST_PATH="$DEST"

    # Add 'Category' to path, if passed in
    if [[ "${CATEGORY}" != "" ]]; then
        DEST_PATH="${DEST}/${CATEGORY}"
    fi

    FinalDestinationValidation "$DEST_PATH"

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

fucntion FinalDestinationValidation
{
    # Make if it doesn't exist
    if [[ ! -e "${1}" ]]; then
        mkdir "${1}"
        SetPerms "${1}"
    # Else, verify it's actually a directory
    elif [[ ! -d "${1}" ]]; then
        echo "'$1' already exists but is not a directory."
        exit 2
    fi
}

function SetPerms
{
    chown -R abc:abc "${1}"
    chmod -R 777 "${1}"
}

#########
#
# Logging
#
#########

PrepLogFile
SetupLogging
PurgeLogFiles

# (UN)Comment as desired
DebugToLog

######
#
# Work
#
######

# Copy files to COMPLETE folder
CopyFiles

# Update permissions
SetPerms "$FINAL_DEST"

echo -e 'Done.\n\n'
exit 0

#
# 08-12-2023 v01.00 - Initial version
# 08-12-2023 v01.50 - Added handling of 'Category'
#   Run external program on torrent finished:
#       '/bin/bash /scripts/complete.sh %Z %C "%N" "%D" "%F" "%L" "%R"'
# 08-12-2023 v01.70 - Added logic to delete old log files
# 08-12-2023 v01.75 - Added output during delete old log files
# 08-12-2023 v01.80 - Variables in log clean-up added
# 08-13-2023 v01.82 - Removed unnecessary redirects and cleaed-up LOG logic
# 08-13-2023 v02.00 - Use and parse FLAGS to handle null/empty parameters
#   (order of parameter won't matter)
#   Run external program on torrent finished:
#       '/bin/bash /scripts/complete.sh -n "%N" -l "%L" -f "%F" -r "%R" -c "%D" -c %C -z %Z -i "%I" -j "%J" -k "%K"'
# 08-26-2023 v01.85 - Logging to functions & fixed purge logic
# 08-26-2023 v01.86 - Fixed & tested logic in 'RotateLogFiles'
# 08-26-2023 v01.90 - Logic flow corrections
# 08-27-2023 v01.95 - Refactored & created 'FinalDestinationValidation' function
#