#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh


if [  -z "$1" ]; then
  cat <<USAGE
d7_dump.sh performs a dump of the database for a Drupal site.

Usage: d7_dump.sh \$SITEPATH
            
\$SITEPATH  Drupal site to sql dump (eg. /srv/example).
USAGE

  exit 1;
fi

SITEPATH=$1

echo "Dumping $SITEPATH database"


## Init site if it doesn't exist
if [[ ! -e $SITEPATH ]]; then
    d7_init.sh "$SITEPATH" || exit 1;
fi

## Grab the basename of the site to use in a few places.
SITE=$(basename "$SITEPATH")


## Make the database dump directory
sudo -u apache mkdir -p "$SITEPATH/db"

## Perform sql-dump
sudo -u apache drush -r "$SITEPATH/drupal" sql-dump --result-file="$SITEPATH/db/drupal_${SITE}_dump.sql"

## Set perms
d7_perms.sh --sticky "$SITEPATH/db"

echo "Finished dumping $SITEPATH database."

