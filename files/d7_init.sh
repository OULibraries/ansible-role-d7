#!/usr/bin/env bash
## Bootstrap an empty drupal site
PATH=/opt/d7/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE

d7_init.sh builds a Drupal site.

Usage: d7_init.sh \$SITEPATH
            
\$SITEPATH  Destination for Drupal site (eg. /srv/example).

USAGE

  exit 1;
fi

SITEPATH=$1

## Don't blow away existing sites
if [[ -e "$SITEPATH" ]]; then
    echo "$SITEPATH already exists!"
    exit 1
fi

echo "Initializing site at ${SITEPATH}."

# Get external host suffix (rev proxy, ngrok, etc)
read -r -e -p "Enter host suffix: " -i "$D7_HOST_SUFFIX" MY_HOST_SUFFIX 

# Get mysql host 
read -r -e -p "Enter MYSQL host name: " -i "$D7_DBHOST" MY_DBHOST
# Get mysql port
read -r -e -p "Enter MYSQL host port: " -i "$D7_DBPORT" MY_DBPORT

# Get DB admin user
read -r -e -p "Enter MYSQL user: " -i "$D7_DBSU" MY_DBSU
# Get DB admin password
read -r -s -p "Enter MYSQL password: " MY_DBSU_PASS
while  [ -z "$MY_DBSU_PASS" ] || ! mysql --host="$MY_DBHOST" --port="$MY_DBPORT" --user="$MY_DBSU" --password="$MY_DBSU_PASS"  -e ";" ; do
    read -r -s -p "Can't connect, please retry: " MY_DBSU_PASS
done

echo
echo
echo "Let's build a site!"
echo

## Make the parent directory
sudo -u apache mkdir -p "$SITEPATH"
sudo -u apache chmod 775 "$SITEPATH"

## Grab the basename of the site to use in a few places.
SITE=$(basename "$SITEPATH")

## Build from drush make
sudo -u apache drush @none -y dl drupal --drupal-project-rename=drupal --destination="$SITEPATH" || exit 1;

##  Move the default site out of the build. This makes updates easier later.
echo "Moving default site out of build."
sudo -u apache mv "$SITEPATH/drupal/sites/default" "$SITEPATH"/

## Drupal default site dir is ~ 6770
d7_perms.sh --sticky "$SITEPATH/default"

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into build."
sudo -u apache ln -s "$SITEPATH/default" "$SITEPATH/drupal/sites/default" || exit 1;

echo "Generating settings.php."
read -r -d '' SETTINGSPHP <<- EOF
\$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => 'drupal_${SITE}_${ENV_NAME}',
      'username' => '${MY_DBSU}',
      'password' => '${MY_DBSU_PASS}',
      'host' => '$MY_DBHOST',
      'port' => '$MY_DBPORT',
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

## Create the Drupal database
sudo -u apache drush -y sql-create --db-su="${MY_DBSU}" --db-su-pw="$MY_DBSU_PASS" -r "$SITEPATH/drupal" || exit 1;

## Do the Drupal install
sudo -u apache drush -y -r "$SITEPATH/drupal" site-install --site-name="$SITE" || exit 1;

## Apply env specific perms to drupal
d7_perms.sh "$SITEPATH/drupal"

## Apply the apache config
d7_httpd_conf.sh "$SITEPATH" || exit 1;

## Apply security updates and clear caches.
d7_update.sh "$SITEPATH" || exit 1;

echo
echo "Finished building site at ${SITEPATH}"
echo 
