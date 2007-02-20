#!/bin/bash
#
# Exports a GrandPerspective help book from the repository and creates a
# help index for it.
#
# Parameters:
# 1. Localization, e.g. "nl" or "English"
# 2. Tokenizer to use, e.g. "English" or "European"
# 3. Revision to check out
# 4. Force svn export? This parameter determines what happens if the target
#    help folder already exists. If the parameter equals "force", the 
#    folder is moved out of the way, and the folder is subsequently
#    exported from SVN. Otherwise, the SVN export step is simply skipped.
#    The latter is useful is a more manual/lightway method is used of
#    updating the files in the folder).

if [ $# -ne "4" ]
then
  echo "Script requires four arguments."
  exit -1
fi

LOC=$1
TOKENIZER=$2
SVN_REV=$3
FORCE=$4

VOLUME="Macintosh HD"
RESOURCE_ROOT="/Users/erwin/svn/GrandPerspective/code"
HELP_NAME=GrandPerspectiveHelp
SVN_URL=https://194.121.182.66/svn/erwin/GrandPerspective

HELP_FOLDER=${RESOURCE_ROOT}/${LOC}.lproj/${HELP_NAME}

if [ -e ${HELP_FOLDER} ]
then
  if [ "$4" == "force" ]
  then 
    OLD_FOLDER=`mktemp -d ${HELP_FOLDER}-XXXXX` || exit -1
    rmdir ${OLD_FOLDER}
    mv ${HELP_FOLDER} ${OLD_FOLDER}
    echo "Moved old help folder out of the way to:" ${OLD_FOLDER}
  fi  
fi

if [ -e ${HELP_FOLDER} ]
then
  echo "Old folder exists. Skipping svn export."
else
  svn export -q -r $SVN_REV ${SVN_URL}/trunk/help/${LOC}.lproj/${HELP_NAME} ${HELP_FOLDER}
fi

# Convert folder name to string as used by AppleScript
HELP_FOLDER_AS=`echo ${VOLUME}${HELP_FOLDER} | sed 's/\//:/g' `

osascript <<EOF
tell application "Finder"
	activate
	set folderAlias to "${HELP_FOLDER_AS}" as alias
end tell

tell application "Apple Help Indexing Tool"
	activate
	use tokenizer "${TOKENIZER}"
	turn anchor indexing "on"
	open folderAlias
end tell
EOF
