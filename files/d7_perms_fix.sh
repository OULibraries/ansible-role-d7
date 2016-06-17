#!/usr/bin/env bash
## Fix perms of drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then

  cat <<USAGE
d7_perm_fix.sh sets our preferred permissions for all Drupal paths in a site folder. 

Usage: d7_perm_fix.sh [--sticky] \$SITEPATH

\$SITEPATH   Site to apply permissions (eg. /srv/example).

USAGE

  exit 1;
fi

SITEPATH=$1
echo "Processing $SITEPATH"


# Strict perms for drupal code in prod
d7_perms.sh "$SITEPATH/drupal"
d7_perms.sh "$SITEPATH/drupal_bak"

# More liberal perms for config and content 
d7_perms.sh --sticky "$SITEPATH/db"
d7_perms.sh --sticky "$SITEPATH/etc"
d7_perms.sh --sticky "$SITEPATH/default"

# Paying specific attention to the file with the passwords 
sudo -u apache chmod 444 "$SITEPATH/default/settings.php"

exit 0
