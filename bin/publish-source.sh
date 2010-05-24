#!/bin/bash

VERSION="1.3.3"
REV=1273

if [ $# -ne "1" ]
then
  echo "Script requires one argument."
  exit -1
fi

DEST_PATH=$1

if [[ "$TEMP_DIR" == "" || ! -d $TEMP_DIR ]]
then
  echo "TEMP_DIR not set (correctly)."
  exit -1
fi

TEMP_PUBLISH_DIR=`mktemp -d ${TEMP_DIR}/publish-XXXXXX` || exit -1
echo "Temporary output to" $TEMP_PUBLISH_DIR

VERSION_ID=$( echo $VERSION | tr ". " "_-" )

HELP_FOLDER=GrandPerspectiveHelp
OUTER_DIR="GrandPerspective-${VERSION_ID}"
OUTER_DIR_PATH=$TEMP_PUBLISH_DIR/$OUTER_DIR
OUT_FILE="GrandPerspective-${VERSION_ID}-src.tgz"

mkdir $OUTER_DIR_PATH

echo "Exporting text files."
./export-docs.sh trunk/docs $REV $OUTER_DIR_PATH $VERSION $VERSION_ID

mkdir $OUTER_DIR_PATH/src
echo "Exporting source code."
./export-source.sh trunk/code $REV $OUTER_DIR_PATH/src $VERSION

echo "Exporting help documentation."
./export-help.sh $REV $OUTER_DIR_PATH/src English
./export-help.sh $REV $OUTER_DIR_PATH/src nl

echo "Generating help indexes."
./update-help-index.sh $OUTER_DIR_PATH/src/English.lproj/$HELP_FOLDER 1
./update-help-index.sh $OUTER_DIR_PATH/src/nl.lproj/$HELP_FOLDER 2

echo "Creating TGZ file."
pushd $TEMP_PUBLISH_DIR > /dev/null
tar czf $DEST_PATH/$OUT_FILE ${OUTER_DIR}
popd > /dev/null

rm -rf $TEMP_PUBLISH_DIR
