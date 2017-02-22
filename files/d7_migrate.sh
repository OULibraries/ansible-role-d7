#!/usr/bin/env bash
## Sync Drupal files & DB from source host

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then
    cat <<USAGE
d7_migrate.sh migrates a site between hosts.

Usage: d7_migrate.sh \$SITEPATH \$SRCHOST \$ORIGIN_SITEPATH [\$MASTERPATH]

\$SITEPATH          local path for Drupal site (eg. /srv/example).
\$SRCHOST           host of site to migrate
\$ORIGIN_SITEPATH   remote path of site to migrate on \$SRCHOST
\$MASTERPATH        (optional) local path to master site
USAGE
    exit 1;
fi

SITEPATH=$1
MASTERSITE=${SITEPATH}
SITETYPE=master

SRCHOST=$2
ORIGIN_SITEPATH=$3

if [ ! -z "$4" ]; then
    SITETYPE="sub"
    MASTERSITE="$4"
fi

if [  -e "$SITEPATH" ]; then
    echo "A site alreay exists at $SITEPATH, try using sync."
    exit 1;
fi

if [[ ! "$ORIGIN_SITEPATH" == $(ssh "${SRCHOST}" "ls -d  ${ORIGIN_SITEPATH}") ]]; then
    echo "Can't find remote site at ${ORIGIN_SITEPATH} on ${SRCHOST}."
    echo "Verify the hostname and remote site."
    exit 1;
fi

echo "Migrating site to ${SITEPATH} from ${SRCHOST} path ${ORIGIN_SITEPATH}."

# Build an empty site
d7_init.sh "$SITEPATH" "$MASTERSITE" || exit 1

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
