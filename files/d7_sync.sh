#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7-conf.sh

## Require arguments
if [ ! -z "$1" ] && [ ! -z "$2" ] && [ ! -z "$3" ]
then
  SITEPATH=$1
  SRCHOST=$2
  NEWSITEPATH=$3
  echo "Syncing $SITEPATH content from $SRCHOST"
else
  echo "Requires site path (eg. /srv/sample) and source host as argument"
  exit 1;
fi

## Grab the basename of the site to use in a few places.
SITE=`basename $SITEPATH`


## Init site if it doesn't exist
if [[ ! -e $NEWSITEPATH ]]; then
    sudo d7_init.sh $NEWSITEPATH || exit 1;
fi

## Make the sync directory
sudo -u apache mkdir -p $NEWSITEPATH/default/files_sync
sudo -u apache chmod 777 $NEWSITEPATH/default/files_sync

## Sync Files to sync directory
RSOPTS="--verbose --recursive --links --owner --devices --compress"
rsync  $RSOPTS  "$SRCHOST:$SITEPATH/default/files/ $NEWSITEPATH/default/files_sync" || exit 1;
echo "Files synced."

## Set perms for sync directory
echo "Setting permissions for synced files."
sudo find $NEWSITEPATH/default/files_sync -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find $NEWSITEPATH/default/files_sync -type f -exec chmod u=rw,g=r,o= '{}' \;
sudo chown -R apache:apache $NEWSITEPATH/default/files_sync
echo "Setting SELinux for synced files."
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$NEWSITEPATH/default/files_sync(/.*)?" || exit 1
sudo restorecon -R $NEWSITEPATH/default || exit 1;

## Now that everything is ready, swap in the synced files
echo "Placing synced files."
sudo rm -rf $NEWSITEPATH/default/files_bak
sudo mv $NEWSITEPATH/default/files $NEWSITEPATH/default/files_bak
sudo mv $NEWSITEPATH/default/files_sync $NEWSITEPATH/default/files

## Perform sql-dump on source host
ssh -A $SRCHOST drush -r $SITEPATH/drupal sql-dump --result-file=$TEMPDIR/drupal_$SITE.sql

## Sync sql-dump
rsync --omit-dir-times $SRCHOST:$TEMPDIR/drupal_$SITE.sql $TEMPDIR/

## Load sql-dump to local DB
sudo -u apache drush sql-cli -r $NEWSITEPATH/drupal < $TEMPDIR/drupal_$SITE.sql || exit 1;

## Cleanup sql-dumps
if [ "localhost" != "$SRCHOST" ]; then 
    ssh -A $SRCHOST rm $TEMPDIR/drupal_$SITE.sql
fi

rm $TEMPDIR/drupal_$SITE.sql
echo "Database synced."

## Apply security updates and clear caches.
sudo d7_update.sh $NEWSITEPATH || exit 1;
