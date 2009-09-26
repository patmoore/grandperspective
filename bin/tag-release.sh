#!/bin/bash
#
# Script that generates commands for tagging a release of GrandPerspective.
# Modify as needed before tagging a new release.

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

VERSION="1.0"
VERSION_ID="1_0"
SRC_REV=1073
BIN_REV=1074

TAG_URL=${GP_SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r $SRC_REV $GP_SVN_URL/trunk/code $TAG_URL/code -m \""Tagging Version ${VERSION} of the code."\"

echo svn copy -r $SRC_REV $GP_SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

echo svn copy -r $SRC_REV $GP_SVN_URL/trunk/help $TAG_URL/help -m \""Tagging Version ${VERSION} of the help documentation."\"

echo svn copy -r $BIN_REV $GP_SVN_URL/trunk/bin $TAG_URL/bin -m \""Tagging Version ${VERSION} of the scripts."\"
