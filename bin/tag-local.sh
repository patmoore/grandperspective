#!/bin/bash
#
# Script that generates commands for tagging a localized release of
# GrandPerspective. Modify as needed before tagging a new release.

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

VERSION="0.9.13.1 (Localized)"
VERSION_ID="0_9_13_1-local"

REV=955
NL_REV=955
BIN_REV=957

TAG_URL=${GP_SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r $REV $GP_SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

echo svn copy -r $REV $GP_SVN_URL/trunk/code/Credits.rtf $TAG_URL/docs/Credits.rtf -m \""Tagging Version ${VERSION} of the credits."\"


echo svn mkdir -m \""Creating Version ${VERSION} tag/locs directory."\" $TAG_URL/locs

for loc in ja fr es
do
  echo svn copy -r $REV $GP_SVN_URL/trunk/locs/${loc}.lproj $TAG_URL/locs/${loc}.lproj -m \""Tagging Version ${VERSION} of the third-party localizations."\"
done

echo svn copy -r $NL_REV $GP_SVN_URL/trunk/code/nl.lproj $TAG_URL/locs/nl.lproj -m \""Tagging Version ${VERSION} of the Dutch localization."\"
echo svn copy -r $NL_REV $GP_SVN_URL/trunk/help/nl.lproj/GrandPerspectiveHelp $TAG_URL/locs/nl.lproj/GrandPerspectiveHelp -m \""Tagging Version ${VERSION} of the Dutch help."\"

echo svn copy -r $BIN_REV $GP_SVN_URL/trunk/bin $TAG_URL/bin -m \""Tagging Version ${VERSION} of the scripts."\"
