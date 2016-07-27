#!/usr/bin/env bash
## Create Apache config for Drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_httpd_conf.sh generates the Apache config for a site.

Usage: d7_httpd_conf.sh \$SITEPATH
            
\$SITEPATH  Drupal site.
USAGE

  exit 1;
fi

SITEPATH=$1

## Site should already be there
if [[ ! -e $SITEPATH ]]; then
    echo "$SITEPATH doesn't exist!"
    exit 1
fi

## Grab the basename of the site to use in conf.
SITE=$(basename "$SITEPATH")

## Make the apache config
echo "Generating Apache config for ${SITEPATH}."

sudo -u apache mkdir -p "$SITEPATH/etc"

sudo -u apache sh -c "sed "s/__SITE_DIR__/$SITE/g" /opt/d7/etc/d7_init_httpd_template > $SITEPATH/etc/srv_$SITE.conf" || exit 1;
sudo -u apache sh -c "sed -i "s/__SITE_NAME__/$SITE/g" $SITEPATH/etc/srv_$SITE.conf" || exit 1;

## Allow apache to read its config
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/etc(/.*)?" || exit 1;
sudo restorecon -R "$SITEPATH/etc" || exit 1;

## Set perms
echo "Setting permissions for config files."
d7_perms.sh --sticky "$SITEPATH/etc"

sudo systemctl restart httpd || exit 1;
