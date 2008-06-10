#!/bin/bash

if [ $# -ne "3" ]
then
  echo "Script requires three arguments."
  exit -1
fi

SOURCE_TGZ=$1
APP_PATH=$2
DEST_PATH=$3

if [[ "$TEMP_DIR" == "" || ! -d $TEMP_DIR ]]
then
  echo "TEMP_DIR not set (correctly)."
  exit -1
fi

TEMP_PUBLISH_DIR=`mktemp -d ${TEMP_DIR}/publish-XXXXXX` || exit -1

echo "Temporary output to" $TEMP_PUBLISH_DIR

TMP=${SOURCE_TGZ##*/}
TMP=${TMP#GrandPerspective-}
VERSION_ID=${TMP%-src.tgz}

echo "Version" $VERSION_ID

BIN_DIR=`pwd`

OUTER_DIR=GrandPerspective-${VERSION_ID}
OUTER_DIR_PATH=$TEMP_PUBLISH_DIR/$OUTER_DIR
OUT_DMG_FILE=GrandPerspective-${VERSION_ID}.dmg

echo "Extracting source archive"
tar xzf $SOURCE_TGZ -C $TEMP_PUBLISH_DIR

rm -rf $OUTER_DIR_PATH/src

echo "Copying application"
mkdir $OUTER_DIR_PATH/GrandPerspective.app
tar cf - -C ${APP_PATH} --exclude "classes.nib" --exclude "info.nib" --exclude "nl.lproj" . | tar xf - -C $OUTER_DIR_PATH/GrandPerspective.app

# Create application DMG file.
#
pushd $DEST_PATH > /dev/null
$BIN_DIR/buildDMG.pl -dmgName ${OUT_DMG_FILE%.dmg} -volSize 2 -compressionLevel 9 $OUTER_DIR_PATH/*.txt $OUTER_DIR_PATH/GrandPerspective.app
popd > /dev/null

echo rm -rf $TEMP_PUBLISH_DIR
