#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [  -z "$1" ]
then
   echo "Requires site path (eg. /srv/sample)."
   exit 1;
fi
SITEPATH=$1

if [[ ! -e $SITEPATH ]]; then
    echo "No site exists at ${SITEPATH}."
    exit 1;
fi

## Grab the basename of the NEW site to use in a few places.
SITE=$(basename "$SITEPATH")

if [[ ! -z "$2" ]]
then
    DBFILE=$2
else
    DBFILE="${SITEPATH}/db/drupal_${SITE}_dump.sql"
fi       

if drush sqlq -r "$SITEPATH/drupal"
then
    echo "Target DB exists. "
else
    echo "Target DB doesn't exist, we need to create it. "

    # Get root DB password
    read -r -s -p "Enter MYSQL root password: " ROOTDBPSSWD
    while ! mysql -u root -p"$ROOTDBPSSWD"  -e ";" ; do
	read -r -s -p "Can't connect. Re-enter password to try again: " ROOTDBPSSWD
    done
    
    ## Create the Drupal database
    sudo -u apache drush -y sql-create --db-su=root --db-su-pw="$ROOTDBPSSWD" -r "$SITEPATH/drupal" || exit 1;
fi

## Load sql-dump to local DB
echo "Importing database for $SITE from file at $DBFILE."
sudo -u apache drush sql-cli -r "$SITEPATH/drupal" < "${DBFILE}" || exit 1;
echo "Database imported."
echo

## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;
