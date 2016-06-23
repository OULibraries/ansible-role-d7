#!/usr/bin/env bash
## Clear Drupal and APC caches
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_cc.sh clears all drupal caches for a site and the local apc cache.

Usage: d7_cc.sh \$SITEPATH
            
\$SITEPATH  Drupal site whose cache to clear (eg. /srv/example).
USAGE

  exit 1;
fi

SITEPATH=$1

echo "Clearing cache for ${SITEPATH}."

# clear APC cache
curl --basic --user "${APC_USER}:${APC_PASS}" "http://localhost/apc.php?SCOPE=A&SORT1=H&SORT2=D&COUNT=20&CC=1&OB=1" >/dev/null
# clear Drupal cache
sudo -u apache drush -y cc all -r "$SITEPATH/drupal" || exit 1;

echo
echo "Cache cleared!"
echo
