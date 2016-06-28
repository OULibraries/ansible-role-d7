#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_importdb.sh imports a Drupal database file. 

Usage: d7_importdb.sh.sh \$SITEPATH [\$DBFILE]
            
\$SITEPATH  Drupal site path
\$DBFILE    Drupal database file to load

If \$DBFILE is not given, then \$SITEPATH/db/drupal_\$SITE_dump.sql will be used.
USAGE

  exit 1;
fi

SITEPATH=$1
echo "Processing $SITEPATH"

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

if [[ ! -f $DBFILE ]]; then
    echo "No file exists at ${DBFILE}."
    exit 1;
fi

if drush sqlq -r "$SITEPATH/drupal"
then
    echo "Target DB exists. "
else
    echo "Target DB doesn't exist, we need to create it. "

    # Get mysql host 
    read -r -e -p "Enter MYSQL host name: " -i "$D7_DBHOST" MY_DBHOST
    # Get mysql port
    read -r -e -p "Enter MYSQL host port: " -i "$D7_DBPORT" MY_DBPORT

    # Get DB admin user
    read -r -e -p "Enter MYSQL admin user: " -i "$D7_DBSU" MY_DBSU
    # Get DB admin password
    read -r -s -p "Enter MYSQL root password: " MY_DBSU_PASS
    while  [ -z "$MY_DBSU_PASS" ] || ! mysql --host="$MY_DBHOST" --port="$MY_DBPORT" --user="$MY_DBSU" --password="$MY_DBSU_PASS"  -e ";" ; do
        read -r -s -p "Can't connect, please retry: " MY_DBSU_PASS
    done
    
    ## Create the Drupal database
    sudo -u apache drush -y sql-create --db-url="mysql://${MY_DBSU}:${MY_DBSU_PASS}@${MY_DBHOST}:${MY_DBPORT}/drupal_${SITE}_${ENV_NAME}" -r "$SITEPATH/drupal" || exit 1;
fi

## Load sql-dump to local DB
echo "Importing database for $SITE from file at $DBFILE."
sudo -u apache drush sql-cli -r "$SITEPATH/drupal" < "${DBFILE}" || exit 1;
echo "Database imported."


## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;
