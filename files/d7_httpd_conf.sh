#!/usr/bin/env bash

## Create Apache config for Drupal site

source /opt/d7/etc/d7_conf.sh

if [  -z "$1" ]; then

  cat <<USAGE

d7_httpd_conf.sh generates or updates the Apache config for a site.

Usage: d7_httpd_conf.sh \$SITEPATH [\$SITETYPE]

\$SITEPATH  local path for Drupal site (eg. /srv/example).
\$SITETYPE  (optional) site type: "master" or "sub". Default is master.

USAGE

  exit 1;

fi

SITEPATH=$1
SITETYPE=master

## Site should already be there
if [[ ! -e $SITEPATH ]]; then
    echo "$SITEPATH doesn't exist!"
    exit 1
fi

if [ ! -z "$2" ]; then

    if [  "$2" != "master"  -a  "$2" != "sub"  ]; then
	  echo "Bad site type: $2"
	  exit 1
    fi
    SITETYPE="$2"
fi

echo "Appling configuration type $SITETYPE at $SITEPATH"

## Grab the basename of the site to use in conf.
SITE=$(basename "$SITEPATH")

## Make the apache config
echo "Generating Apache config for ${SITEPATH}."
sudo -u apache mkdir -p "$SITEPATH/etc"

if [ "$SITETYPE" == "master" ]; then
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
    Order allow,deny
    Allow from all
    Require all granted
    AllowOverride None
    Include /etc/httpd/conf.d/drupal.include
  </Directory>
EOF

  for SUBSITEPATH in $( cat "${SITEPATH}/etc/subsites" ); do
      SUBSITE=$(basename "$SUBSITEPATH")
      read -r -d '' SRV_SITE_CONF <<- EOF

${SRV_SITE_CONF}

  Alias /${SUBSITE} /srv/${SUBSITE}/drupal

  <Directory "/srv/${SUBSITE}/drupal">
    Order allow,deny
    Allow from all
    Require all granted
    AllowOverride None

    RewriteEngine on
    RewriteBase /${SUBSITE}
    Include /etc/httpd/conf.d/drupal.include
  </Directory>

  Include /etc/httpd/conf.d/drupal-files.include

EOF
  done

  ## Finish normally
  read -r -d '' SRV_SITE_CONF <<- EOF
${SRV_SITE_CONF}

</VirtualHost>
EOF

  sudo -u apache echo "$SRV_SITE_CONF"| sudo -u apache tee "$SITEPATH/etc/srv_$SITE.conf" >/dev/null

# Subsite gets an empty configuration
elif [ "$SITETYPE" == "sub" ]; then
  sudo -u apache sh -c "echo \# > ${SITEPATH}/etc/srv_${SITE}.conf" || exit 1;
fi

## Allow apache to read its config
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/etc(/.*)?" || exit 1;
sudo restorecon -R "$SITEPATH/etc" || exit 1;

## Set perms
echo "Setting permissions for config files."
d7_perms.sh --sticky "$SITEPATH/etc"

sudo systemctl restart httpd || exit 1;
