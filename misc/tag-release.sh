#!/bin/bash

SVN_URL=https://194.121.182.66/svn/erwin/GrandPerspective
VERSION="0.98"
VERSION_ID="0_98"

TAG_URL=${SVN_URL}/tags/release-${VERSION_ID}

echo svn mkdir -m \""Creating Version ${VERSION} tag directory."\" $TAG_URL

echo svn copy -r 286 $SVN_URL/trunk/code $TAG_URL/code -m \""Tagging Version ${VERSION} of the code."\"

echo svn copy -r 286 $SVN_URL/trunk/docs $TAG_URL/docs -m \""Tagging Version ${VERSION} of the release documents."\"

for f in export-docs.sh export-source.sh publish.sh
do
  echo svn copy $SVN_URL/trunk/misc/$f $TAG_URL/$f -m \""Tagging Version ${VERSION} of the release scripts."\"
done