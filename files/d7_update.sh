#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Processing $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Dump DB before touching anything
sudo d7_dump.sh "$SITEPATH" || exit 1;

## Enable update manager.
sudo -u apache drush -y en update -r "$SITEPATH/drupal" || exit 1;

## Apply security updates.
sudo -u apache drush up -y --security-only -r "$SITEPATH/drupal"  --backup-dir="$SITEPATH/drush-backups/" || exit 1;

## Disable update manager; no need to leave it phoning home.
sudo -u apache drush -y dis update -r "$SITEPATH/drupal" || exit 1;

## Clear the caches
sudo -u apache drush -y cc all -r "$SITEPATH/drupal" || exit 1;

## Avoid a known performance-crusher in our environment
sudo -u apache drush eval 'variable_set('drupal_http_request_fails', 0)' -r "$SITEPATH/drupal" || exit 1;
