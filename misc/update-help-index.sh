#!/bin/bash
#
# Creates or updates a help index.
#

if [ $# -ne "2" ]
then
  echo "Script requires two arguments."
  exit -1
fi

HELP_PATH=$1
TOKENIZER=$2

VOLUME="Macintosh HD"

# Convert path name to string as used by AppleScript
HELP_PATH_AS=`echo ${VOLUME}${HELP_PATH} | sed 's/\//:/g' `

osascript <<EOF
tell application "Finder"
	activate
	set folderAlias to "${HELP_PATH_AS}" as alias
end tell

tell application "Apple Help Indexing Tool"
	activate
	use tokenizer "${TOKENIZER}"
	turn anchor indexing "on"
	open folderAlias
end tell
EOF
