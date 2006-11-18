#!/bin/bash

VERSION="0.97"
VERSION_ID="0_97"
TEXT_PATH="/Users/erwin/svn/GrandPerspective/docs"
BUILD_PATH="/Users/erwin/svn/GrandPerspective/code/build"
TEMP_PARENT_PATH="/Users/erwin/temp"

APP_DIR="GrandPerspective.app"
OUTER_DIR="GrandPerspective-${VERSION_ID}"
OUT_SRC_FILE="GrandPerspective-${VERSION_ID}-src.tgz"
OUT_DMG_FILE="GrandPerspective-${VERSION_ID}.dmg"
OUT_NL_FILE="GrandPerspective-${VERSION_ID}-NL.tgz"

CURRENT_PATH=`pwd`

for f in xx${OUT_SRC_FILE} xx${OUT_DMG_FILE}
do
  if [ -e $f ]
  then 
    echo "Output file $f already exists. Aborting"
    exit -1
  fi
done

cd ${TEMP_PARENT_PATH}
if [ -e ${OUTER_DIR} ]
then
  echo "Temporary directory ${TEMP_PARENT_PATH}/${OUTER_DIR} already exists. Aborting"
  exit -1
fi

mkdir ${OUTER_DIR}
cd ${OUTER_DIR}

# Copy common text files (license, README, etc)
#
for f in ${TEXT_PATH}/*.txt
do
  base_f=${f##?*/}
  cat $f \
    | sed "s/GRANDPERSPECTIVE_SOFTWARE_VERSION_ID/${VERSION_ID}/g" \
    | sed "s/GRANDPERSPECTIVE_SOFTWARE_VERSION/Version ${VERSION}/g" \
  > $base_f
done

svn export /Users/erwin/svn/GrandPerspective/code raw-src
rm -rf raw-src/nl.lproj

mkdir src

# Copy Objective C source files. Also add header to each file.
#
OBJECTIVE_C_SRC=`find raw-src -name \*.[hm]`
for f in ${OBJECTIVE_C_SRC}
do
  base_f=${f#raw-src/}
  tmp="/"$base_f
  tmp=${tmp%/*}
  subdir=${tmp#/}
  if [ ! -e src/$subdir ]
  then
    mkdir src/$subdir
  fi
  # echo $f "->" $base_f "[" $subdir "]"
  cat $f \
    | sed "1,1 s|^|/* GrandPerspective, Version ${VERSION} \\
 *   A utility for Mac OS X that graphically shows disk usage. \\
 * Copyright (C) 2005-2006, Eriban Software \\
 * \\
 * This program is free software; you can redistribute it and/or modify it \\
 * under the terms of the GNU General Public License as published by the Free \\
 * Software Foundation; either version 2 of the License, or (at your option) \\
 * any later version. \\
 * \\
 * This program is distributed in the hope that it will be useful, but WITHOUT \\
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \\
 * FITNESS FOR A cPARTICULAR PURPOSE.  See the GNU General Public License for \\
 * more details. \\
 * \\
 * You should have received a copy of the GNU General Public License along \\
 * with this program; if not, write to the Free Software Foundation, Inc., \\
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. \\
 */\\
\\
|" > src/${base_f}
done

# Copy remaining (useful) source files.
#
tar cf - -C raw-src --exclude "*.[mh]" --exclude "*.pch" --exclude "*~.nib" --exclude "TODO.txt" --exclude "*.xcode" --exclude "*.icns" --exclude "version.plist" . | tar xf - -C src

# Copy application from build directory.
# 
tar cf - -C ${BUILD_PATH} ${APP_DIR} --exclude ".svn" --exclude "classes.nib" --exclude "info.nib" --exclude "nl.lproj" | tar xf - -C .

# Copy localized Dutch resources from build directory.
#
tar cf - -C ${BUILD_PATH}/${APP_DIR}/Contents/Resources nl.lproj --exclude ".svn" --exclude "classes.nib" --exclude "info.nib" | tar xf - -C .

# Create source TGZ file.
# 
cd ${TEMP_PARENT_PATH}
tar czf ${CURRENT_PATH}/${OUT_SRC_FILE} ${OUTER_DIR}/*.txt ${OUTER_DIR}/src

# Create application DMG file.
#
/Users/Erwin/bin/buildDMG.pl -dmgName ${OUT_DMG_FILE%.dmg} -volSize 1 -compressionLevel 9 ${OUTER_DIR}/*.txt ${OUTER_DIR}/${APP_DIR}

# Create Dutch resources TGZ file.
#
tar czf ${CURRENT_PATH}/${OUT_NL_FILE} -C ${OUTER_DIR} nl.lproj

# rm -rf ${OUTER_DIR}
cd ${CURRENT_DIR}