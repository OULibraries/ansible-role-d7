#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [  -z "$1" ]
then
    echo "Usage: d7_snapshot.sh \$SITEPATH"
    exit 1;
fi
SITEPATH=$1
SITE=$(basename "$SITEPATH")
SNAPSHOTDIR="$SITEPATH/snapshots"
DOW=$( date +%a)


# Make a backup in case the latest one is old
d7_dump.sh $SITEPATH

# Tar files required to rebuild 
sudo -u apache mkdir -p "$SNAPSHOTDIR"
sudo -u apache tar -cvf "$SNAPSHOTDIR/$SITE.$DOW.tar" -C "${SITEPATH}" "./etc" "./db" "./default/files"
