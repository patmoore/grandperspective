#!/bin/bash
#
# Exports a GrandPerspective help book from the repository.
#

if [ $# -ne "4" ]
then
  echo "Script requires four arguments."
  exit -1
fi

SVN_PATH=$1
SVN_REV=$2
DEST_DIR=$3
LOC=$4

HELP_NAME=GrandPerspectiveHelp
SVN_URL=https://194.121.182.66/svn/erwin/GrandPerspective

svn export -q -r $SVN_REV ${SVN_URL}/trunk/help/${LOC}.lproj/${HELP_NAME} ${DEST_DIR}/${LOC}.lproj/${HELP_NAME}
