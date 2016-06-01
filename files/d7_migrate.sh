#!/usr/bin/env bash
## Sync Drupal files & DB from source host
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ ! -z "$1" ] && [ ! -z "$2" ] && [ ! -z "$2" ]
then
  SITEPATH=$1
  SRCHOST=$2
  ORIGIN_SITEPATH=$3 
else
    echo "Usage: d7_migrate.sh \$SITEPATH \$SRCHOST \$ORIGIN_SITEPATH"
    exit 1;
fi

if [  -e "$SITEPATH" ]; then
    echo "A site alreay exists at $SITEPATH, try using sync."
    exit 1;
fi

# Build an empty site 
d7_init.sh "$SITEPATH"  || exit 1

echo "Copying makefiles!"
for file in "site.make" "site.make.uri" ; do
    scp "$SRCHOST:$ORIGIN_SITEPATH/etc/${file}" "$SITEPATH/etc/${file}" || exit 1
done

# Perms
echo "Setting permissions for config files."
d7_perms_sticky.sh "$SITEPATH/etc"

# Install modules and themes
d7_make.sh "$SITEPATH" || exit 1

# sync files and db
d7_sync.sh "$SITEPATH" "$SRCHOST" "$ORIGIN_SITEPATH" || exit 1



