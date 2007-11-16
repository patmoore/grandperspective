#!/bin/bash
#
# Creates the GrandPerspective DMG release file with localized resources.
# It assumes that the disk image for the basic release file is mounted, as
# it copies the application directly from it. Release text files and the
# localized resources are taken from the SVN repository.

VERSION="0.99"
VERSION_ID="0_99"
REV=427

if [ $# -ne "1" ]
then
  echo "Script requires one argument."
  exit -1
fi

DEST_PATH=$1

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_URL not set correctly."
  exit -1
fi

if [[ "$TEMP_DIR" == "" || ! -d $TEMP_DIR ]]
then
  echo "TEMP_DIR not set (correctly)."
  exit -1
fi

TEMP_PUBLISH_DIR=`mktemp -d ${TEMP_DIR}/publish-local-XXXXXX` || exit -1

echo "Temporary output to" $TEMP_PUBLISH_DIR

APP_FOLDER=GrandPerspective.app
HELP_FOLDER=GrandPerspectiveHelp
RESOURCES_PATH=$TEMP_PUBLISH_DIR/$APP_FOLDER/Contents/Resources

OUT_DMG_FILE=GrandPerspective-${VERSION_ID}-local.dmg

echo "Copying basic application."
tar cf - -C /Volumes/GrandPerspective-${VERSION_ID} $APP_FOLDER | tar xf - -C $TEMP_PUBLISH_DIR

echo "Exporting text files."
./export-docs.sh trunk/docs $REV $TEMP_PUBLISH_DIR $VERSION $VERSION_ID

for loc in nl de ja
do
  echo "Exporting" $loc "resources."
  svn export -q -r $REV $GP_SVN_URL/trunk/code/${loc}.lproj $RESOURCES_PATH/${loc}.lproj
done

echo "Exporting nl help documentation."
./export-help.sh $REV $RESOURCES_PATH nl

echo "Updating nl help index."
./update-help-index.sh $RESOURCES_PATH/nl.lproj/$HELP_FOLDER European

echo -n "[Please press return once the indexing is done]" 
read dummy

# Remove unneeded nib files.
find $RESOURCES_PATH/ \( -name classes.nib -or -name info.nib \) -delete

/Users/Erwin/bin/buildDMG.pl -dmgName ${OUT_DMG_FILE%.dmg} -buildDir $DEST_PATH -volSize 2 -compressionLevel 9 ${TEMP_PUBLISH_DIR}/*.txt ${TEMP_PUBLISH_DIR}/${APP_FOLDER}

rm -rf $TEMP_PUBLISH_DIR

