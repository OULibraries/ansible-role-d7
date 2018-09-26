#!/usr/bin/env bash
## Deploy drupal site from drush make

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
    cat <<USAGE
d7_update.sh applies security (only) updates to a drupal site.

Usage: d7_update.sh \$SITEPATH

\$SITEPATH   Drupal site to update.
USAGE

  exit 1;
fi

SITEPATH=$1

echo "Processing $SITEPATH"


# Check for available updates
UPDATELIST=$(drush -r "${SITEPATH}/drupal" pm-updatestatus --security-only --pipe)
if [ "" == "${UPDATELIST}" ] ; then
    echo "No security updates available"
    exit 0
fi


## dump DB before touching anything
d7_dump.sh "$SITEPATH" || exit 1;

## Enable update manager.
sudo -u apache drush -y en update -r "$SITEPATH/drupal" || exit 1;

## Apply security updates.
sudo -u apache drush up -y --security-only -r "$SITEPATH/drupal"  --no-backup  || exit 1;

## Disable update manager; no need to leave it phoning home.
sudo -u apache drush -y dis update -r "$SITEPATH/drupal" || exit 1;

## Make sure any updated php is readable
d7_perms.sh "$SITEPATH/drupal"

## Make sure new code is loaded
## d7_cc.sh "$SITEPATH"

## Avoid a known performance-crusher in our environment
sudo -u apache drush eval 'variable_set('drupal_http_request_fails', 0)' -r "$SITEPATH/drupal" || exit 1;
