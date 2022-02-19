#!/bin/bash

# Author  : Zhou Jinghui
# Date    : 2014/11/18, 2019/03/04
# Purpose : Restore a MediaWiki site from programs, database, images and resources

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo
    echo "=== USAGE ==="
    echo "This script restores a MediaWiki website from backup programs, database, images and resources:"
    echo "  1) the variables affecting script behavior"
    echo "    RESTORE_TAG       : the tag used in all restore filenames  (CURRENT = '$RESTORE_TAG', DEFAULT = ERROR)"
    echo "    RESTORE_PROGRAMS  : whether to restore MediaWiki programs  (CURRENT = '$RESTORE_PROGRAMS', DEFAULT = 0)"
    echo "    RESTORE_DATABASE  : whether to restore MediaWiki database  (CURRENT = '$RESTORE_DATABASE', DEFAULT = 0)"
    echo "    RESTORE_IMAGES    : whether to restore MediaWiki images    (CURRENT = '$RESTORE_IMAGES', DEFAULT = 0)"
    echo "    RESTORE_RESOURCES : whether to restore MediaWiki resources (CURRENT = '$RESTORE_RESOURCES', DEFAULT = 0)"
    echo "    ENABLE_TRACE      : whether to show verbose information    (CURRENT = '$ENABLE_TRACE', DEFAULT = 0)"
    echo "  2) the variables referenced in script"
    echo "    WIKI_HOME         : the MediaWiki home directory     (CURRENT = '$WIKI_HOME', DEFAULT = '/var/www/wiki')"
    echo "    WIKI_DATA         : the MediaWiki data directory     (CURRENT = '$WIKI_DATA', DEFAULT = '/var/data/wiki')"
    echo "    WIKI_RES_DIR      : the MediaWiki resource directory (CURRENT = '$WIKI_RES_DIR', DEFAULT = '\$WIKI_DATA/resources')"
    echo "    WIKI_DB_HOST      : the MySQL host                   (CURRENT = '$WIKI_DB_HOST', DEFAULT = 'localhost')"
    echo "    WIKI_DB_NAME      : the MySQL db name                (CURRENT = '$WIKI_DB_NAME', DEFAULT = 'wiki')"
    echo "    WIKI_DB_USER      : the MySQL user name              (CURRENT = '$WIKI_DB_USER', DEFAULT = 'wiki')"
    echo "    WIKI_DB_PASS      : the MySQL user password          (CURRENT = '$WIKI_DB_PASS', DEFAULT = ERROR)"
    echo "    WIKI_BACKUP_DIR   : the local backup directory       (CURRENT = '$WIKI_BACKUP_DIR', DEFAULT = '\$WIKI_DATA/backup')"
    echo
    echo "=== EXAMPLE ==="
    echo "$ RESTORE_TAG=20141118 RESTORE_DATABASE=1 RESTORE_IMAGES=1 WIKI_DB_PASS=*** ENABLE_TRACE=1 $0"
    echo
    exit
fi

if [ -z "$RESTORE_TAG" ]; then
    echo "ERROR: Please provide \$RESTORE_TAG first!"
    exit
fi

if [ -z "$WIKI_DB_PASS" ]; then
    echo "ERROR: Please provide \$WIKI_DB_PASS first"
    exit
fi

echo
echo "=== MediaWiki restore started at [$(date '+%Y/%m/%d %H:%M:%S')] ==="

echo
echo "1) Checking running environment ..."

echo "    RESTORE_TAG       = '$RESTORE_TAG'"
echo "    RESTORE_PROGRAMS  = $RESTORE_PROGRAMS"
echo "    RESTORE_DATABASE  = $RESTORE_DATABASE"
echo "    RESTORE_IMAGES    = $RESTORE_IMAGES"
echo "    RESTORE_RESOURCES = $RESTORE_RESOURCES"
echo "    ENABLE_TRACE      = $ENABLE_TRACE"
echo "    --------------------"
echo "    WIKI_HOME         = '$WIKI_HOME'"
echo "    WIKI_DATA         = '$WIKI_DATA'"
echo "    WIKI_RES_DIR      = '$WIKI_RES_DIR'"
echo "    WIKI_DB_HOST      = '$WIKI_DB_HOST'"
echo "    WIKI_DB_NAME      = '$WIKI_DB_NAME'"
echo "    WIKI_DB_USER      = '$WIKI_DB_USER'"
echo "    WIKI_DB_PASS      = '$WIKI_DB_PASS'"
echo "    WIKI_BACKUP_DIR   = '$WIKI_BACKUP_DIR'"

echo
echo "2) Setting running environment ..."

echo "    RESTORE_TAG       => '$RESTORE_TAG'"

if [ -z "$RESTORE_PROGRAMS" ]; then
    RESTORE_PROGRAMS=0
fi
echo "    RESTORE_PROGRAMS  => $RESTORE_PROGRAMS"

if [ -z "$RESTORE_DATABASE" ]; then
    RESTORE_DATABASE=0
fi
echo "    RESTORE_DATABASE  => $RESTORE_DATABASE"

if [ -z "$RESTORE_IMAGES" ]; then
    RESTORE_IMAGES=0
fi
echo "    RESTORE_IMAGES    => $RESTORE_IMAGES"

if [ -z "$RESTORE_RESOURCES" ]; then
    RESTORE_RESOURCES=0
fi
echo "    RESTORE_RESOURCES => $RESTORE_RESOURCES"

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
    WIKI_DB_USER="wiki_user"
fi
echo "    WIKI_DB_USER      => '$WIKI_DB_USER'"

if [ -z "$WIKI_DB_PASS" ]; then
    WIKI_DB_PASS="wiki_user"
fi
echo "    WIKI_DB_PASS      => '$WIKI_DB_PASS'"

if [ -z "$WIKI_BACKUP_DIR" ]; then
    WIKI_BACKUP_DIR="$WIKI_DATA/backup"
    echo "    WIKI_BACKUP_DIR   => '$WIKI_BACKUP_DIR'"
fi

echo
echo "3) Setting MediaWiki service to READONLY temporarily ..."

WIKI_READONLY=$(grep '^\$wgReadOnly\s*=' $WIKI_HOME/LocalSettings.php | wc -l)
if [ $WIKI_READONLY -eq 0 ]; then
    echo '$wgReadOnly = "<span style=\"color:red\">数据恢复进行中，请稍候...</span>";' >> $WIKI_HOME/LocalSettings.php
fi
ERROR=$?
if [ $ERROR -ne 0 ]; then
    echo "ERROR: Failed to set MediaWiki service to READONLY, error = $ERROR"
    exit
fi

echo
echo "4) Checking MediaWiki backup directory and files ..."

if [ ! -d "$WIKI_BACKUP_DIR/$RESTORE_TAG" ]; then
    echo "ERROR: Failed to read MediaWiki backup directory"
    exit
fi
if [ "$RESTORE_PROGRAMS" == "1" ]; then
    if [ ! -f "$WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_programs.$RESTORE_TAG.tgz" ]; then
        echo "ERROR: Failed to read MediaWiki program backup file"
        exit
    fi
fi
if [ "$RESTORE_DATABASE" == "1" ]; then
    if [ ! -f "$WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_database.$RESTORE_TAG.sql.gz" ]; then
        echo "ERROR: Failed to read MediaWiki database backup file"
        exit
    fi
fi
if [ "$RESTORE_IMAGES" == "1" ]; then
    if [ ! -f "$WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_images.$RESTORE_TAG.tgz" ]; then
        echo "ERROR: Failed to read MediaWiki image backup file"
        exit
    fi
fi
if [ "$RESTORE_RESOURCES" == "1" ]; then
    if [ ! -f "$WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_resources.$RESTORE_TAG.tgz" ]; then
        echo "ERROR: Failed to read MediaWiki resource backup file"
        exit
    fi
fi

echo
echo "5) Restoring MediaWiki programs ..."

if [ "$RESTORE_PROGRAMS" == "1" ]; then
    RESTORE_COMMAND="rm -rf $WIKI_HOME/* && tar -C $WIKI_HOME/ -xzf $WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_programs.$RESTORE_TAG.tgz && chown -R apache:apache $WIKI_HOME/"
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $RESTORE_COMMAND"; fi
    sh -c "$RESTORE_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to restore MediaWiki programs, error = $ERROR"
        exit
    fi
else
    echo "    *** IGNORED ***"
fi

echo
echo "6) Restoring MediaWiki database ..."

if [ "$RESTORE_DATABASE" == "1" ]; then
    RESTORE_COMMAND="gunzip < $WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_database.$RESTORE_TAG.sql.gz | mysql --host=$WIKI_DB_HOST --user=$WIKI_DB_USER --password=$WIKI_DB_PASS --database=$WIKI_DB_NAME"
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $RESTORE_COMMAND"; fi
    sh -c "$RESTORE_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to restore MediaWiki database, error = $ERROR"
        exit
    fi
else
    echo "    *** IGNORED ***"
fi

echo
echo "7) Restoring MediaWiki images ..."

if [ "$RESTORE_IMAGES" == "1" ]; then
    RESTORE_COMMAND="rm -rf $WIKI_DATA/images/* && tar -C $WIKI_DATA/images/ -xzf $WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_images.$RESTORE_TAG.tgz && chown -R apache:apache $WIKI_DATA/images/"
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $RESTORE_COMMAND"; fi
    sh -c "$RESTORE_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to restore MediaWiki images, error = $ERROR"
        exit
    fi
else
    echo "    *** IGNORED ***"
fi

echo
echo "8) Restoring MediaWiki resources ..."

if [ "$RESTORE_RESOURCES" == "1" ]; then
    if [ ! -d "$WIKI_RES_DIR" ]; then
        mkdir -p "$WIKI_RES_DIR"
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "ERROR: Failed to create MediaWiki resource directory, error = $ERROR"
            exit
        fi
        echo "    CREATED MediaWiki resource directory: $WIKI_RES_DIR"
    else
        echo "    CHECKED MediaWiki resource directory: $WIKI_RES_DIR"
    fi
    RESTORE_COMMAND="rm -rf $WIKI_RES_DIR/* && tar -C $WIKI_RES_DIR/ -xzf $WIKI_BACKUP_DIR/$RESTORE_TAG/wiki_resources.$RESTORE_TAG.tgz && chown -R apache:apache $WIKI_RES_DIR/"
    if [ "$ENABLE_TRACE" == "1" ]; then echo "    \$ $RESTORE_COMMAND"; fi
    sh -c "$RESTORE_COMMAND"
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
        echo "ERROR: Failed to restore MediaWiki resources, error = $ERROR"
        exit
    fi
else
    echo "    *** IGNORED ***"
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
echo "10) Restarting MediaWiki service ..."

service httpd restart

echo
echo "=== MediaWiki restore completed at [$(date '+%Y/%m/%d %H:%M:%S')] ==="
echo

if [ "$RESTORE_PROGRAMS" != "1" -a "$RESTORE_DATABASE" != "1" -a "$RESTORE_IMAGES" != "1" -a "$RESTORE_RESOURCES" != "1" ]; then
    echo "WARNING: NOTHING restored!"
fi
