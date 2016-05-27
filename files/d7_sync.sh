#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ ! -z "$1" ] && [ ! -z "$2" ]
then
  SITEPATH=$1
  SRCHOST=$2

  if [ ! -z "$3" ]; then
      ORIGIN_SITEPATH=$3 
  else
      ORIGIN_SITEPATH=$SITEPATH
  fi

  echo "Syncing to local path $SITEPATH from $SRCHOST path $ORIGIN_SITEPATH"
else
    echo "Usage: d7_sync.sh \$SITEPATH \$SRCHOST [\$ORIGIN_SITEPATH]"
    echo "\$ORIGIN_SITEPATH is optional if it matches the local \$SITEPATH"
  exit 1;
fi

## Grab the basename of the NEW site to use in a few places.
SITE=$(basename "$SITEPATH")
ORIGIN_SITE=$(basename "$ORIGIN_SITEPATH")

## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    d7_init.sh "$SITEPATH" || exit 1;
fi

## Make the sync directory
sudo -u apache mkdir -p "$SITEPATH/default/files_sync"
echo "Setting permissions for synced files."
d7_perms_sticky.sh "$SITEPATH/default/files_sync" || exit 1;

## Sync Files to writable directory (sudo would break ssh)
RSOPTS="--verbose --recursive --links  --compress"
rsync  $RSOPTS  "$SRCHOST:$ORIGIN_SITEPATH/default/files/" "$SITEPATH/default/files_sync" ;
echo "Files synced."

## Set perms for sync directory
echo "Setting permissions for synced files."
d7_perms_sticky.sh "$SITEPATH/default/files_sync" || exit 1;

## Now that everything is ready, swap in the synced files
## /srv/libraries1/default isn't supposed to be writeable, so we need
## to do some things as root.
echo "Placing synced files."
sudo -u apache rm -rf "$SITEPATH/default/files_bak"
sudo -u apache mv "$SITEPATH/default/files" "$SITEPATH/default/files_bak"
sudo -u apache mv "$SITEPATH/default/files_sync" "$SITEPATH/default/files"
echo
echo

## Perform sql-dump on source host
echo "Dumping database for ${ORIGIN_SITEPATH} at ${SRCHOST}"
ssh -A "$SRCHOST" drush -r "$ORIGIN_SITEPATH/drupal" sql-dump --result-file="$ORIGIN_SITEPATH/db/drupal_${ORIGIN_SITE}_sync.sql"

## Sync sql-dump to localhost and import
rsync --omit-dir-times "$SRCHOST:$ORIGIN_SITEPATH/db/drupal_${ORIGIN_SITE}_sync.sql" "$SITEPATH/db/"
d7_importdb.sh "$SITEPATH" "$SITEPATH/db/drupal_${ORIGIN_SITE}_sync.sql" || exit 1;
