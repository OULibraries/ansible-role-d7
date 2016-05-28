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
sudo -u apache chgrp -R apache "${INPUTDIR}" 2>/dev/null ||\
chgrp -R apache "${INPUTDIR}" 2>/dev/null

## Set perms. Try as apache first, then as self.
## We're doing files, then subdirs, then top dir

## Loop through the files
for FILE in `find "${INPUTDIR}" -mindepth 1 -maxdepth 1 -type f`
do
  sudo -u apache chmod ${FILEPERMS} "${FILE}" 2>/dev/null ||\
  chmod ${FILEPERMS} "${FILE}" 2>/dev/null
done

## Loop through the subdirectories
for SUBDIR in `find "${INPUTDIR}" -mindepth 1 -maxdepth 1 -type d`
do
  sudo -u apache chmod ${DIRPERMS} "${SUBDIR}" 2>/dev/null ||\
  chmod ${DIRPERMS} "${SUBDIR}" 2>/dev/null
done

## Set perms for input directory itself. Try as apache first, then as self.
## For no reason I can fathom, this must come last.
sudo -u apache chmod ${DIRPERMS} "${INPUTDIR}" ||\
chmod ${DIRPERMS} "${INPUTDIR}"
