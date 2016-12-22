#!/usr/bin/env bash
## Deploy drupal site from drush make

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_make.sh applies a Drupal makefile to a Drupal site. 

Usage: d7_init.sh \$SITEPATH [$MAKEURI]
            
\$SITEPATH  Drupal site (eg. /srv/example).
\$MAKEFILE  URI of Drupal makefike. Can be a file:// uri.
USAGE

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

# Make sure etc exists and is writeable
sudo -u apache mkdir -p "$SITEPATH/etc"
d7_perms.sh --sticky "$SITEPATH/etc"

# Download makefile if it isn't the one we already have
if [ ! ${MAKEURI} == "file://${MY_MAKEFILE}" ]; then

    # Backup old files if we have them
    [ -f $MY_MAKEFILE ] && sudo -u apache cp -v "$MY_MAKEFILE" "${MY_MAKEFILE}.bak"
    [ -f "${MY_MAKEFILE}.uri" ] && sudo -u apache cp -v "$MY_MAKEFILE" "${MY_MAKEFILE}.uri.bak"

    # Get a new copy of the make file
    echo "$MAKEURI"  | sudo -u apache tee  "${MY_MAKEFILE}.uri" > /dev/null
    (cd "$SITEPATH/etc" &&  sudo -u apache curl "$MAKEURI"  -o "$MY_MAKEFILE")
    d7_perms.sh --sticky "$SITEPATH/etc"
fi

if [[ ! -e "${MY_MAKEFILE}" ]]; then 
    echo "Makefile ${MY_MAKEFILE} does not exist."
    exit 1
fi

## Build from drush make or die
(cd /tmp && sudo -u apache drush -y --working-copy make "${MY_MAKEFILE}" "$SITEPATH/drupal_build" )|| exit 1;
# Drush gets unhappy if it can't chdir back to CWD, and sudo breaks
# that when the script is run from, for example, /home/$user. Starting
# a subshell so we can run from a consistent dir and end up back where
# we started at end of execution.

## Delete default site in the build
sudo -u apache rm -rf "$SITEPATH/drupal_build/sites/default"

## Drupal build dir is ~ 750
d7_perms.sh "$SITEPATH/drupal_build"

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

echo "Finished applying makefile to ${SITEPATH}."
