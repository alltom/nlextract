#!/usr/bin/env bash
#
# Runs the English PCFG parser on one or more files, printing trees with headwords

if [ ! $# -ge 1 ]; then
  echo Usage: `basename $0` 'file(s)'
  echo
  exit
fi

scriptdir=`dirname $0`

java -mx150m -cp "$scriptdir/*:" edu.stanford.nlp.parser.lexparser.LexicalizedParser \
 -outputFormat penn -outputFormatOptions lexicalize edu/stanford/nlp/models/lexparser/englishPCFG.ser.gz $*
