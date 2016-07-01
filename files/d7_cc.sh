#!/usr/bin/env bash
## Clear Drupal and APC caches
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_cc.sh clears all Drupal caches for a site, and clears the localhost apc cache.

Usage: d7_cc.sh \$SITEPATH
            
\$SITEPATH  Drupal site  (eg. /srv/example).
USAGE

  exit 1;
fi

SITEPATH=$1

if [[ ! -e "$SITEPATH" ]] ;then
    echo "Can't find site at $SITEPATH."
    exit 0
fi

# Kludging APC username and password from php file.
APC_USER=$(cat /usr/share/pear/apc.php  | grep ^defaults.*USERNAME | grep -o \'.*\',\'.*\' | awk  'BEGIN { FS=","};  {print $2}')
APC_USER=${APC_USER:1:-1}
APC_PASS=$(cat /usr/share/pear/apc.php  | grep ^defaults.*PASSWORD | grep -o \'.*\',\'.*\' | awk  'BEGIN { FS=","};  {print $2}')
APC_PASS=${APC_PASS:1:-1}

echo "Clearing APC cache"
curl --silent --basic --user "${APC_USER}:${APC_PASS}" "http://localhost/apc.php?SCOPE=A&SORT1=H&SORT2=D&COUNT=20&CC=1&OB=1" >/dev/null || exit 1;

echo "Clearing Drupal caches for ${SITEPATH}."
sudo -u apache drush -y cc all -r "$SITEPATH/drupal" || exit 1;
