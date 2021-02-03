#!/usr/bin/env bash
## Set permissions on the specified dir

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_perms.sh sets our preferred permissions for a Drupal path. 

Usage: d7_perms.sh [--sticky] \$DIR
            
--sticky    Optional argument adds group write with sticky bit. 
            This is the default behavior for dev environments.  
\$INPUTDIR      Folder to modify (eg. /srv/example/drupal).
USAGE

  exit 1;
fi

# Process options and args
if [ "$1" == "--sticky" ] ; then 
    STICKY="sticky"
    INPUTDIR="$2"
else
    INPUTDIR=$1
fi

# Validate arguments
if  [ -z "$INPUTDIR" ] || [ ! -e "$INPUTDIR" ]; then 
    echo "Error: Cowardly refusing to set perms on nonexistent \$INPUTDIR \"${INPUTDIR}\"."
    exit 1;
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
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "${INPUTDIR}(/.*)?"
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
  PERMS_CMD="${PERMS_CMD} chgrp -v  apache ${DIR} ;" 
  PERMS_CMD="${PERMS_CMD} chmod -v ${DIRPERMS} ${DIR} ;"  
done
echo ${PERMS_CMD} | sudo -s -- 

## Find all of the files.
declare -a FILES
while IFS= read -r -d '' FILE; do
  FILES+=( "$FILE" )
done < <(find "${INPUTDIR}" -mindepth 1 -type f -print0 2>/dev/null)

## Loop through the files, setting appropriate perms.
for FILE in "${FILES[@]}"; do
  PERMS_CMD="${PERMS_CMD} chgrp -v  apache ${FILE} ;" 
  PERMS_CMD="${PERMS_CMD} chmod -v ${FILEPERMS} ${FILE} ;"  
done
echo ${PERMS_CMD} | sudo -s -- 


echo "Done!"

# Returning 0 because variances in storage leads to a lot of false
# positives in detecting errors.
exit 0
