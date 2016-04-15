#!/usr/bin/env bash
## Create Apache config for Drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Processing $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Site should already be there
if [[ ! -e $SITEPATH ]]; then
    echo "$SITEPATH doesn't exist!"
    exit 1
fi

## Grab the basename of the site to use in conf.
SITE=$(basename "$SITEPATH")

## Make the apache config
echo "Generating Apache Config."

sudo -u apache mkdir "$SITEPATH/etc"
sudo -u apache sh -c "sed "s/__SITE_DIR__/$SITE/g" /opt/d7/etc/d7_init_httpd_template > $SITEPATH/etc/srv_$SITE.conf" || exit 1;
sudo -u apache sh -c "sed -i "s/__SITE_NAME__/$SITE/g" $SITEPATH/etc/srv_$SITE.conf" || exit 1;

sudo semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/etc(/.*)?" || exit 1;
sudo restorecon -R "$SITEPATH/etc" || exit 1;

sudo systemctl restart httpd || exit 1;
