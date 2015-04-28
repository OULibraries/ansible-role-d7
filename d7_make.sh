#!/bin/sh
## Deploy drupal site from drush make
PATH=/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Unix owner and group of site path
SITESOWNER=apache:apache

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

SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi

## Delete build dir if it's there
rm -rf $SITEPATH/drupal_build

## Build from drush make or die
drush -y --working-copy make $MAKEFILE $SITEPATH/drupal_build || exit 1;

## Delete default site in the build
rm -rf $SITEPATH/drupal_build/sites/default

## Set perms- allows group write
echo "Setting permissions of the new build."
$SUDO find $SITEPATH/drupal_build -type d -exec chmod u=rwx,g=rwx,o= '{}' \;
$SUDO find $SITEPATH/drupal_build -type f -exec chmod u=rw,g=rw,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy of the new build."
$SUDO semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/drupal_build(/.*)?" || exit 1;
$SUDO restorecon -R $SITEPATH/drupal_build || exit 1;

# Set owner
echo "Changing owner of the new build."
$SUDO chown -R $SITESOWNER $SITEPATH/drupal_build

## Set perms- allows group write
echo "Setting permissions of default site."
$SUDO find $SITEPATH/default -type d -exec chmod u=rwx,g=rwx,o= '{}' \;
$SUDO find $SITEPATH/default -type f -exec chmod u=rw,g=rw,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy of the default site."
$SUDO semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/default(/.*)?" || exit 1;
$SUDO restorecon -R $SITEPATH/default || exit 1;

# Set owner
echo "Changing owner of the default site."
$SUDO chown -R $SITESOWNER $SITEPATH/default

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into new build."
ln -s $SITEPATH/default $SITEPATH/drupal_build/sites/default
$SUDO chown $SITESOWNER $SITEPATH/drupal_build/sites/default

## Now that everything is ready, do the swap
echo "Placing new build."
$SUDO rm -rf $SITEPATH/drupal_bak
mv $SITEPATH/drupal $SITEPATH/drupal_bak
mv $SITEPATH/drupal_build $SITEPATH/drupal

## Apply security updates
$SUDO drush up -y --security-only -r $SITEPATH/drupal || exit 1;
## Clear the caches
drush -y cc all -r $SITEPATH/drupal || exit 1;

## Avoid a known performance-crusher in our environment
drush eval 'variable_set('drupal_http_request_fails', 0)' -r $SITEPATH/drupal || exit 1;
