#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [  -z "$1" ] || [ -z "$2" ]; then
    cat <<USAGE
d7_synch.sh syncs content files and database from a remote site to a
local Drupal site, creating it if it doesn't exist.

Usage: d7_sync.sh \$SITEPATH \$SRCHOST [\$ORIGIN_SITEPATH]
    
\$SITEPATH         local target of the sync
\$SRCHOST          host from which to sync  
\$ORIGIN_SITEPATH  optional argument, path to sync on the remote host. 
                   \$SITEPATH will be used if a different $ORIGIN_SITEPATH 
                   is not specified. 
USAGE

  exit 1;
fi

SITEPATH=$1
SRCHOST=$2
if [ ! -z "$3" ]; then
    ORIGIN_SITEPATH=$3 
else
    ORIGIN_SITEPATH=$SITEPATH
fi

echo "Syncing local path ${SITEPATH} from ${SRCHOST} path ${ORIGIN_SITEPATH}"

## Grab the basename of the NEW site to use in a few places.
SITE=$(basename "$SITEPATH")
ORIGIN_SITE=$(basename "$ORIGIN_SITEPATH")

## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    d7_init.sh "$SITEPATH" || exit 1;
fi

## Can't sync a nonexisting remote site
if ssh -A d7.dev.web.ec2.internal [[ ! -e "${ORIGIN_SITEPATH}" ]] ; then 
    echo "Can't find remote site at ${ORIGIN_SITEPATH}."
    exit 1
fi

## Drupal default site dir is ~ 6770
d7_perms.sh --sticky "$SITEPATH/default"

## Make the sync directory
sudo -u apache mkdir -p "$SITEPATH/default/files_sync"
echo "Setting permissions for synced files."
d7_perms.sh --sticky "$SITEPATH/default/files_sync"

## Sync Files to writable directory (sudo would break ssh)
RSOPTS="--verbose --recursive --links  --compress"
rsync  $RSOPTS  "$SRCHOST:$ORIGIN_SITEPATH/default/files/" "$SITEPATH/default/files_sync" | while read $RSFILE; do printf "."; done; 
echo "Files synced."

## Set perms for sync directory
echo "Setting permissions for synced files."
d7_perms.sh --sticky "$SITEPATH/default/files_sync"

## Now that everything is ready, swap in the synced files
## /srv/libraries1/default isn't supposed to be writeable, so we need
## to do some things as root.
echo "Placing synced files."
sudo -u apache rm -rf "$SITEPATH/default/files_bak"
sudo -u apache mv -v "$SITEPATH/default/files" "$SITEPATH/default/files_bak"
sudo -u apache mv -v "$SITEPATH/default/files_sync" "$SITEPATH/default/files"

## Perform sql-dump on source host
echo "Dumping database for ${ORIGIN_SITEPATH} at ${SRCHOST}"
ssh -A "$SRCHOST" drush -r "$ORIGIN_SITEPATH/drupal" sql-dump --result-file="$ORIGIN_SITEPATH/db/drupal_${ORIGIN_SITE}_sync.sql"

## Sync sql-dump to localhost and import
rsync --omit-dir-times "$SRCHOST:$ORIGIN_SITEPATH/db/drupal_${ORIGIN_SITE}_sync.sql" "$SITEPATH/db/"
d7_importdb.sh "$SITEPATH" "$SITEPATH/db/drupal_${ORIGIN_SITE}_sync.sql" || exit 1;

echo "Site synched!"
