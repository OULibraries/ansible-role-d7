#!/usr/bin/env bash
## Clean out an existing Drupal site

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

echo "Preparing to delete Drupal files and database for $SITEPATH."
read -p "You would cry if you did this on accident. Are you sure? " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]] ;then
    echo "Better safe than sorry."
    exit 0
fi

# Add some whitespace to the output because the above read doesn't
echo

## Get sudo password if needed because first sudo use is behind a pipe.
sudo ls > /dev/null

## Get the db name from drush and drop it.
MYDB=$(drush -r "$SITEPATH/drupal" sql-connect | sed 's/.*\-\-database=//; s/ \-\-host=.*//')
echo "Dropping database ${MYDB}."
echo "DROP DATABASE \`${MYDB}\`" | sudo -u apache drush sql-cli -r "$SITEPATH/drupal"

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

echo "Restarting web server."
sudo systemctl restart httpd24-httpd
