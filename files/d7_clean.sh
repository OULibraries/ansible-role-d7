#!/usr/bin/env bash
## Clean out an existing Drupal site
PATH=/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Processing $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

read -p "You would cry if you did this on accident. Are you sure? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  ## Grab the basename of the site to use in a few places.
  SITE=`basename $SITEPATH`

  ## Get sudo password if needed because first sudo use is behind a pipe.
  sudo ls > /dev/null

  ## Drop the database
  echo "Dropping database."
  echo "DROP DATABASE \`drupal_$SITE\`" | sudo -u apache drush sql-cli -r $SITEPATH/drupal

  ## Remove apache config
  echo "Deleting apache config."
  sudo rm /etc/httpd/conf.d/srv_$SITE.conf

  ## Remove the content
  echo "Deleting site files."
  sudo -u apache rm -rf $SITEPATH

  sudo systemctl restart httpd
fi
