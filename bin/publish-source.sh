#!/bin/bash

VERSION="0.9.11"
VERSION_ID="0_9_11"

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

HELP_FOLDER=GrandPerspectiveHelp
OUTER_DIR="GrandPerspective-${VERSION_ID}"
OUTER_DIR_PATH=$TEMP_PUBLISH_DIR/$OUTER_DIR
OUT_FILE="GrandPerspective-${VERSION_ID}-src.tgz"

mkdir $OUTER_DIR_PATH

echo "Exporting text files."
./export-docs.sh trunk/docs 652 $OUTER_DIR_PATH $VERSION $VERSION_ID

mkdir $OUTER_DIR_PATH/src
echo "Exporting source code."
./export-source.sh trunk/code 653 $OUTER_DIR_PATH/src $VERSION

echo "Exporting help documentation."
./export-help.sh 652 $OUTER_DIR_PATH/src English
./export-help.sh 652 $OUTER_DIR_PATH/src nl

echo "Generating help indexes."
./update-help-index.sh $OUTER_DIR_PATH/src/English.lproj/$HELP_FOLDER English

echo -n "[Please press return once the indexing is done]" 
read dummy

./update-help-index.sh $OUTER_DIR_PATH/src/nl.lproj/$HELP_FOLDER European

echo -n "[Please press return once the indexing is done]" 
read dummy


echo "Creating TGZ file."
pushd $TEMP_PUBLISH_DIR > /dev/null
tar czf $DEST_PATH/$OUT_FILE ${OUTER_DIR}
popd > /dev/null

rm -rf $TEMP_PUBLISH_DIR
