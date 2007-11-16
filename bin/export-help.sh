#!/bin/bash
#
# Exports a GrandPerspective help book from the repository.
#

if [ $# -ne "3" ]
then
  echo "Script requires three arguments."
  exit -1
fi

SVN_REV=$1
DEST_DIR=$2
LOC=$3

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

HELP_NAME=GrandPerspectiveHelp

svn export -q -r $SVN_REV ${GP_SVN_URL}/trunk/help/${LOC}.lproj/${HELP_NAME} ${DEST_DIR}/${LOC}.lproj/${HELP_NAME}
