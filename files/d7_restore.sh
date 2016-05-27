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
DOW=$2
SITE=$(basename "$SITEPATH")
SNAPSHOTFILE="${SITEPATH}/snapshots/${SITE}.${DOW}.tar"

# extract files for site from snapshot
sudo -u apache tar -xvf "${SNAPSHOTFILE}" -C "${SITEPATH}"
