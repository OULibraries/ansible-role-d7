#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7-conf.sh

## Require arguments
if [ ! -z "$1" ] && [ ! -z "$2" ] && [ ! -z "$3" ]
then
  ORIGIN_SITEPATH=$1
  SRCHOST=$2
  SITEPATH=$3
  echo "Syncing $ORIGIN_SITEPATH content from $SRCHOST to local $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample), source host, and new site path as arguments"
  exit 1;
fi

## Grab the basename of the NEW site to use in a few places.
SITE=`basename $SITEPATH`


## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    sudo d7_init.sh $SITEPATH || exit 1;
fi

## Make the sync directory
sudo mkdir -v  -p "$SITEPATH/default/files_sync"
sudo chmod 777 "$SITEPATH/default/files_sync"

## Sync Files to writable directory (sudo would break ssh)
RSOPTS="--verbose --recursive --links --devices --compress"
rsync  $RSOPTS  "$SRCHOST:$ORIGIN_SITEPATH/default/files/" "$SITEPATH/default/files_sync" ;
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
sudo mv $SITEPATH/default/files $SITEPATH/default/files_bak
sudo mv $SITEPATH/default/files_sync $SITEPATH/default/files

## Perform sql-dump on source host
ssh -A $SRCHOST drush -r $ORIGIN_SITEPATH/drupal sql-dump --result-file=$TEMPDIR/drupal_$SITE.sql

## Sync sql-dump
rsync --omit-dir-times $SRCHOST:$TEMPDIR/drupal_$SITE.sql $TEMPDIR/

## Load sql-dump to local DB
sudo -u apache drush sql-cli -r $SITEPATH/drupal < $TEMPDIR/drupal_$SITE.sql || exit 1;

## Cleanup sql-dumps
if [ "localhost" != "$SRCHOST" ]; then 
    ssh -A $SRCHOST rm $TEMPDIR/drupal_$SITE.sql
fi

rm $TEMPDIR/drupal_$SITE.sql
echo "Database synced."

## Apply security updates and clear caches.
sudo d7_update.sh $SITEPATH || exit 1;
