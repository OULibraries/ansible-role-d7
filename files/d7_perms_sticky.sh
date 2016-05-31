#!/usr/bin/env bash
## Set permissions on the specified dir
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

## Require arguments
if [ ! -z "$1" ]
then
  INPUTDIR=$1
  echo "Processing ${INPUTDIR}"
else
  echo "Requires input dir (eg. /srv/example/drupal) as argument"
  exit 1;
fi

DIRPERMS='u=rwxs,g=rwxs,o='
FILEPERMS='u=rw,g=rw,o='

## This stuff may not do anything on NFS
sudo semanage fcontext -a -t httpd_sys_content_t  "${INPUTDIR}(/.*)?"
sudo restorecon -R "${INPUTDIR}"
sudo -u apache chgrp -R apache "${INPUTDIR}" 2>/dev/null || \
chgrp -R apache "${INPUTDIR}" 2>/dev/null

## Set perms. Try as apache first, then as self.

## Recursively set perms for input directory.
sudo -u apache chmod -R ${DIRPERMS} "${INPUTDIR}" || \
chmod -R ${DIRPERMS} "${INPUTDIR}"

## Find all of the files
declare -a FILES
while IFS= read -r -d '' FILE; do
  FILES+=( "$FILE" )
done < <(find "${INPUTDIR}" -mindepth 1 -print0 -type f 2>/dev/null)

## Loop through the files, setting appropriate perms.
for FILE in "${FILES[@]}"; do
  sudo -u apache chmod ${FILEPERMS} "${FILE}" 2>/dev/null || \
  chmod ${FILEPERMS} "${FILE}" 2>/dev/null
done
