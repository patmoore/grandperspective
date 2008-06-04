#!/bin/bash
#
# Script that generates commands for tagging a release of GrandPerspective.
# Modify as needed before tagging a new release.

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

VERSION="0.9.11"
VERSION_ID="0_9_11"

TAG_URL=${GP_SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r 653 $GP_SVN_URL/trunk/code $TAG_URL/code -m \""Tagging Version ${VERSION} of the code."\"

echo svn copy -r 652 $GP_SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

echo svn copy -r 652 $GP_SVN_URL/trunk/help $TAG_URL/help -m \""Tagging Version ${VERSION} of the help documentation."\"

for f in export-docs.sh export-help.sh export-source.sh publish-source.sh publish-app.sh update-help-index.sh
do
  echo svn copy -r 655 $GP_SVN_URL/trunk/bin/$f $TAG_URL/$f -m \""Tagging Version ${VERSION} of the release scripts."\"
done