#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [  -z "$1" ]
then
    echo "Usage: d7_snapshot.sh \$SITEPATH \$DOW"
    echo "$DOW should be something like Mon, Tue, Web, etc. "
    exit 1;
fi

SITEPATH=$1
DOW=$2
SITE=$(basename "$SITEPATH")
SNAPSHOTFILE="${SITEPATH}/snapshots/${SITE}.${DOW}.tar"

if [ -z "${DOW}" ]; then
    echo "No snapshot specified."
    echo "The following snapshots exist:"
    ls "${SITEPATH}/snapshots/"
    exit 0
fi

if [ ! -f $SNAPSHOTFILE ]; then
    echo "No snapshot at ${SNAPSHOTFILE}"
    exit 0
fi

# Tarballs include the $SITE folder, so we need to strip that off
# whene extracting
sudo -u apache tar -xf "${SNAPSHOTFILE}" -C "${SITEPATH}" --strip-components=1


echo "Files from snapshot restored." 
echo "Now run d7_importdb.sh ${SITEPATH} to restore the db for the site."


