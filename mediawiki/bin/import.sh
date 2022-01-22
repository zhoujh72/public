#!/bin/bash

# Author  : Zhou Jinghui
# Date    : 2019/03/04
# Purpose : Import a snapshot of the MediaWiki site without any history record

ME=$(basename $0)

if [ $# -ne 1 ]; then
    echo "USAGE: $ME <import_file_tag>"
    exit
fi

echo
echo "1) Importing a snapshot of all wiki pages ..."
COMMAND="php $WIKI_HOME/maintenance/importDump.php $1.xml.gz"
echo "    \$ $COMMAND"
sh -c "$COMMAND"
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to import page snapshot, error = $ERROR"
    exit
fi

echo
echo "2) Importing a snapshot of all wiki images ..."
COMMAND="mkdir -p /tmp/wiki/images/ && tar -C /tmp/wiki/images/ -xzf $1.tar.gz && php $WIKI_HOME/maintenance/importImages.php --search-recursively /tmp/wiki/images/ && chown -R apache:apache $WIKI_HOME/images/ && rm -rf /tmp/wiki/" # NOTE: importImages.php --extensions="ext1,ext2,...(缺省:$wgFileExtensions)"
echo "    \$ $COMMAND"
sh -c "$COMMAND"
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to import image snapshot, error = $ERROR"
    exit
fi

echo
echo "3) Rebuild recent changes ..."
COMMAND="php $WIKI_HOME/maintenance/rebuildrecentchanges.php"
echo "    \$ $COMMAND"
sh -c "$COMMAND"
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to import image snapshot, error = $ERROR"
    exit
fi

echo
echo "NOTE: Please restart httpd service for image display issue"
echo "NOTE: Please restart mysqld service for GraphViz BUG: uncommitted transaction"

echo
echo "=== IMPORTED ==="
