#!/usr/bin/env bash
## Clean out an existing Drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_clean.sh removes a Drupal site and the database it connects to.

Usage: d7_clean.sh \$SITEPATH
            
\$SITEPATH  Drupal site to remove (eg. /srv/example).
USAGE

  exit 1;
fi

SITEPATH=$1
SITE=$(basename "$SITEPATH")

if [[ ! -e "$SITEPATH" ]] ;then
    echo "Can't find a site to delete at $SITEPATH."
    exit 0
fi

echo "Deleting Drupal stie at $SITEPATH, and the corresponding database."
read -p "You would cry if you did this on accident. Are you sure? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ;then
    echo "Better safe than sorry."
    exit 0
fi


## Get sudo password if needed because first sudo use is behind a pipe.
sudo ls > /dev/null

## Drop the database
echo "Dropping database."
echo "DROP DATABASE \`drupal_${SITE}_${ENV_NAME}\`" | sudo -u apache drush sql-cli -r "$SITEPATH/drupal"

## Change settings.php to 660
sudo -u apache chmod ug=rw,o= "$SITEPATH/default/settings.php" 2>/dev/null || \
    chmod ug=rw,o= "$SITEPATH/default/settings.php"

## Change .htaccess to 660
sudo -u apache chmod ug=rw,o= "$SITEPATH/default/files/.htaccess" 2>/dev/null || \
    chmod ug=rw,o= "$SITEPATH/default/files/.htaccess"

## Remove the content
## /srv/libraries1/default isn't supposed to be writeable, so we need
## to do some things as root
echo "Deleting site files."
sudo -u apache  rm -rf "$SITEPATH"

sudo systemctl restart httpd

