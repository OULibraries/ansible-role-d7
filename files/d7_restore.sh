#!/usr/bin/env bash
## Deploy drupal site from drush make

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [  -z "$1" ]; then
    cat <<USAGE
d7_restore.sh restores an existing site snapshot backup.

Usage: d7_restore.sh \$SITEPATH \$DOW

\$SITEPATH   path to Drupal site to restore
\$DOW        lowercase day-of-week abbreviation indicating backup 
             to restore. Must be one of sun, mon, tue, wed, thu, fri, or sat.
USAGE

    exit 1;
fi

SITEPATH=$1
DOW=$2
SITE=$(basename "$SITEPATH")

if [ ! -d "$SITEPATH" ]; then
  echo "${SITEPATH} doesn't exist, nothing to restore."
  exit 0
fi

if [ -z "${DOW}" ]; then
  echo "No snapshot specified."
  echo "The following snapshots exist:"

  # If we don't have a target s3 bucket, use the local filesystem.
  if [ -z "${D7_S3_SNAPSHOT_DIR}" ]; then
    ls "${SITEPATH}/snapshots/"
  # Otherwise use aws s3. Trailing slash required.
  else
    aws s3 ls "${D7_S3_SNAPSHOT_DIR}/"
  fi

  exit 0
fi

# If we don't have a target s3 bucket, use the local filesystem.
if [ -z "${D7_S3_SNAPSHOT_DIR}" ]; then
  SNAPSHOTFILE="${SITEPATH}/snapshots/${SITE}.${D7_HOST_SUFFIX}.${DOW}.tar.gz"

  # Verify the file is there
  if [ ! -f "$SNAPSHOTFILE" ]; then
    echo "No snapshot at ${SNAPSHOTFILE}"
    exit 0
  fi

# Otherwise use aws s3
else
  SNAPSHOTFILE="${D7_S3_SNAPSHOT_DIR}/${SITE}.${D7_HOST_SUFFIX}.${DOW}.tar.gz"
fi

echo "Restoring ${DOW} snapshot of ${SITEPATH}."

# If we don't have a target s3 bucket, use the local filesystem.
if [ -z "${D7_S3_SNAPSHOT_DIR}" ]; then

# Tarballs include the $SITE folder, so we need to strip that off
    # when extracting
    sudo -u apache tar -xvzf  "${SNAPSHOTFILE}" -C "${SITEPATH}" --strip-components=1 --no-overwrite-dir
# Otherwise use aws s3
else

    # Tarballs include the $SITE folder, so we need to strip that off
    # when extracting
    sudo -u apache bash -c "aws s3 cp '${SNAPSHOTFILE}' - | tar -xvzf - -C '${SITEPATH}' --strip-components=1 --no-overwrite-dir" || exit 1;
fi


echo "Files from snapshot restored." 
echo "Now run d7_importdb.sh ${SITEPATH} to restore the db for the site."
