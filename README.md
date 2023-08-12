# qBittorrent
Scripts for qBittorrent's 'Run external program on torrent finished'

Ensure script is execuatable & paths updated, then plug-in the following

/bin/bash /scripts/complete.sh %Z %C "%N" "%D" "%F" "%R"

'%R' is last as it may be NULL.  If anything is after, it'll shift left any other properties passed
