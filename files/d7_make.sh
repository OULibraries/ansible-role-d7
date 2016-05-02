#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Don't edit below here.

# Require arguments
if [ -z "$1" ]; then
    echo "Usage: d7_make.sh $SITEPATH [$MAKEURI]"
    echo "If option $MAKEURI argument is not specified, a cached Makefile will be used"
    exit 1;
fi

SITEPATH=$1
MY_MAKEFILE="$SITEPATH/etc/site.make"

if [  -z "$2" ]; then 
    MAKEURI="file://${MY_MAKEFILE}"
else
    MAKEURI="$2"
fi

echo "Making $SITEPATH based on $MAKEURI"


    
## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    d7_init.sh "$SITEPATH" || exit 1;
fi

## Dump DB before touching anything
d7_dump.sh "$SITEPATH" || exit 1;

## Delete build dir if it's there
sudo -u apache rm -rf "$SITEPATH/drupal_build"

# Make sure etc exists
sudo -u apache mkdir -p "$SITEPATH/etc"

# Backup the file we might be overwriting 
[ -f $MY_MAKEFILE ] && cp -v "$MY_MAKEFILE" "${MY_MAKEFILE}.bak"

# Download makefile if it isn't the one we already have
if [ ! MAKEURI == "file://${MY_MAKEFILE}" ]; then
    echo "$MAKEURI" > $SITEPATH/etc/site.make.uri
    (cd "$SITEPATH/etc" &&  curl "$MAKEURI"  -o "$MY_MAKEFILE")
fi

## Build from drush make or die
sudo -u apache drush -y --working-copy make "${MAKEURI}" "$SITEPATH/drupal_build" || exit 1;


## Delete default site in the build
sudo -u apache rm -rf "$SITEPATH/drupal_build/sites/default"

## Set perms
echo "Setting permissions of the new build."
sudo find "$SITEPATH/drupal_build" -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find "$SITEPATH/drupal_build" -type f -exec chmod u=rw,g=r,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy of the new build."
sudo semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/drupal_build(/.*)?" || exit 1;
sudo restorecon -R "$SITEPATH/drupal_build" || exit 1;

## Set perms
echo "Setting permissions of default site."
sudo find "$SITEPATH/default" -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo find "$SITEPATH/default" -type f -exec chmod u=rw,g=r,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy of the default site."
sudo semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/default(/.*)?" || exit 1;
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/default/files(/.*)?" || exit 1
sudo restorecon -R "$SITEPATH/default" || exit 1;

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into new build."
sudo -u apache ln -s "$SITEPATH/default" "$SITEPATH/drupal_build/sites/default"

## Now that everything is ready, do the swap
echo "Placing new build."
sudo -u apache rm -rf "$SITEPATH/drupal_bak"
sudo -u apache mv "$SITEPATH/drupal" "$SITEPATH/drupal_bak"
sudo -u apache mv "$SITEPATH/drupal_build" "$SITEPATH/drupal"

## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;
