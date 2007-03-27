#!/bin/bash
#
# Creates the GrandPerspective DMG release file with localized resources.
# It assumes that the disk image for the basic release file is mounted, as
# it copies the application directly from it. Release text files and the
# localized resources are taken from the SVN repository.

VERSION="0.99"
VERSION_ID="0_99"

TEMP_PARENT_PATH="/Users/erwin/temp"
TEMP_PATH=`mktemp -d ${TEMP_PARENT_PATH}/publish-local-XXXXXX` || exit -1

echo "Output to" $TEMP_PATH

DEST_PATH=$TEMP_PATH
APP_DIR="GrandPerspective.app"
RESOURCES_PATH=$DEST_PATH/$APP_DIR/Contents/Resources

SVN_URL=https://194.121.182.66/svn/erwin/GrandPerspective

OUT_DMG_FILE=GrandPerspective-${VERSION_ID}-local.dmg

echo "Copying basic application."
tar cf - -C /Volumes/GrandPerspective-${VERSION_ID} $APP_DIR | tar xf - -C $DEST_PATH

echo "Exporting text files."
./export-docs.sh trunk/docs 424 $DEST_PATH $VERSION $VERSION_ID

for loc in nl de ja
do
  echo "Exporting" $loc "resources."
  svn export -q -r 424 $SVN_URL/trunk/code/${loc}.lproj $RESOURCES_PATH/${loc}.lproj
done

# Remove unneeded nib files.
find $RESOURCES_PATH/ \( -name classes.nib -or -name info.nib \) -delete

/Users/Erwin/bin/buildDMG.pl -dmgName ${OUT_DMG_FILE%.dmg} -buildDir $TEMP_PARENT_PATH -volSize 2 -compressionLevel 9 ${DEST_PATH}/*.txt ${DEST_PATH}/${APP_DIR}

# rm -rf $TEMP_PATH


