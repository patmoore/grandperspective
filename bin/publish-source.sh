#!/bin/bash

VERSION="0.99"
VERSION_ID="0_99"
TEMP_PARENT_PATH="/Users/erwin/temp"
TEMP_PATH=`mktemp -d ${TEMP_PARENT_PATH}/publish-XXXXXX` || exit -1

echo "Output to" $TEMP_PATH

HELP_FOLDER=GrandPerspectiveHelp
OUTER_DIR="GrandPerspective-${VERSION_ID}"
OUTER_DIR_PATH=$TEMP_PATH/$OUTER_DIR
OUT_FILE="GrandPerspective-${VERSION_ID}-src.tgz"

if [ $# -ne "1" ]
then
  echo "Script requires one argument."
  exit -1
fi

DEST_PATH=$1

mkdir $OUTER_DIR_PATH

echo "Exporting text files."
./export-docs.sh trunk/docs 383 $OUTER_DIR_PATH $VERSION $VERSION_ID

mkdir $OUTER_DIR_PATH/src
echo "Exporting source code."
./export-source.sh trunk/code 385 $OUTER_DIR_PATH/src $VERSION

echo "Exporting help documentation."
./export-help.sh trunk/help 390 $OUTER_DIR_PATH/src English
./export-help.sh trunk/help 390 $OUTER_DIR_PATH/src nl

echo "Generating help indexes."
./update-help-index.sh $OUTER_DIR_PATH/src/English.lproj/$HELP_FOLDER English

echo -n "[Please press return once the indexing is done]" 
read dummy

./update-help-index.sh $OUTER_DIR_PATH/src/nl.lproj/$HELP_FOLDER European

echo -n "[Please press return once the indexing is done]" 
read dummy


echo "Creating TGZ file."
pushd $TEMP_PATH > /dev/null
tar czf $DEST_PATH/$OUT_FILE ${OUTER_DIR}
popd > /dev/null

rm -rf $TEMP_PATH
