#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

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

## Dump DB before touching anything
d7_dump.sh "$SITEPATH" || exit 1;

## Enable update manager.
sudo -u apache drush -y en update -r "$SITEPATH/drupal" || exit 1;

## Apply security updates.
sudo -u apache drush up -y --security-only -r "$SITEPATH/drupal"  --no-backup  || exit 1;

## Disable update manager; no need to leave it phoning home.
sudo -u apache drush -y dis update -r "$SITEPATH/drupal" || exit 1;

## Clear the caches
d7_cc.sh "$SITEPATH"

## Avoid a known performance-crusher in our environment
sudo -u apache drush eval 'variable_set('drupal_http_request_fails', 0)' -r "$SITEPATH/drupal" || exit 1;

## settings.php is protected.
sudo -u apache chmod ug=r,o= "$SITEPATH/default/settings.php" 2>/dev/null || \
chmod ug=r,o= "$SITEPATH/default/settings.php"
