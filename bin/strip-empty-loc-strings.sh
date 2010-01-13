#!/bin/bash
#
# Strips empty strings from strings files extracted from NIB files.
# Given that they're empty, there is no need to localize these.

if [ $# -ne "1" ]
then
  echo "Script requires one argument."
  exit -1
fi

STRINGS_FILE=$1

mv $STRINGS_FILE $STRINGS_FILE.old
iconv -f UTF-16 -t UTF-8 $STRINGS_FILE.old \
  | sed -n -f strip-empty-loc-strings.sed \
  | sed "1d" \
  | iconv -f UTF-8 -t UTF-16 \
  > $STRINGS_FILE