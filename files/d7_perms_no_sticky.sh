#!/usr/bin/env bash
## Set permissions on the specified dir
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [ ! -z "$1" ]
then
  INPUTDIR=$1
  echo "Processing $INPUTDIR"
else
  echo "Requires input dir (eg. /srv/example/drupal) as argument"
  exit 1;
fi

## Set perms
sudo -u apache find "$INPUTDIR" -type d -exec chmod u=rwx,g=rx,o= '{}' \;
sudo -u apache find "$INPUTDIR" -type f -exec chmod u=rw,g=r,o= '{}' \;
sudo semanage fcontext -a -t httpd_sys_content_t  "$INPUTDIR(/.*)?" || exit 1;
sudo restorecon -R "$INPUTDIR" || exit 1;
sudo chown -R apache:apache "$INPUTDIR"
