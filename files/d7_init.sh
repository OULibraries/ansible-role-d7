#!/usr/bin/env bash
## Bootstrap an empty drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

## Require arguments
if [ ! -z "$1" ]
then
  SITEPATH=$1
  echo "Processing $SITEPATH"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Don't blow away existing sites
if [[ -e "$SITEPATH" ]]; then
    echo "$SITEPATH already exists!"
    exit 1
fi



# Get external host suffix (rev proxy, ngrok, etc)
read -r -e -p "Enter host suffix (e.g. lib.ou.edu): " -i "$D7_HOST_SUFFIX" MY_HOST_SUFFIX 

# Get mysql host 
read -r -e -p "Enter MYSQL host name: " -i "$D7_DBHOST" DBHOST
# Get mysql port
read -r -e -p "Enter MYSQL host port: " -i "$D7_DBPORT" DBPORT

# Get DB admin user
read -r -e -p "Enter MYSQL admin user: " -i "$D7_DBSU" DBSU
# Get DB admin password
read -r -s -p "Enter MYSQL root password: " D7_DBSU_PASS
while ! mysql -u "$D7_DBSU" -p"$D7_DBSU_PASS"  -e ";" ; do
    read -r -s -p "Can't connect, please retry: " D7_DBSU_PASS
done

# Generate Drupal DB password
DBPSSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

## Make the parent directory
sudo mkdir -p "$SITEPATH"
sudo chmod 775 "$SITEPATH"
sudo chown apache:apache "$SITEPATH"

## Grab the basename of the site to use in a few places.
SITE=$(basename "$SITEPATH")

## Build from drush make
sudo -u apache drush @none -y dl drupal --drupal-project-rename=drupal --destination="$SITEPATH" || exit 1;

## Set perms
echo "Setting permissions."

## Get sudo password if needed because first sudo use is behind a pipe.
sudo ls > /dev/null
find "$SITEPATH/drupal" -type d -exec sudo -u apache chmod u=rwx,g=rx,o= '{}' \;
find "$SITEPATH/drupal" -type f -exec sudo -u apache chmod u=rw,g=r,o= '{}' \;

# Set SELinux or die
echo "Setting SELinux policy."
sudo semanage fcontext -a -t httpd_sys_content_t  "$SITEPATH/drupal(/.*)?" || exit 1;
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/default/files(/.*)?" || exit 1
sudo restorecon -R "$SITEPATH/drupal" || exit 1;

##  Move the default site out of the build. This makes updates easier later.
echo "Moving default site out of build."
sudo -u apache mv "$SITEPATH/drupal/sites/default" "$SITEPATH"/

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into build."
sudo -u apache ln -s "$SITEPATH/default" "$SITEPATH/drupal/sites/default"

echo "Generating settings.php."
read -r -d '' SETTINGSPHP <<- EOF
\$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => 'drupal_${SITE}_${ENV_NAME}',
      'username' => '$SITE',
      'password' => '$DBPSSWD',
      'host' => '$DBHOST',
      'port' => '$DBPORT',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);

## Set public-facing hostname.
\$base_url = 'https://${SITE}.${MY_HOST_SUFFIX}';
\$cookie_domain = '${SITE}.${MY_HOST_SUFFIX}';

EOF

sudo -u apache cp "$SITEPATH/default/default.settings.php" "$SITEPATH/default/settings.php"
sudo -u apache echo "$SETTINGSPHP"| sudo -u apache tee -a "$SITEPATH/default/settings.php" >/dev/null
sudo -u apache chmod 444 "$SITEPATH/default/settings.php"

## Create the Drupal database
sudo -u apache drush -y sql-create --db-su="${D7_DBSU}" --db-su-pw="$D7_DBSU_PASS" -r "$SITEPATH/drupal" || exit 1;

## Do the Drupal install
sudo -u apache drush -y -r "$SITEPATH/drupal" site-install --site-name="$SITE" || exit 1;

## Apply the apache config
d7_httpd_conf.sh "$SITEPATH" || exit 1;

## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;
