#!/bin/bash
#
# Exports GrandPerspective text files (ReadMe, ChangeLog, etc) from the
# repository, and post-processes these files for inclusion in a release
# of the application.

if [ $# -ne "5" ]
then
  echo "Script requires five arguments."
  exit -1
fi

SVN_PATH=$1
SVN_REV=$2
DEST_DIR=$3
VERSION=$4
VERSION_ID=$5

TEMP_PARENT_DIR="/Users/erwin/temp"
TEMP_DIR=${TEMP_PARENT_DIR}"/export-docs.tmp"

if [ ! -e $DEST_DIR ]
then
  echo "Output folder" $DEST_DIR "does not exist."
  exit -2
fi

svn export -r $SVN_REV https://194.121.182.66/svn/erwin/GrandPerspective/$SVN_PATH $TEMP_DIR

for f in ${TEMP_DIR}/*.txt
do
  base_f=${f##?*/}
  cat $f \
    | sed "s/GRANDPERSPECTIVE_SOFTWARE_VERSION_ID/${VERSION_ID}/g" \
    | sed "s/GRANDPERSPECTIVE_SOFTWARE_VERSION/Version ${VERSION}/g" \
  > $DEST_DIR/$base_f
done

rm $TEMP_DIR/*.txt
rmdir $TEMP_DIR