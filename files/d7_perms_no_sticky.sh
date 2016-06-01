#!/usr/bin/env bash
## Set permissions on the specified dir
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [ ! -z "$1" ]
then
  INPUTDIR=$1
else
  echo "Requires input dir (eg. /srv/example/drupal) as argument"
  exit 1;
fi

DIRPERMS='u=rwx,g=rx,o='
FILEPERMS='u=rw,g=r,o='

if [ ! -d "$INPUTDIR" ]; then
  echo "cannot access ${INPUTDIR}: No such or directory"
  exit 1
fi

echo "Setting permissions on ${INPUTDIR}"

## Set SELinux context.  Useless over NFS/SMB.
sudo semanage fcontext -a -t httpd_sys_content_t  "${INPUTDIR}(/.*)?"
sudo restorecon -R "${INPUTDIR}"

## Set perms. Try as apache first, then as self.

## Recursively set group to apache.
sudo -u apache chgrp -R apache "${INPUTDIR}" 2>/dev/null || \
chgrp -R apache "${INPUTDIR}" 2>/dev/null

## Recursively set perms for input directory.
sudo -u apache chmod -R ${DIRPERMS} "${INPUTDIR}" 2>/dev/null || \
chmod -R ${DIRPERMS} "${INPUTDIR}" 2>/dev/null

## Find all of the files
declare -a FILES
while IFS= read -r -d '' FILE; do
  FILES+=( "$FILE" )
done < <(find "${INPUTDIR}" -mindepth 1 -type f -print0 2>/dev/null)

## Loop through the files, setting appropriate perms.
for FILE in "${FILES[@]}"; do
  sudo -u apache chmod ${FILEPERMS} "${FILE}" 2>/dev/null || \
  chmod ${FILEPERMS} "${FILE}" 2>/dev/null
done
