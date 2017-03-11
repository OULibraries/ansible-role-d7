#!/usr/bin/env bash
## Run composer for site

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_composer.sh runs composer for a site

Usage: d7_composer.sh \$SITEPATH
            
\$SITEPATH  Drupal site  (eg. /srv/example).

USAGE

  exit 1;
fi

SITEPATH=$1
if [[ ! -e "$SITEPATH" ]] ;then
    echo "Can't find site at $SITEPATH."
    exit 0
fi



echo "Verify vendor folder for ${SITEPATH}"
mkdir -p "${SITEPATH}/vendor" || exit 0

echo "Verify composer manger installation"

if [[ ! -d "$SITEPATH/drupal/sites/all/modules/composer_manager" ]] ;then
    echo "Composer manger not installed as expected"
    exit 0
fi

drush -r "${SITEPATH}/drupal" composer-json-rebuild

(cd "${SITEPATH}/etc" && /opt/php/bin/composer.phar install)


d7_perms.sh "$SITEPATH/vendor"
