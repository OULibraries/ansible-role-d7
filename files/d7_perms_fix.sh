#!/usr/bin/env bash
## Fix perms of drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Processing $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Set perms
d7_perms_no_sticky.sh "$SITEPATH/drupal"
d7_perms_no_sticky.sh "$SITEPATH/drupal_bak"
d7_perms_sticky.sh "$SITEPATH/db"
d7_perms_sticky.sh "$SITEPATH/etc"
d7_perms_sticky.sh "$SITEPATH/default"

sudo -u apache chmod 444 "$SITEPATH/default/settings.php"
