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

## Set perms. Try as apache first, then as self.  Only show errors if both attempts have failed.
sudo -u apache chmod u=rwx,g=rx,o= $INPUTDIR 2>/dev/null || chmod u=rwx,g=rx,o= $INPUTDIR
find "$INPUTDIR" -type d -exec bash -c "sudo -u apache chmod u=rwx,g=rx,o= '{}' 2>/dev/null || chmod u=rwx,g=rx,o= '{}'" \;
find "$INPUTDIR" -type f -exec bash -c "sudo -u apache chmod u=rw,g=r,o= '{}' 2>/dev/null || chmod u=rw,g=r,o= '{}'" \;
sudo semanage fcontext -a -t httpd_sys_content_t  "$INPUTDIR(/.*)?"
sudo restorecon -R "$INPUTDIR"
sudo -u apache chgrp -R apache $INPUTDIR 2>/dev/null || chgrp -R apache $INPUTDIR
