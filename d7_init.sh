#!/bin/sh
## Bootstrap an empty drupal site
PATH=/usr/local/bin:/usr/bin:/bin:/sbin

SITESOWNER=apache:apache                        # unix owner and group of /srv.

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Processing $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Set sudo if user isn't root
SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi

## Don't blow away existing sites
if [[ -e $SITEPATH ]]; then
    echo "$SITEPATH already exists!"
    exit 1
fi

# Get root DB password
read -s -p "Enter MYSQL root password: " ROOTDBPSSWD
echo

while ! mysql -u root -p$ROOTDBPSSWD  -e ";" ; do
    read -s -p "Can't connect, please retry: " ROOTDBPSSWD
done

# Generate Drupal DB password
DBPSSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

## Make the parent directory
$SUDO mkdir -p $SITEPATH
$SUDO chown $SITESOWNER $SITEPATH
$SUDO chmod 775 $SITEPATH

## Grab the basename of the site to use in a few places.
SITE=`basename $SITEPATH`

## Build from drush make
drush -y dl drupal --drupal-project-rename=drupal --destination=$SITEPATH || exit 1;

## Set perms- allows group write
echo "Setting permissions."
find $SITEPATH/drupal -type d -exec chmod u=rwx,g=rwx,o= '{}' \;
find $SITEPATH/drupal -type f -exec chmod u=rw,g=rw,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy."
$SUDO semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/drupal(/.*)?" || exit 1;
$SUDO restorecon -R $SITEPATH/drupal || exit 1;

##  Move the default site out of the build. This makes updates easier later.
echo "Moving default site out of build."
mv $SITEPATH/drupal/sites/default $SITEPATH/

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into build."
ln -s $SITEPATH/default $SITEPATH/drupal/sites/default

echo "Generating settings.php."
read -d '' SETTINGSPHP <<- EOF
\$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => 'drupal_$SITE',
      'username' => '$SITE',
      'password' => '$DBPSSWD',
      'host' => 'localhost',
      'port' => '',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);
EOF

cp $SITEPATH/default/default.settings.php $SITEPATH/default/settings.php
echo "$SETTINGSPHP" >> $SITEPATH/default/settings.php
$SUDO chmod 444 $SITEPATH/default/settings.php

# Set owner
echo "Changing owner."
$SUDO chown -R $SITESOWNER $SITEPATH

## Create the Drupal database
drush -y sql-create --db-su=root --db-su-pw=$ROOTDBPSSWD -r $SITEPATH/drupal || exit 1;

## Do the Drupal install
drush -y -r $SITEPATH/drupal site-install --site-name=$SITE || exit 1;

## Make the apache config
echo "Generating Apache Config."
#$SUDO rm /etc/httpd/conf.d/srv_$SITE.conf
$SUDO sh -c " sed "s/__SITE_DIR__/$SITE/g" /etc/httpd/conf.d/template_init_oulib_drupal > /etc/httpd/conf.d/srv_$SITE.conf" || exit 1;
$SUDO service httpd configtest || exit 1;
$SUDO service httpd reload || exit 1;
