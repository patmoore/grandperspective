#!/bin/bash
#
# Script that generates commands for tagging a release of GrandPerspective.
# Modify as needed before tagging a new release.

SVN_URL=https://194.121.182.66/svn/erwin/GrandPerspective
VERSION="0.99"
VERSION_ID="0_99"

TAG_URL=${SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r 385 $SVN_URL/trunk/code $TAG_URL/code -m \""Tagging Version ${VERSION} of the code."\"

echo svn copy -r 383 $SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

echo svn copy -r 390 $SVN_URL/trunk/help $TAG_URL/help -m \""Tagging Version ${VERSION} of the help documentation."\"

for f in export-docs.sh export-help.sh export-source.sh publish-source.sh publish-app.sh update-help-index.sh
do
  echo svn copy $SVN_URL/trunk/misc/$f $TAG_URL/$f -m \""Tagging Version ${VERSION} of the release scripts."\"
done