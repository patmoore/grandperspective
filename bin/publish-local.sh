#!/bin/bash
#
# Creates the GrandPerspective DMG release file with localized resources.
# It assumes that the disk image for the basic release file is mounted, as
# it copies the application directly from it. Release text files and the
# localized resources are taken from the SVN repository.

# The version of the main (non-localized) release
VERSION="1.0"

# The sub-version of this localized release (multiple localized versions
# may be released for a given main release, as more localizations are 
# provided over time)
LOCAL_VERSION="1"

# The revision to use for all 3rd party localizations
REV=1075

# The revision to use for the Dutch localization (it is specified 
# separately, as revision REV may already include updates to the Dutch
# resources that apply to the next main release of the application)
NL_REV=1073

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

VERSION_ID=$( echo $VERSION | tr ". " "_-" )
LOCAL_VERSION_ID=$( echo $LOCAL_VERSION | tr ". " "_-" )

APP_FOLDER=GrandPerspective.app
HELP_FOLDER=GrandPerspectiveHelp
RESOURCES_PATH=$TEMP_PUBLISH_DIR/$APP_FOLDER/Contents/Resources

OUT_DMG_FILE=GrandPerspective-${VERSION_ID}-L${LOCAL_VERSION_ID}.dmg
VOLUME_NAME="GrandPerspective ${VERSION} (Localized v${LOCAL_VERSION})"

echo "Copying basic application."
tar cf - -C "/Volumes/GrandPerspective ${VERSION}" $APP_FOLDER | tar xf - -C $TEMP_PUBLISH_DIR

echo "Exporting text files."
./export-docs.sh trunk/docs $REV $TEMP_PUBLISH_DIR $VERSION $VERSION_ID

echo "Exporting credits."
svn export -q -r $REV $GP_SVN_URL/trunk/code/Credits.rtf $RESOURCES_PATH/Credits.rtf

echo "Exporting nl resources."
svn export -q -r $NL_REV $GP_SVN_URL/trunk/code/nl.lproj $RESOURCES_PATH/nl.lproj

echo "Exporting nl help documentation."
./export-help.sh $NL_REV $RESOURCES_PATH nl

for loc in ja fr es
do
  echo "Exporting" $loc "resources."
  svn export -q -r $REV $GP_SVN_URL/trunk/locs/${loc}.lproj $RESOURCES_PATH/${loc}.lproj
done

echo "Updating nl help index."
./update-help-index.sh $RESOURCES_PATH/nl.lproj/$HELP_FOLDER European

echo "Updating fr help index."
./update-help-index.sh $RESOURCES_PATH/fr.lproj/$HELP_FOLDER European

echo "Updating es help index."
./update-help-index.sh $RESOURCES_PATH/es.lproj/$HELP_FOLDER European

# Remove unneeded nib files.
find $RESOURCES_PATH/ \( -name classes.nib -or -name info.nib \) -delete

/Users/Erwin/bin/buildDMG.pl -dmgName ${OUT_DMG_FILE%.dmg} -volName "${VOLUME_NAME}" -buildDir $DEST_PATH -volSize 4 -compressionLevel 9 ${TEMP_PUBLISH_DIR}/*.txt ${TEMP_PUBLISH_DIR}/${APP_FOLDER}

rm -rf $TEMP_PUBLISH_DIR

