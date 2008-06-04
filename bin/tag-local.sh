#!/bin/bash
#
# Script that generates commands for tagging a localized release of
# GrandPerspective. Modify as needed before tagging a new release.

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

VERSION="0.9.11 (Localized)"
VERSION_ID="0_9_11-local"

REV=667
BIN_REV=668

TAG_URL=${GP_SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r $REV $GP_SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

echo svn mkdir -m \""Creating Version ${VERSION} tag/locs directory."\" $TAG_URL/locs

for loc in ja
do
  echo svn copy -r $REV $GP_SVN_URL/trunk/locs/${loc}.lproj $TAG_URL/locs/${loc}.lproj -m \""Tagging Version ${VERSION} of the third-party localizations."\"
done

for f in publish-local.sh export-docs.sh export-help.sh update-help-index.sh
do
  echo svn copy -r $BIN_REV $GP_SVN_URL/trunk/bin/$f $TAG_URL/$f -m \""Tagging Version ${VERSION} of the release scripts."\"
done