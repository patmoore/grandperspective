#!/bin/bash
#
# Exports GrandPerspective source code from the repository. It also
# processes the source files by adding a header, and furthermore excludes
# a few less relevant files.

if [ $# -ne "4" ]
then
  echo "Script requires four arguments."
  exit -1
fi

SVN_PATH=$1
SVN_REV=$2
DEST_DIR=$3
VERSION=$4

if [[ "$TEMP_DIR" == "" || ! -d $TEMP_DIR ]]
then
  echo "TEMP_DIR not set (correctly)."
  exit -1
fi

TEMP_EXPORT_DIR=${TEMP_DIR}/export-source-$$

if [ "$GP_SVN_URL" == "" ]
then
  echo "GP_SVN_UR not set correctly."
  exit -1
fi

if [ ! -e $DEST_DIR ]
then
  echo "Output folder" $DEST_DIR "does not exist."
  exit -2
fi

svn export -q -r $SVN_REV $GP_SVN_URL/$SVN_PATH $TEMP_EXPORT_DIR

# Exclude all localizations except the English and Dutch
mv $TEMP_EXPORT_DIR/nl.lproj $TEMP_EXPORT_DIR/Dutch.lproj
rm -rf $TEMP_EXPORT_DIR/??.lproj
mv $TEMP_EXPORT_DIR/Dutch.lproj $TEMP_EXPORT_DIR/nl.lproj

# Exclude sources files that are not part of the release
rm -rf $TEMP_EXPORT_DIR/xutil

# Copy Objective C source files. Also add header to each file.
#
OBJECTIVE_C_SRC=`find $TEMP_EXPORT_DIR -name \*.[hm]`
for f in ${OBJECTIVE_C_SRC}
do
  base_f=${f#${TEMP_EXPORT_DIR}/}
  tmp="/"$base_f
  tmp=${tmp%/*}
  subdir=${tmp#/}
  if [ ! -e $DEST_DIR/$subdir ]
  then
    mkdir $DEST_DIR/$subdir
  fi
  # echo $f "->" $base_f "[" $subdir "]"
  cat $f \
    | sed "1,1 s|^|/* GrandPerspective, Version ${VERSION} \\
 *   A utility for Mac OS X that graphically shows disk usage. \\
 * Copyright (C) 2005-2008, Erwin Bonsma \\
 * \\
 * This program is free software; you can redistribute it and/or modify it \\
 * under the terms of the GNU General Public License as published by the Free \\
 * Software Foundation; either version 2 of the License, or (at your option) \\
 * any later version. \\
 * \\
 * This program is distributed in the hope that it will be useful, but WITHOUT \\
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \\
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for \\
 * more details. \\
 * \\
 * You should have received a copy of the GNU General Public License along \\
 * with this program; if not, write to the Free Software Foundation, Inc., \\
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. \\
 */\\
\\
|" > $DEST_DIR/${base_f}
done

# Copy remaining source files.
#
tar cf - -C $TEMP_EXPORT_DIR --exclude "*.[mh]" . | tar xf - -C $DEST_DIR

rm -rf $TEMP_EXPORT_DIR
