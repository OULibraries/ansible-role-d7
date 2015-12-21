#!/bin/sh
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

  ## Drop the database
  echo "Dropping database."
  echo "DROP DATABASE \`drupal_$SITE\`" | drush sql-cli -r $SITEPATH/drupal

  ## Remove apache config
  echo "Deleting apache config."
  sudo rm /etc/httpd/conf.d/srv_$SITE.conf

  ## Remove the content
  echo "Deleting site files."
  sudo rm -rf $SITEPATH
fi
