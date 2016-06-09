#!/usr/bin/env bash
## Deploy drupal site from drush make
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Don't edit below here.

# Require arguments
if [ -z "$1" ]; then
    echo "Usage: d7_make.sh $SITEPATH [$MAKEURI]"
    echo "If optional \$MAKEURI argument is not specified, a cached Makefile will be used"
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

# Download makefile if it isn't the one we already have
if [ ! MAKEURI == "file://${MY_MAKEFILE}" ]; then

    # Backup old files if we have them
    [ -f $MY_MAKEFILE ] && sudo -u apache cp -v "$MY_MAKEFILE" "${MY_MAKEFILE}.bak"
    [ -f "${MY_MAKEFILE}.uri" ] && sudo -u apache cp -v "$MY_MAKEFILE" "${MY_MAKEFILE}.uri.bak"

    # Get a new copy of the make file
    echo "$MAKEURI"  | sudo -u apache tee  "${MY_MAKEFILE}.uri" > /dev/null
    (cd "$SITEPATH/etc" &&  sudo -u apache curl "$MAKEURI"  -o "$MY_MAKEFILE")
fi

## Build from drush make or die
sudo -u apache drush -y --working-copy make "${MY_MAKEFILE}" "$SITEPATH/drupal_build" || exit 1;

## Delete default site in the build
sudo -u apache rm -rf "$SITEPATH/drupal_build/sites/default"

## Drupal build dir is ~ 750
d7_perms_no_sticky.sh "$SITEPATH/drupal_build"

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into new build."
sudo -u apache ln -s "$SITEPATH/default" "$SITEPATH/drupal_build/sites/default" || exit 1;

## Now that everything is ready, do the swap
echo "Placing new build."
sudo -u apache rm -rf "$SITEPATH/drupal_bak"
sudo -u apache mv "$SITEPATH/drupal" "$SITEPATH/drupal_bak"
sudo -u apache mv "$SITEPATH/drupal_build" "$SITEPATH/drupal"

## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;
