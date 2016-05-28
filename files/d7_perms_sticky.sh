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
sudo -u apache chmod u=rwxs,g=rwxs,o= $INPUTDIR 2>/dev/null || chmod u=rwxs,g=rwxs,o= $INPUTDIR
find "$INPUTDIR" -type d -exec bash -c "sudo -u apache chmod u=rwxs,g=rwxs,o= '{}' 2>/dev/null || chmod u=rwxs,g=rwxs,o= '{}'" \;
find "$INPUTDIR" -type f -exec bash -c "sudo -u apache chmod u=rw,g=rw,o= '{}' 2>/dev/null || chmod u=rw,g=rw,o= '{}'" \;
sudo semanage fcontext -a -t httpd_sys_content_t  "$INPUTDIR(/.*)?"
sudo restorecon -R "$INPUTDIR"
sudo -u apache chgrp -R apache $INPUTDIR 2>/dev/null || chgrp -R apache $INPUTDIR
