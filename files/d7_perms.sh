#!/usr/bin/env bash
## Set permissions on the specified dir
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_perms.sh sets our preferred permissions for a Drupal path. 

Usage: d7_perms.sh [--sticky] \$PATH
            
\$PATH      Folder to modify (eg. /srv/example/drupal).
--sticky    Optional argument adds group write with sticky bit. 
            This is the default behavior for dev environments.  
USAGE

  exit 1;
fi

# Check for argument to set sticky group perms
if [ "$1" == "--sticky" ]; then 
    STICKY="sticky"
    INPUTDIR="$2"
else 
    INPUTDIR="$1"
fi 

if  [[ "${ENV_NAME}" == *dev ]] || [ "${STICKY}" == "sticky" ]; then
  # Looser permissions in sticky mode and dev environments so that
  # files can be moved around by all group members
  DIRPERMS='u=rwxs,g=rwxs,o='
  FILEPERMS='u=rw,g=rw,o='
  POLICY="sticky group"
else
  # Default to more restrictive perms for drupal files in prod mode
  DIRPERMS='u=rwx,g=rx,o='
  FILEPERMS='u=rw,g=r,o='
  POLICY="strict (no group)"
fi

if [ ! -d "$INPUTDIR" ]; then
  echo "cannot access ${INPUTDIR}: No such directory"
  exit 1
fi

echo "Setting ${POLICY} permissions on ${INPUTDIR}"

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

# Returning 0 because variances in storage leads to a lot of false
# positives in detecting errors.
exit 0
