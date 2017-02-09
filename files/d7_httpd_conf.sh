#!/usr/bin/env bash

## Create Apache config for Drupal site

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then

  cat <<USAGE

d7_httpd_conf.sh generates the Apache config for a site.

Usage: d7_httpd_conf.sh \$SITEPATH [\$SITE_TYPE]

\$SITEPATH  Drupal site.
\$SITE_TYPE  optional argument, standalone (default), master, or sub.

USAGE

  exit 1;

fi

SITEPATH=$1

## Site should already be there
if [[ ! -e $SITEPATH ]]; then
    echo "$SITEPATH doesn't exist!"
#    exit 1
fi

if [ ! -z "$2" ]; then
  if [ "$2" == "standalone" ] || [ "$2" == "master" ] || [ "$2" == "sub" ]; then
    SITE_TYPE=$2
  fi
else
    SITE_TYPE=standalone
fi

## Grab the basename of the site to use in conf.
SITE=$(basename "$SITEPATH")

## Make the apache config
echo "Generating Apache config for ${SITEPATH}."
sudo -u apache mkdir -p "$SITEPATH/etc"

## Standalone config gets our original template
if [ "$SITE_TYPE" == "standalone" ]; then
  sudo -u apache sh -c "sed "s/__SITE_DIR__/$SITE/g" /opt/d7/etc/d7_init_httpd_template > $SITEPATH/etc/srv_$SITE.conf" || exit 1;
  sudo -u apache sh -c "sed -i "s/__SITE_NAME__/$SITE/g" $SITEPATH/etc/srv_$SITE.conf" || exit 1;

# Master gets a special interactive configuration

elif [ "$SITE_TYPE" == "master" ]; then
  echo "Generating ${SITEPATH}/etc/srv_${SITE}.conf with additional subsite information."

  # Start off normally
  read -r -d '' SRV_SITE_CONF <<- EOF
<VirtualHost *:443>

  Include /etc/httpd/conf.d/00ssl.include
  SSLCertificateFile \${HTTPD_CERT_PATH}/star.\${HTTPD_DN_SUFFIX}/cert.pem
  SSLCertificateKeyFile \${HTTPD_KEY_PATH}/star.\${HTTPD_DN_SUFFIX}/privkey.pem
  SSLCertificateChainFile \${HTTPD_CERT_PATH}/star.\${HTTPD_DN_SUFFIX}/chain.pem

  ServerName ${SITE}.\${HTTPD_DN_SUFFIX}
  DocumentRoot /srv/${SITE}/drupal

  <Directory "/srv/${SITE}/drupal">
    Options Indexes FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
    Require all granted
  </Directory>
EOF
  ## Ask for a list of sub sites and do some config for each of them
  # list of subsites
  read -r -e -p "Enter comma-separated list of subsite paths: " SUBSITEPATHS
  for SUBSITEPATH in $( echo ${SUBSITEPATHS} | tr "," "\n" ); do
    SUBSITE=$(basename "$SUBSITEPATH")
    read -r -d '' SRV_SITE_CONF <<- EOF
${SRV_SITE_CONF}

  Alias /${SUBSITE} /srv/${SUBSITE}/drupal

  <Directory "/srv/${SUBSITE}/drupal">
    Options Indexes FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
    Require all granted
  </Directory>
EOF
  done
  ## Finish normally
  read -r -d '' SRV_SITE_CONF <<- EOF
${SRV_SITE_CONF}

</VirtualHost>
EOF

  sudo -u apache echo "$SRV_SITE_CONF"| sudo -u apache tee -a "$SITEPATH/etc/srv_$SITE.conf" >/dev/null

# Subsite gets an empty configuration
elif [ "$SITE_TYPE" == "sub" ]; then
  sudo -u apache sh -c "echo \# > ${SITEPATH}/etc/srv_$SITE.conf" || exit 1;
fi

## Allow apache to read its config
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/etc(/.*)?" || exit 1;
sudo restorecon -R "$SITEPATH/etc" || exit 1;

## Set perms
echo "Setting permissions for config files."
d7_perms.sh --sticky "$SITEPATH/etc"

sudo systemctl restart httpd || exit 1;
