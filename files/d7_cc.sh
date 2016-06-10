#!/usr/bin/env bash
## Clear Drupal and APC caches
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

## Clear the caches
curl --basic --user "${APC_USER}:${APC_PASS}" "http://localhost/apc.php?SCOPE=A&SORT1=H&SORT2=D&COUNT=20&CC=1&OB=1" >/dev/null
sudo -u apache drush -y cc all -r "$SITEPATH/drupal" || exit 1;
