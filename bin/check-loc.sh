#!/bin/bash
#
# Checks the .string files of two localizations of GrandPerspective to
# see if both contain exactly the same key strings. If there is a string
# missing in one localization (which can also mean that the string is
# superfluous in the other), it will be output.

if [ $# -ne "2" ]
then
  echo "Script requires two arguments."
  exit -1
fi

ENGLISH_PATH=$1
OTHER_PATH=$2

for f in Localizable.strings Tests.strings Names.strings
do
  echo $f
  iconv -f UTF-16 -t UTF-8 $ENGLISH_PATH/$f $OTHER_PATH/$f \
    | awk -f extract-keys.awk | sort | uniq -u \
    | awk '{ print "  ", $0; }'
done

