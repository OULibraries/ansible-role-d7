#!/usr/bin/env bash
## Clean out an existing Drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7-conf.sh

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
  echo "DROP DATABASE \`drupal_${SITE}_${D7_ENV_NAME}\`" | sudo -u apache drush sql-cli -r "$SITEPATH/drupal"

  ## Remove apache config
  echo "Deleting apache config."
  sudo rm "/etc/httpd/conf.d/srv_$SITE.conf"

  ## Change 444 files to 644
  sudo chmod 644 "$SITEPATH/default/settings.php"
  sudo chmod 644 "$SITEPATH/default/files/.htaccess"

  ## Remove the content
  echo "Deleting site files."
  sudo -u apache rm -rf "$SITEPATH"

  sudo systemctl restart httpd
fi
