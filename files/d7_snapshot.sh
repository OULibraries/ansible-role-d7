#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [  -z "$1" ]
then
    echo "Usage: d7_snapshot.sh \$SITEPATH"
    exit 1;
fi
SITEPATH=$1
SITE=$(basename "$SITEPATH")
SNAPSHOTDIR="$SITEPATH/snapshots"
DOW=$( date +%a | awk '{print tolower($0)}')


# Make a db backup in case the latest one is old
d7_dump.sh $SITEPATH

# Make sure we have a place to stick snapshots
sudo -u apache mkdir -p "$SNAPSHOTDIR"

d7_perms.sh "$SNAPSHOTDIR"

# Tar files required to rebuild, with $SITE as TLD inside tarball. 
sudo -u apache tar -cf "$SNAPSHOTDIR/$SITE.$DOW.tar" -C /srv/ "${SITE}/etc" "${SITE}/db" "${SITE}/default/files"

echo "Snapshot created at ${SNAPSHOTDIR}/${SITE}.${DOW}.tar"
