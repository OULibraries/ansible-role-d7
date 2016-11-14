#!/usr/bin/env bash
## Clear Drupal and APC caches

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_cc.sh clears all Drupal caches for a site, and clears the localhost apc cache.

Usage: d7_cc.sh \$SITEPATH
            
\$SITEPATH  Drupal site  (eg. /srv/example).
USAGE

  exit 1;
fi

SITEPATH=$1
if [[ ! -e "$SITEPATH" ]] ;then
    echo "Can't find site at $SITEPATH."
    exit 0
fi

curl --silent "http://localhost/apc_clear.php" || exit 1;
echo""
echo "Cleared APC cache"

sudo -u apache drush -y cc all -r "$SITEPATH/drupal" || exit 1;
echo "Cleared Drupal caches for ${SITEPATH}."
