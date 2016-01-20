#!/bin/sh
## Deploy drupal site from drush make
PATH=/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Don't edit below here.
# Require arguments
if [ ! -z "$1" ] && [ ! -z "$2" ]
then
  SITEPATH=$1
  MAKEFILE=$2
  echo "Deploying $MAKEFILE to $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) and makefile as argument"
  exit 1;
fi

## Delete build dir if it's there
sudo -u apache rm -rf $SITEPATH/drupal_build

## Build from drush make or die
sudo -u apache drush -y --working-copy make $MAKEFILE $SITEPATH/drupal_build || exit 1;

## Delete default site in the build
sudo -u apache rm -rf $SITEPATH/drupal_build/sites/default

## Set perms
echo "Setting permissions of the new build."
sudo find $SITEPATH/drupal_build -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find $SITEPATH/drupal_build -type f -exec chmod u=rw,g=r,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy of the new build."
sudo semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/drupal_build(/.*)?" || exit 1;
sudo restorecon -R $SITEPATH/drupal_build || exit 1;

## Set perms
echo "Setting permissions of default site."
sudo find $SITEPATH/default -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find $SITEPATH/default -type f -exec chmod u=rw,g=r,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy of the default site."
sudo semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/default(/.*)?" || exit 1;
sudo restorecon -R $SITEPATH/default || exit 1;

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into new build."
sudo -u apache ln -s $SITEPATH/default $SITEPATH/drupal_build/sites/default

## Now that everything is ready, do the swap
echo "Placing new build."
sudo rm -rf $SITEPATH/drupal_bak
mv $SITEPATH/drupal $SITEPATH/drupal_bak
mv $SITEPATH/drupal_build $SITEPATH/drupal

## Enable update manager.
sudo -u apache drush -y en update -r $SITEPATH/drupal || exit 1;

## Apply security updates.
sudo -u apache drush up -y --security-only -r $SITEPATH/drupal || exit 1;

## Disable update manager; no need to leave it phoning home.
sudo -u apache drush -y dis update -r $SITEPATH/drupal || exit 1;

## Clear the caches
sudo -u apache drush -y cc all -r $SITEPATH/drupal || exit 1;

## Avoid a known performance-crusher in our environment
sudo -u apache drush eval 'variable_set('drupal_http_request_fails', 0)' -r $SITEPATH/drupal || exit 1;
