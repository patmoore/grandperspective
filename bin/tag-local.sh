#!/bin/bash
#
# Script that generates commands for tagging a localized release of
# GrandPerspective. Modify as needed before tagging a new release.

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

VERSION="0.9.10 (Localized)"
VERSION_ID="0_9_10-local"

TAG_URL=${GP_SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r 556 $GP_SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

echo svn copy -r 555 $GP_SVN_URL/trunk/locs $TAG_URL/locs -m \""Tagging Version ${VERSION} of the third-party localizations."\"

for f in publish-local.sh export-docs.sh export-help.sh update-help-index.sh
do
  echo svn copy -r 557 $GP_SVN_URL/trunk/bin/$f $TAG_URL/$f -m \""Tagging Version ${VERSION} of the release scripts."\"
done