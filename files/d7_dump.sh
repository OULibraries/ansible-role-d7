#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

# Writable dir on both local and souce hosts
TEMPDIR=/var/local/backups/drupal/temp

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Dumping $SITEPATH database"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    sudo d7_init.sh $SITEPATH || exit 1;
fi

## Grab the basename of the site to use in a few places.
SITE=`basename $SITEPATH`

## Make the database dump directory
sudo -u apache mkdir -p $SITEPATH/db

## Perform sql-dump
sudo -u apache drush -r $SITEPATH/drupal sql-dump --result-file=$SITEPATH/db/drupal_$SITE.sql
