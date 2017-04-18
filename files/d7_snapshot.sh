#!/usr/bin/env bash
## Deploy drupal site from drush make

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
    cat <<USAGE
d7_snapshot.sh creates a db dump and tar GZip backup for a site.

Usage: d7_snapshot.sh \$SITEPATH
            
\$SITEPATH   Drupal site to tar GZip (eg. /srv/example).

Backups will be stored at $SITEPATH/snapshots/$SITE.$DOW.tar.gz. $DOW is
the lowercase day-of-week abbreviation for the current day.

USAGE
    exit 1;
fi

SITEPATH=$1
SITE=$(basename "$SITEPATH")
SNAPSHOTDIR="$SITEPATH/snapshots"
DOW=$( date +%a | awk '{print tolower($0)}')

if [[ ! -e "$SITEPATH" ]]; then 
    echo "Can't create snapshot of nonexistent site at $SITEPATH."
    exit 1;
fi

echo "Making ${DOW} snapshot for $SITEPATH"

# Make a db backup in case the latest one is old
d7_dump.sh $SITEPATH

# Make sure we have a place to stick snapshots
sudo -u apache mkdir -p "$SNAPSHOTDIR"

d7_perms.sh "$SNAPSHOTDIR"

# Tar files required to rebuild, with $SITE as TLD inside tarball. 
sudo -u apache tar -czf "$SNAPSHOTDIR/$SITE.$DOW.tar.gz" -C /srv/ "${SITE}/etc" "${SITE}/db" "${SITE}/default/files"

echo "Snapshot created at ${SNAPSHOTDIR}/${SITE}.${DOW}.tar.gz"
