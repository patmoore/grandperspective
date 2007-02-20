#!/bin/bash

VERSION="0.98"
VERSION_ID="0_98"
TEXT_PATH="/Users/erwin/svn/GrandPerspective/docs"
BUILD_PATH="/Users/erwin/svn/GrandPerspective/build"
TEMP_PARENT_PATH="/Users/erwin/temp"
TEMP_PATH=`mktemp -d ${TEMP_PARENT_PATH}/publish-XXXXXX` || exit -1

echo "Output to" $TEMP_PATH

APP_DIR="GrandPerspective.app"
OUTER_DIR="GrandPerspective-${VERSION_ID}"
OUTER_DIR_PATH=$TEMP_PATH/$OUTER_DIR
OUT_SRC_FILE="GrandPerspective-${VERSION_ID}-src.tgz"
OUT_DMG_FILE="GrandPerspective-${VERSION_ID}.dmg"
OUT_NL_FILE="GrandPerspective-${VERSION_ID}-NL.tgz"

if [ $# -ne "1" ]
then
  echo "Script requires one argument."
  exit -1
fi

DEST_PATH=$1

mkdir ${OUTER_DIR_PATH}

echo "Exporting text files."
./export-docs.sh trunk/docs 286 $OUTER_DIR_PATH $VERSION $VERSION_ID

mkdir $OUTER_DIR_PATH/src
echo "Exporting source code."
./export-source.sh trunk/code 286 $OUTER_DIR_PATH/src $VERSION

# Copy application from build directory.
# 
tar cf - -C ${BUILD_PATH} ${APP_DIR} --exclude ".svn" --exclude "classes.nib" --exclude "info.nib" --exclude "nl.lproj" | tar xf - -C $OUTER_DIR_PATH

# Copy localized Dutch resources from build directory.
#
tar cf - -C ${BUILD_PATH}/${APP_DIR}/Contents/Resources nl.lproj --exclude ".svn" --exclude "classes.nib" --exclude "info.nib" | tar xf - -C $OUTER_DIR_PATH

# Create source TGZ file.
# 
pushd $TEMP_PATH > /dev/null
tar czf $DEST_PATH/$OUT_SRC_FILE ${OUTER_DIR}/*.txt ${OUTER_DIR}/src
popd > /dev/null

# Create application DMG file.
#
pushd $DEST_PATH > /dev/null
/Users/Erwin/bin/buildDMG.pl -dmgName ${OUT_DMG_FILE%.dmg} -volSize 1 -compressionLevel 9 ${OUTER_DIR_PATH}/*.txt ${OUTER_DIR_PATH}/${APP_DIR}
popd > /dev/null

# Create Dutch resources TGZ file.
#
tar czf $DEST_PATH/$OUT_NL_FILE -C ${OUTER_DIR_PATH} nl.lproj

echo rm -rf $TEMP_PATH
