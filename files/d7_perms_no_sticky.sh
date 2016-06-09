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
  echo "cannot access ${INPUTDIR}: No such directory"
  exit 1
fi

echo "Setting permissions on ${INPUTDIR}"

## Set SELinux context.  Useless over NFS/SMB.
sudo semanage fcontext -a -t httpd_sys_content_t  "${INPUTDIR}(/.*)?"
sudo restorecon -R "${INPUTDIR}"

## Set perms. Try as apache first, then as self.

## Find all of the DIRs.
declare -a DIRS
while IFS= read -r -d '' DIR; do
  
  ## Add dir to the array.
  DIRS+=( "$DIR" )
done < <(find "${INPUTDIR}" -type d -print0 2>/dev/null)

## Loop through the DIRs, setting appropriate perms.
for DIR in "${DIRS[@]}"; do

  ## Set group to apache.
  sudo -u apache chgrp apache "${DIR}" 2>/dev/null || \
  chgrp apache "${DIR}" 

  ## Set dir perms.
  sudo -u apache chmod ${DIRPERMS} "${DIR}" 2>/dev/null || \
  chmod ${DIRPERMS} "${DIR}" 
done

## Find all of the files.
declare -a FILES
while IFS= read -r -d '' FILE; do
  FILES+=( "$FILE" )
done < <(find "${INPUTDIR}" -mindepth 1 -type f -print0 2>/dev/null)

## Loop through the files, setting appropriate perms.
for FILE in "${FILES[@]}"; do

  ## Set group to apache.
  sudo -u apache chgrp apache "${FILE}" 2>/dev/null || \
  chgrp apache "${FILE}"

  ## Set file perms.
  sudo -u apache chmod ${FILEPERMS} "${FILE}" 2>/dev/null || \
  chmod ${FILEPERMS} "${FILE}"
done
