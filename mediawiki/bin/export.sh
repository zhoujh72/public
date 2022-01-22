#!/bin/bash

# Author  : Zhou Jinghui
# Date    : 2019/03/04
# Purpose : Export a snapshot of the MediaWiki site without any history record

ME=$(basename $0)

if [ $# -ne 1 ]; then
    echo "USAGE: $ME <export_file_tag>"
    exit
fi

echo
echo "1) Creating a snapshot of all wiki pages ..."
COMMAND="php $WIKI_HOME/maintenance/dumpBackup.php --current --quiet | gzip > $1.xml.gz"
echo "    \$ $COMMAND"
sh -c "$COMMAND"
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to create page snapshot, error = $ERROR"
    exit
fi

echo
echo "2) Creating a snapshot of all wiki images ..."
COMMAND="php $WIKI_HOME/maintenance/dumpUploads.php --base mwstore://local-backend/local-public | xargs tar -C $WIKI_HOME/images/ -czf $1.tar.gz"
echo "    \$ $COMMAND"
sh -c "$COMMAND"
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to create image snapshot, error = $ERROR"
    exit
fi

echo
echo "=== EXPORTED ==="
