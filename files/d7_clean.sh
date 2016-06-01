#!/usr/bin/env bash
## Clean out an existing Drupal site
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

## Grab the basename of the site to use in a few places.
SITE=$(basename "$SITEPATH")


read -p "You would cry if you did this on accident. Are you sure? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
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
fi
