#!/bin/bash
#
# Creates or updates a help index.
#

if [ $# -ne "2" ]
then
  echo "Script requires two arguments."
  exit -1
fi

HELP_PATH=$1
TOKENIZER=$2

pushd /Developer/Applications/Utilities/Help\ Indexer.app/Contents/MacOS > /dev/null

./Help\ Indexer $HELP_PATH \
   -PantherIndexing YES \
   -Tokenizer $TOKENIZER \
   -ShowProgress YES -LogStyle 0

./Help\ Indexer $HELP_PATH \
   -TigerIndexing YES \
   -Tokenizer $TOKENIZER \
   -ShowProgress YES -LogStyle 0

popd > /dev/null
