#!/bin/bash
#
# Updates localized resources provided by third-party in a Subversion
# working copy. It leaves the administrative SVN files in place, but
# removes all other files, and replaces them by the new ones. Note: you
# may have to invoke "svn remove" and/or "svn add" before commiting.

if [ $# -ne "2" ]
then
  echo "Script requires two arguments."
  exit -1
fi

FROM_DIR=$1
TO_DIR=$2

for fold in `find ${TO_DIR} -not -path \*/.svn/\* -and -type f`
do
  rm $fold
done

for fin in `find ${FROM_DIR} -type f`
do
  fout=${TO_DIR}${fin#${FROM_DIR}}
  cp $fin $fout
done