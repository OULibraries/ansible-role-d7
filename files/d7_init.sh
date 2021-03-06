#!/usr/bin/env bash
## Bootstrap an empty drupal site

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
d7_init.sh builds a Drupal site.

Usage: d7_init.sh \$SITEPATH [\$MASTERPATH]

\$SITEPATH    local path for Drupal site (eg. /srv/example).
\$MASTERPATH  (optional) local path to master site

USAGE

  exit 1;
fi

SITEPATH="$(realpath  --canonicalize-missing --no-symlinks $1)"
MASTERPATH=${SITEPATH}  # default to site being it's own master
SITETYPE=master


# some sites are subsites
if [ ! -z "$2" ] && [ ! "${SITEPATH}" == "$2" ]; then
    SITETYPE="sub"
    MASTERPATH="$(realpath  --canonicalize-missing --no-symlinks $2)"
fi

## Don't blow away existing sites
if [[ -e "$SITEPATH" ]]; then
    echo "$SITEPATH already exists!"
    exit 1
fi

## Grab the base for SITEPATH and MASTERPATH to use as slugs
SITE=$(basename "$SITEPATH")
MASTERSITE=$(basename "$MASTERPATH")

## Sanitize the DB slug by excluding everything that MySQL doesn't like from $SITE
DBSLUG=$(echo -n  "${SITE}" | tr -C '_A-Za-z0-9' '_')

echo "Initializing ${SITETYPE} site at ${SITEPATH}."

# Get external host suffix (rev proxy, ngrok, etc)
read -r -e -p "Enter host suffix: " -i "$D7_HOST_SUFFIX" MY_HOST_SUFFIX


# By default, we're operating at the root for a domain
SUBPATH="";

# Set subpath for subsites
if [ "$SITETYPE" == "sub" ]; then
    SUBPATH="/${SITE}"
fi

## Set some URL-related setings
BASE_URL="https://${MASTERSITE}.${MY_HOST_SUFFIX}${SUBPATH}"
COOKIE_DOMAIN="${MASTERSITE}.${MY_HOST_SUFFIX}"

# Get base URL. Default is the root of the sitename over HTTPS.
read -r -e -p "Enter base URL without trailing slash: " -i "${BASE_URL}" MY_BASE_URL

# Get cookie domain. Default is site name, but may need to be changed for SSO.
read -r -e -p "Enter cookie domain: " -i "${COOKIE_DOMAIN}" MY_COOKIE_DOMAIN

# Get CAS host.
read -r -e -p "Enter CAS server: " -i "${D7_CAS}" MY_CAS

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

# Add some whitespace because read doesn't
echo
echo "Let's build a site!"


## Make the parent directory
sudo -u apache mkdir -p "$SITEPATH"
sudo -u apache chmod 775 "$SITEPATH"

# Let master site know about subsite
if [ "$SITETYPE" == "sub" ]; then
    echo "Register with master at ${MASTERPATH}."
    mkdir -v -p "${MASTERPATH}/etc/subsites"
    touch "${MASTERPATH}/etc/subsites/${SITE}"
fi

## Install drupal core
sudo -u apache drush @none -y dl drupal --drupal-project-rename=drupal --destination="$SITEPATH" || exit 1;

##  Move the default site out of the build. This makes updates easier later.
echo "Moving default site out of build."
sudo -u apache mv "$SITEPATH/drupal/sites/default" "$SITEPATH"/

## Link default site folder. Doing this last ensures that our earlier recursive
## operations aren't duplicating efforts.
echo "Linking default site into build."
sudo -u apache ln -s "$SITEPATH/default" "$SITEPATH/drupal/sites/default" || exit 1;

echo "Generating settings.php with database ${DBSLUG}."
read -r -d '' SETTINGSPHP <<- EOF
\$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => 'drupal_${DBSLUG}_${ENV_NAME}',
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
\$base_url = '${MY_BASE_URL}';
\$cookie_domain = '${MY_COOKIE_DOMAIN}';

## Set CAS config
\$conf['cas_server'] = '${MY_CAS}';

## Include site-wide settings file 
include '/opt/d7/etc/d7_host_config.inc.php';


# Include site-wide Solr config for Apachesolr
# Uncomment to enable
# include '/opt/d7/etc/d7_solr_config.inc.php';

# Add additional manually configured settings below
#
EOF

sudo -u apache cp "/opt/d7/etc/default.settings.php" "$SITEPATH/default/settings.php"
sudo -u apache echo "$SETTINGSPHP"| sudo -u apache tee -a "$SITEPATH/default/settings.php" >/dev/null

## Create the Drupal database
sudo -u apache drush -y sql-create --db-su="${MY_DBSU}" --db-su-pw="$MY_DBSU_PASS" -r "$SITEPATH/drupal" || exit 1;

## Do the Drupal install
sudo -u apache drush -y -r "$SITEPATH/drupal" site-install --site-name="$SITE" || exit 1;

## Apply the apache config
d7_httpd_conf.sh "$SITEPATH" "$SITETYPE" || exit 1;

## Clear caches.
d7_cc.sh "$SITEPATH" || exit 1;

# Apply our standard permissions to the new site
d7_perms_fix.sh "$SITEPATH"

echo "Finished building site at ${SITEPATH}."
echo "If this is a new site, make sure to note the admin password."
