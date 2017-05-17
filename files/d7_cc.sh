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


sudo systemctl reload rh-php56-php-fpm &&  echo "Reloaded PHP-FPM to clear OpCache for all sites." || exit 1

sudo -u apache drush -y cc all -r "$SITEPATH/drupal" && echo "Cleared Drupal caches for ${SITEPATH}." || exit 1
