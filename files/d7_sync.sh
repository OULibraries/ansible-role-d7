#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

# Writable dir on both local and souce hosts
TEMPDIR=/var/local/backups/drupal/temp

## Require arguments
if [ ! -z "$1" ] && [ ! -z "$2" ]
then
  SITEPATH=$1
  SRCHOST=$2
  echo "Syncing $SITEPATH content from $SRCHOST"
else
  echo "Requires site path (eg. /srv/sample) and source host as argument"
  exit 1;
fi

## Grab the basename of the site to use in a few places.
SITE=`basename $SITEPATH`

## Make the sync directory
sudo mkdir -p $SITEPATH/default/files_sync
sudo chmod 777 $SITEPATH/default/files_sync

## Sync Files to sync directory
rsync -a --ignore-times --omit-dir-times --no-perms $SRCHOST:$SITEPATH/default/files/ $SITEPATH/default/files_sync || exit 1;
echo "Files synced."

## Set perms for sync directory
sudo find $SITEPATH/default/files_sync -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find $SITEPATH/default/files_sync -type f -exec chmod u=rw,g=r,o= '{}' \;
sudo chown -R apache:apache $SITEPATH/default/files_sync


## Perform sql-dump on source host
ssh -A $SRCHOST drush -r $SITEPATH/drupal sql-dump --result-file=$TEMPDIR/drupal_$SITE.sql

## Sync sql-dump
rsync --omit-dir-times $SRCHOST:$TEMPDIR/drupal_$SITE.sql $TEMPDIR/

## Load sql-dump to local DB
sudo -u apache drush sql-cli -r $SITEPATH/drupal < $TEMPDIR/drupal_$SITE.sql || exit 1;

## Cleanup sql-dumps
ssh -A $SRCHOST rm $TEMPDIR/drupal_$SITE.sql
rm $TEMPDIR/drupal_$SITE.sql
echo "Database synced."

## Enable update manager.
sudo -u apache drush -y en update -r $SITEPATH/drupal || exit 1;

## Apply security updates.
sudo -u apache drush up -y --security-only -r $SITEPATH/drupal || exit 1;

## Disable update manager; no need to leave it phoning home.
sudo -u apache drush -y dis update -r $SITEPATH/drupal || exit 1;

## Clear the caches
sudo -u apache drush -y cc all -r $SITEPATH/drupal || exit 1;

## Avoid a known performance-crusher in our environment
sudo -u apache drush eval 'variable_set('drupal_http_request_fails', 0)' -r $SITEPATH/drupal || exit 1;
