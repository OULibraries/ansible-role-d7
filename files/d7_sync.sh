#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

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
echo "Setting permissions for synced files."
sudo find $SITEPATH/default/files_sync -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find $SITEPATH/default/files_sync -type f -exec chmod u=rw,g=r,o= '{}' \;
sudo chown -R apache:apache $SITEPATH/default/files_sync
echo "Setting SELinux for synced files."
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/default/files_sync(/.*)?" || exit 1
sudo restorecon -R $SITEPATH/default || exit 1;

## Now that everything is ready, swap in the synced files
echo "Placing synced files."
sudo rm -rf $SITEPATH/default/files_bak
mv $SITEPATH/default/files $SITEPATH/default/files_bak
mv $SITEPATH/default/files_sync $SITEPATH/default/files

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

## Apply security updates and clear caches.
sudo d7_update.sh $SITEPATH || exit 1;
