#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ ! -z "$1" ] 
then
    SITEPATH=$1
    echo "Importing SITEPATH content from $DUMP"
else
  echo "Requires site path (eg. /srv/sample)."
  exit 1;
fi

## Grab the basename of the NEW site to use in a few places.
SITE=$(basename "$SITEPATH")

## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    echo "No site exists at ${SITEPATH}."
    exit
fi


## Load sql-dump to local DB
sudo -u apache drush sql-cli -r "$SITEPATH/drupal" < "$SITEPATH/db/drupal_${SITE}_dump.sql" || exit 1;
echo "Database synced."

## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;
