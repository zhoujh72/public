#!/bin/bash

# Author  : Zhou Jinghui
# Date    : 2014/11/18, 2019/03/04
# Purpose : Backup a MediaWiki site completely for programs, database, images and resources(external referenced files)

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo
    echo "=== USAGE ==="
    echo "This script backups all data in a MediaWiki website:"
    echo "  1) the variables affecting script behavior"
    echo "    BACKUP_TAG        : the tag used in all backup filenames  (CURRENT = '$BACKUP_TAG', DEFAULT = \$(date +%Y%m%d_%H%M%S), EXAMPLE = $(date +%Y%m%d_%H%M%S))"
    echo "    BACKUP_PROGRAMS   : whether to backup MediaWiki programs  (CURRENT = '$BACKUP_PROGRAMS', DEFAULT = 1)"
    echo "    BACKUP_DATABASE   : whether to backup MediaWiki database  (CURRENT = '$BACKUP_DATABASE', DEFAULT = 1)"
    echo "    BACKUP_IMAGES     : whether to backup MediaWiki images    (CURRENT = '$BACKUP_IMAGES', DEFAULT = 1)"
    echo "    BACKUP_RESOURCES  : whether to backup MediaWiki resources (CURRENT = '$BACKUP_RESOURCES', DEFAULT = 1)"
    echo "    ENABLE_TRACE      : whether to show verbose information   (CURRENT = '$ENABLE_TRACE', DEFAULT = 0)"
    echo "  2) the variables referenced in script"
    echo "    WIKI_HOME         : the MediaWiki home directory     (CURRENT = '$WIKI_HOME', DEFAULT = '/var/www/wiki')"
    echo "    WIKI_DATA         : the MediaWiki data directory     (CURRENT = '$WIKI_DATA', DEFAULT = '/var/data/wiki')"
    echo "    WIKI_RES_DIR      : the MediaWiki resource directory (CURRENT = '$WIKI_RES_DIR', DEFAULT = '\$WIKI_DATA/resources')"
    echo "    WIKI_DB_HOST      : the MySQL host                   (CURRENT = '$WIKI_DB_HOST', DEFAULT = 'localhost')"
    echo "    WIKI_DB_NAME      : the MySQL db name                (CURRENT = '$WIKI_DB_NAME', DEFAULT = 'wiki')"
    echo "    WIKI_DB_USER      : the MySQL user name              (CURRENT = '$WIKI_DB_USER', DEFAULT = 'wiki')"
    echo "    WIKI_DB_PASS      : the MySQL user password          (CURRENT = '$WIKI_DB_PASS', DEFAULT = ERROR)"
    echo "    LOCAL_BACKUP_DIR  : the local backup directory       (CURRENT = '$LOCAL_BACKUP_DIR', DEFAULT = '\$WIKI_DATA/backup')"
    echo "    REMOTE_BACKUP_URL : the remote backup directory      (CURRENT = '$REMOTE_BACKUP_URL', DEFAULT = '', EXAMPLE = 'sftp://user:pass@host/dir/')"
    echo
    echo "=== EXAMPLE ==="
    echo "$ BACKUP_TAG=20141118 BACKUP_PROGRAMS=0 BACKUP_RESOURCES=0 WIKI_DB_PASS=*** ENABLE_TRACE=1 $0"
    echo
    exit
fi

if [ -z "$WIKI_DB_PASS" ]; then
    echo "ERROR: Please provide \$WIKI_DB_PASS first!"
    exit
fi

if [ -n "$REMOTE_BACKUP_URL" ]; then
    MATCH_URL=$(echo "$REMOTE_BACKUP_URL" | egrep "(ftp|sftp|http|https|scp):\/\/(.+):(.+)@([^/]+)\/([^\/]+\/)*")
    if [ -z "$MATCH_URL" ]; then
        echo "ERROR: Please provide legal \$REMOTE_BACKUP_URL as '{ftp|sftp|http|https|scp}://user:pass@host/dir/' (NOTE: special characters should be encoded first, e.g. @ => %40)"
        exit
    fi
fi

echo
echo "=== MediaWiki backup started at [$(date '+%Y/%m/%d %H:%M:%S')] ==="

echo
echo "1) Checking running environment ..."

echo "    BACKUP_TAG        = '$BACKUP_TAG'"
echo "    BACKUP_PROGRAMS   = $BACKUP_PROGRAMS"
echo "    BACKUP_DATABASE   = $BACKUP_DATABASE"
echo "    BACKUP_IMAGES     = $BACKUP_IMAGES"
echo "    BACKUP_RESOURCES  = $BACKUP_RESOURCES"
echo "    ENABLE_TRACE      = $ENABLE_TRACE"
echo "    --------------------"
echo "    WIKI_HOME         = '$WIKI_HOME'"
echo "    WIKI_DATA         = '$WIKI_DATA'"
echo "    WIKI_RES_DIR      = '$WIKI_RES_DIR'"
echo "    WIKI_DB_HOST      = '$WIKI_DB_HOST'"
echo "    WIKI_DB_NAME      = '$WIKI_DB_NAME'"
echo "    WIKI_DB_USER      = '$WIKI_DB_USER'"
echo "    WIKI_DB_PASS      = '$WIKI_DB_PASS'"
echo "    LOCAL_BACKUP_DIR  = '$LOCAL_BACKUP_DIR'"
echo "    REMOTE_BACKUP_URL = '$REMOTE_BACKUP_URL'"

echo
echo "2) Setting running environment ..."

if [ -z "$BACKUP_TAG" ]; then
    BACKUP_TAG="$(date +%Y%m%d_%H%M%S)"
fi
echo "    BACKUP_TAG        => '$BACKUP_TAG'"

if [ -z "$BACKUP_PROGRAMS" ]; then
    BACKUP_PROGRAMS=1
fi
echo "    BACKUP_PROGRAMS   => $BACKUP_PROGRAMS"

if [ -z "$BACKUP_DATABASE" ]; then
    BACKUP_DATABASE=1
fi
echo "    BACKUP_DATABASE   => $BACKUP_DATABASE"

if [ -z "$BACKUP_IMAGES" ]; then
    BACKUP_IMAGES=1
fi
echo "    BACKUP_IMAGES     => $BACKUP_IMAGES"

if [ -z "$BACKUP_RESOURCES" ]; then
    BACKUP_RESOURCES=1
fi
echo "    BACKUP_RESOURCES  => $BACKUP_RESOURCES"

if [ -z "$ENABLE_TRACE" ]; then
    ENABLE_TRACE=0
fi
echo "    ENABLE_TRACE      => $ENABLE_TRACE"

echo "    --------------------"

if [ -z "$WIKI_HOME" ]; then
    WIKI_HOME="/var/www/wiki"
fi
echo "    WIKI_HOME         => '$WIKI_HOME'"

if [ -z "$WIKI_DATA" ]; then
    WIKI_DATA="/var/data/wiki"
fi
echo "    WIKI_DATA         => '$WIKI_DATA'"

if [ -z "$WIKI_RES_DIR" ]; then
    WIKI_RES_DIR="$WIKI_DATA/resources"
fi
echo "    WIKI_RES_DIR      => '$WIKI_RES_DIR'"

if [ -z "$WIKI_DB_HOST" ]; then
    WIKI_DB_HOST="localhost"
fi
echo "    WIKI_DB_HOST      => '$WIKI_DB_HOST'"

if [ -z "$WIKI_DB_NAME" ]; then
    WIKI_DB_NAME="wiki"
fi
echo "    WIKI_DB_NAME      => '$WIKI_DB_NAME'"

if [ -z "$WIKI_DB_USER" ]; then
    WIKI_DB_USER="wiki"
fi
echo "    WIKI_DB_USER      => '$WIKI_DB_USER'"

if [ -z "$WIKI_DB_PASS" ]; then
    WIKI_DB_PASS="$WIKI_DB_PASS"
fi
echo "    WIKI_DB_PASS      => '$WIKI_DB_PASS'"

if [ -z "$LOCAL_BACKUP_DIR" ]; then
    LOCAL_BACKUP_DIR="$WIKI_DATA/backup"
fi
echo "    LOCAL_BACKUP_DIR  => '$LOCAL_BACKUP_DIR'"

echo "    REMOTE_BACKUP_URL => '$REMOTE_BACKUP_URL'"

echo
echo "3) Setting MediaWiki service to READONLY temporarily ..."

WIKI_READONLY=$(grep '^\$wgReadOnly\s*=' $WIKI_HOME/LocalSettings.php | wc -l)
if [ $WIKI_READONLY -eq 0 ]; then
    echo '$wgReadOnly = "<span style=\"color:red\">数据备份进行中，请稍候...</span>";' >> $WIKI_HOME/LocalSettings.php
fi
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to set MediaWiki service to READONLY, error = $ERROR"
    exit
fi

echo
echo "4) Preparing MediaWiki backup directory ..."

if [ ! -d "$LOCAL_BACKUP_DIR/$BACKUP_TAG" ]; then
    mkdir -p "$LOCAL_BACKUP_DIR/$BACKUP_TAG"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to create MediaWiki backup directory, error = $ERROR"
        exit
    fi
    echo "    CREATED MediaWiki backup directory: $LOCAL_BACKUP_DIR/$BACKUP_TAG"
else
    echo "    CHECKED MediaWiki backup directory: $LOCAL_BACKUP_DIR/$BACKUP_TAG"
fi

echo
echo "5) Backuping MediaWiki programs ..."

if [ "$BACKUP_PROGRAMS" == "1" ]; then
    BACKUP_COMMAND="tar -C $WIKI_HOME/ -czf $LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_programs.$BACKUP_TAG.tgz ."
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $BACKUP_COMMAND"; fi
    sh -c "$BACKUP_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to backup MediaWiki programs, error = $ERROR"
        exit
    fi
else
   echo "   *** IGNORED ***"
fi

echo
echo "6) Backuping MediaWiki database ..."

if [ "$BACKUP_DATABASE" == "1" ]; then
    BACKUP_COMMAND="mysqldump --host=$WIKI_DB_HOST --user=$WIKI_DB_USER --password=$WIKI_DB_PASS --quote-names --hex-blob $WIKI_DB_NAME 2>mysqldump.error | gzip > $LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_database.$BACKUP_TAG.sql.gz"
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $BACKUP_COMMAND"; fi
    sh -c "$BACKUP_COMMAND"
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to backup MediaWiki database, error = $ERROR"
        exit
    fi
    if [ -s mysqldump.error ]; then
        BACKUP_DATABASE_ERROR=`cat mysqldump.error | fgrep -v '[Warning]' | wc -l`
        if [ $BACKUP_DATABASE_ERROR -gt 0 ]; then
            echo "ERROR: Failed to backup MediaWiki database =>"
            cat mysqldump.error
            exit
        fi
    fi
    rm -f mysqldump.error
else
   echo "   *** IGNORED ***"
fi

echo
echo "7) Backuping MediaWiki images ..."

if [ "$BACKUP_IMAGES" == "1" ]; then
    BACKUP_COMMAND="tar -C $WIKI_DATA/images/ -czf $LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_images.$BACKUP_TAG.tgz ."
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $BACKUP_COMMAND"; fi
    sh -c "$BACKUP_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to backup MediaWiki images, error = $ERROR"
        exit
    fi
else
   echo "   *** IGNORED ***"
fi

echo
echo "8) Backuping MediaWiki resources ..."

if [ "$BACKUP_RESOURCES" == "1" ]; then
    BACKUP_COMMAND="[ ! -d $WIKI_RES_DIR ] || tar -C $WIKI_RES_DIR/ -czf $LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_resources.$BACKUP_TAG.tgz ."
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $BACKUP_COMMAND"; fi
    sh -c "$BACKUP_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to backup MediaWiki resources, error = $ERROR"
        exit
    fi
else
   echo "   *** IGNORED ***"
fi

echo
echo "9) Resetting MediaWiki service to WRITEABLE ..."

sed '/^\$wgReadOnly\s*=/d' $WIKI_HOME/LocalSettings.php > $WIKI_HOME/LocalSettings.php.tmp
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to reset MediaWiki service to WRITEABLE(I), error = $ERROR"
    exit
fi
mv -f $WIKI_HOME/LocalSettings.php.tmp $WIKI_HOME/LocalSettings.php
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to reset MediaWiki service to WRITEABLE(II), error = $ERROR"
    exit
fi
chown apache:apache $WIKI_HOME/LocalSettings.php
chmod 644 $WIKI_HOME/LocalSettings.php

echo
echo "10) Uploading MediaWiki backup files to remote directory ..."

if [ -n "$REMOTE_BACKUP_URL" ]; then
    BACKUP_FILES=""
    if [ "$BACKUP_PROGRAMS"  == "1" ]; then [ -n "$BACKUP_FILES" ] && BACKUP_FILES="$BACKUP_FILES,"; BACKUP_FILES="$BACKUP_FILES$LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_programs.$BACKUP_TAG.tgz";    fi
    if [ "$BACKUP_DATABASE"  == "1" ]; then [ -n "$BACKUP_FILES" ] && BACKUP_FILES="$BACKUP_FILES,"; BACKUP_FILES="$BACKUP_FILES$LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_database.$BACKUP_TAG.sql.gz"; fi
    if [ "$BACKUP_IMAGES"    == "1" ]; then [ -n "$BACKUP_FILES" ] && BACKUP_FILES="$BACKUP_FILES,"; BACKUP_FILES="$BACKUP_FILES$LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_images.$BACKUP_TAG.tgz";      fi
    if [ "$BACKUP_RESOURCES" == "1" ]; then [ -n "$BACKUP_FILES" ] && BACKUP_FILES="$BACKUP_FILES,"; BACKUP_FILES="$BACKUP_FILES$LOCAL_BACKUP_DIR/$BACKUP_TAG/wiki_resources.$BACKUP_TAG.tgz";   fi
    BACKUP_COMMAND="curl -T \"{$BACKUP_FILES}\" $REMOTE_BACKUP_URL"
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $BACKUP_COMMAND"; fi
    sh -c "$BACKUP_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to move MediaWiki backup files to remote directory, error = $ERROR"
        exit
    fi
else
   echo "   *** IGNORED ***"
fi

echo
echo "=== MediaWiki backup completed at [$(date '+%Y/%m/%d %H:%M:%S')] ==="
echo
