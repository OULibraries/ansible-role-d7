#!/usr/bin/env bash
## Sync Drupal files & DB from source host

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then 
    cat <<USAGE
d7_migrate.sh migrates a site between hosts.

Usage: d7_migrate.sh \$SITEPATH \$SRCHOST \$ORIGIN_SITEPATH

\$SITEPATH          local Drupal path for new migrated site
\$SRCHOST           host of site to migrate    
\$ORIGIN_SITEPATH   path of site to migrate on \$SRCHOST  
USAGE
    exit 1;
fi

SITEPATH=$1
SRCHOST=$2
ORIGIN_SITEPATH=$3 

if [  -e "$SITEPATH" ]; then
    echo "A site alreay exists at $SITEPATH, try using sync."
    exit 1;
fi

echo "Migrating site to ${SITEPATH} from ${SRCHOST} path ${ORIGIN_SITEPATH}."

# Build an empty site 
d7_init.sh "$SITEPATH"  || exit 1

echo "Copying makefiles!"
for file in "site.make" "site.make.uri" ; do
    ssh "$SRCHOST" "cat $ORIGIN_SITEPATH/etc/${file}" | sudo -u apache tee "$SITEPATH/etc/${file}" >/dev/null
done

# Perms
echo "Setting permissions for config files."
d7_perms.sh --sticky "$SITEPATH/etc"

# Install modules and themes
d7_make.sh "$SITEPATH" || exit 1

# sync files and db
d7_sync.sh "$SITEPATH" "$SRCHOST" "$ORIGIN_SITEPATH" || exit 1

# clear caches
d7_cc.sh "$SITEPATH"  || exit 1

echo "Finished migrating site to ${SITEPATH}."
