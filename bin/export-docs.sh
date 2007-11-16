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

if [ ! -e $DEST_DIR ]
then
  echo "Output folder" $DEST_DIR "does not exist."
  exit -2
fi

TEMP_EXPORT_DIR=${TEMP_DIR}/export-docs-$$

svn export -q -r $SVN_REV $GP_SVN_URL/$SVN_PATH $TEMP_EXPORT_DIR

for f in ${TEMP_EXPORT_DIR}/*.txt
do
  base_f=${f##?*/}
  cat $f \
    | sed "s/GRANDPERSPECTIVE_SOFTWARE_VERSION_ID/${VERSION_ID}/g" \
    | sed "s/GRANDPERSPECTIVE_SOFTWARE_VERSION/Version ${VERSION}/g" \
  > $DEST_DIR/$base_f
done

rm $TEMP_EXPORT_DIR/*.txt
rmdir $TEMP_EXPORT_DIR
