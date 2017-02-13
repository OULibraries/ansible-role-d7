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
    exit 1
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
    Order allow,deny
    Allow from all
    Require all granted
    AllowOverride None
    #
    # Apache/PHP/Drupal settings:
    #

    # Protect files and directories from prying eyes.
    <FilesMatch "\.(engine|inc|info|install|make|module|profile|test|po|sh|.*sql|theme|tpl(\.php)?|xtmpl)(~|\.sw[op]|\.bak|\.orig|\.save)?$|^(\..*|Entries.*|Repository|Root|Tag|Template|composer\.(json|lock))$|^#.*#$|\.php(~|\.sw[op]|\.bak|\.orig\.save)$">
      Order allow,deny
    </FilesMatch>

    # Don't show directory listings for URLs which map to a directory.
    Options -Indexes

    # Follow symbolic links in this directory.
    Options +FollowSymLinks

    # Make Drupal handle any 404 errors.
    ErrorDocument 404 /index.php

    # Set the default handler.
    DirectoryIndex index.php index.html index.htm

    # Override PHP settings that cannot be changed at runtime. See
    # sites/default/default.settings.php and drupal_environment_initialize() in
    # includes/bootstrap.inc for settings that can be changed at runtime.

    # PHP 5, Apache 1 and 2.
    <IfModule mod_php5.c>
      php_flag magic_quotes_gpc                 off
      php_flag magic_quotes_sybase              off
      php_flag register_globals                 off
      php_flag session.auto_start               off
      php_value mbstring.http_input             pass
      php_value mbstring.http_output            pass
      php_flag mbstring.encoding_translation    off
    </IfModule>

    # Requires mod_expires to be enabled.
    <IfModule mod_expires.c>
      # Enable expirations.
      ExpiresActive On

      # Cache all files for 2 weeks after access (A).
      ExpiresDefault A1209600

      <FilesMatch \.php$>
        # Do not allow PHP scripts to be cached unless they explicitly send cache
        # headers themselves. Otherwise all scripts would have to overwrite the
        # headers set by mod_expires if they want another caching behavior. This may
        # fail if an error occurs early in the bootstrap process, and it may cause
        # problems if a non-Drupal PHP file is installed in a subdirectory.
        ExpiresActive Off
      </FilesMatch>
    </IfModule>

    # Various rewrite rules.
    <IfModule mod_rewrite.c>
      RewriteEngine on

      # Set "protossl" to "s" if we were accessed via https://.  This is used later
      # if you enable "www." stripping or enforcement, in order to ensure that
      # you don't bounce between http and https.
      RewriteRule ^ - [E=protossl]
      RewriteCond %{HTTPS} on
      RewriteRule ^ - [E=protossl:s]

      # Make sure Authorization HTTP header is available to PHP
      # even when running as CGI or FastCGI.
      RewriteRule ^ - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

      # Block access to "hidden" directories whose names begin with a period. This
      # includes directories used by version control systems such as Subversion or
      # Git to store control files. Files whose names begin with a period, as well
      # as the control files used by CVS, are protected by the FilesMatch directive
      # above.
      #
      # NOTE: This only works when mod_rewrite is loaded. Without mod_rewrite, it is
      # not possible to block access to entire directories from .htaccess, because
      # <DirectoryMatch> is not allowed here.
      #
      # If you do not have mod_rewrite installed, you should remove these
      # directories from your webroot or otherwise protect them from being
      # downloaded.
      RewriteRule "(^|/)\." - [F]

      # If your site can be accessed both with and without the 'www.' prefix, you
      # can use one of the following settings to redirect users to your preferred
      # URL, either WITH or WITHOUT the 'www.' prefix. Choose ONLY one option:
      #
      # To redirect all users to access the site WITH the 'www.' prefix,
      # (http://example.com/... will be redirected to http://www.example.com/...)
      # uncomment the following:
      # RewriteCond %{HTTP_HOST} .
      # RewriteCond %{HTTP_HOST} !^www\. [NC]
      # RewriteRule ^ http%{ENV:protossl}://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
      #
      # To redirect all users to access the site WITHOUT the 'www.' prefix,
      # (http://www.example.com/... will be redirected to http://example.com/...)
      # uncomment the following:
      # RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
      # RewriteRule ^ http%{ENV:protossl}://%1%{REQUEST_URI} [L,R=301]

      # Modify the RewriteBase if you are using Drupal in a subdirectory or in a
      # VirtualDocumentRoot and the rewrite rules are not working properly.
      # For example if your site is at http://example.com/drupal uncomment and
      # modify the following line:
      # RewriteBase /drupal
      #
      # If your site is running in a VirtualDocumentRoot at http://example.com/,
      # uncomment the following line:
      # RewriteBase /

      # Pass all requests not referring directly to files in the filesystem to
      # index.php. Clean URLs are handled in drupal_environment_initialize().
      RewriteCond %{REQUEST_FILENAME} !-f
      RewriteCond %{REQUEST_FILENAME} !-d
      RewriteCond %{REQUEST_URI} !=/favicon.ico
      RewriteRule ^ index.php [L]

      # Rules to correctly serve gzip compressed CSS and JS files.
      # Requires both mod_rewrite and mod_headers to be enabled.
      <IfModule mod_headers.c>
        # Serve gzip compressed CSS files if they exist and the client accepts gzip.
        RewriteCond %{HTTP:Accept-encoding} gzip
        RewriteCond %{REQUEST_FILENAME}\.gz -s
        RewriteRule ^(.*)\.css $1\.css\.gz [QSA]

        # Serve gzip compressed JS files if they exist and the client accepts gzip.
        RewriteCond %{HTTP:Accept-encoding} gzip
        RewriteCond %{REQUEST_FILENAME}\.gz -s
        RewriteRule ^(.*)\.js $1\.js\.gz [QSA]

        # Serve correct content types, and prevent mod_deflate double gzip.
        RewriteRule \.css\.gz$ - [T=text/css,E=no-gzip:1]
        RewriteRule \.js\.gz$ - [T=text/javascript,E=no-gzip:1]

        <FilesMatch "(\.js\.gz|\.css\.gz)$">
          # Serve correct encoding type.
          Header set Content-Encoding gzip
          # Force proxies to cache gzipped & non-gzipped css/js files separately.
          Header append Vary Accept-Encoding
        </FilesMatch>
      </IfModule>
    </IfModule>

    # Add headers to all responses.
    <IfModule mod_headers.c>
      # Disable content sniffing, since it's an attack vector.
      Header always set X-Content-Type-Options nosniff
    </IfModule>
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
    Order allow,deny
    Allow from all
    Require all granted
    AllowOverride None
    #
    # Apache/PHP/Drupal settings:
    #

    # Protect files and directories from prying eyes.
    <FilesMatch "\.(engine|inc|info|install|make|module|profile|test|po|sh|.*sql|theme|tpl(\.php)?|xtmpl)(~|\.sw[op]|\.bak|\.orig|\.save)?$|^(\..*|Entries.*|Repository|Root|Tag|Template|composer\.(json|lock))$|^#.*#$|\.php(~|\.sw[op]|\.bak|\.orig\.save)$">
      Order allow,deny
    </FilesMatch>

    # Don't show directory listings for URLs which map to a directory.
    Options -Indexes

    # Follow symbolic links in this directory.
    Options +FollowSymLinks

    # Make Drupal handle any 404 errors.
    ErrorDocument 404 /index.php

    # Set the default handler.
    DirectoryIndex index.php index.html index.htm

    # Override PHP settings that cannot be changed at runtime. See
    # sites/default/default.settings.php and drupal_environment_initialize() in
    # includes/bootstrap.inc for settings that can be changed at runtime.

    # PHP 5, Apache 1 and 2.
    <IfModule mod_php5.c>
      php_flag magic_quotes_gpc                 off
      php_flag magic_quotes_sybase              off
      php_flag register_globals                 off
      php_flag session.auto_start               off
      php_value mbstring.http_input             pass
      php_value mbstring.http_output            pass
      php_flag mbstring.encoding_translation    off
    </IfModule>

    # Requires mod_expires to be enabled.
    <IfModule mod_expires.c>
      # Enable expirations.
      ExpiresActive On

      # Cache all files for 2 weeks after access (A).
      ExpiresDefault A1209600

      <FilesMatch \.php$>
        # Do not allow PHP scripts to be cached unless they explicitly send cache
        # headers themselves. Otherwise all scripts would have to overwrite the
        # headers set by mod_expires if they want another caching behavior. This may
        # fail if an error occurs early in the bootstrap process, and it may cause
        # problems if a non-Drupal PHP file is installed in a subdirectory.
        ExpiresActive Off
      </FilesMatch>
    </IfModule>

    # Various rewrite rules.
    <IfModule mod_rewrite.c>
      RewriteEngine on

      # Set "protossl" to "s" if we were accessed via https://.  This is used later
      # if you enable "www." stripping or enforcement, in order to ensure that
      # you don't bounce between http and https.
      RewriteRule ^ - [E=protossl]
      RewriteCond %{HTTPS} on
      RewriteRule ^ - [E=protossl:s]

      # Make sure Authorization HTTP header is available to PHP
      # even when running as CGI or FastCGI.
      RewriteRule ^ - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

      # Block access to "hidden" directories whose names begin with a period. This
      # includes directories used by version control systems such as Subversion or
      # Git to store control files. Files whose names begin with a period, as well
      # as the control files used by CVS, are protected by the FilesMatch directive
      # above.
      #
      # NOTE: This only works when mod_rewrite is loaded. Without mod_rewrite, it is
      # not possible to block access to entire directories from .htaccess, because
      # <DirectoryMatch> is not allowed here.
      #
      # If you do not have mod_rewrite installed, you should remove these
      # directories from your webroot or otherwise protect them from being
      # downloaded.
      RewriteRule "(^|/)\." - [F]

      # If your site can be accessed both with and without the 'www.' prefix, you
      # can use one of the following settings to redirect users to your preferred
      # URL, either WITH or WITHOUT the 'www.' prefix. Choose ONLY one option:
      #
      # To redirect all users to access the site WITH the 'www.' prefix,
      # (http://example.com/... will be redirected to http://www.example.com/...)
      # uncomment the following:
      # RewriteCond %{HTTP_HOST} .
      # RewriteCond %{HTTP_HOST} !^www\. [NC]
      # RewriteRule ^ http%{ENV:protossl}://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
      #
      # To redirect all users to access the site WITHOUT the 'www.' prefix,
      # (http://www.example.com/... will be redirected to http://example.com/...)
      # uncomment the following:
      # RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
      # RewriteRule ^ http%{ENV:protossl}://%1%{REQUEST_URI} [L,R=301]

      # Modify the RewriteBase if you are using Drupal in a subdirectory or in a
      # VirtualDocumentRoot and the rewrite rules are not working properly.
      # For example if your site is at http://example.com/drupal uncomment and
      # modify the following line:
      RewriteBase /${SUBSITE}
      #
      # If your site is running in a VirtualDocumentRoot at http://example.com/,
      # uncomment the following line:
      # RewriteBase /

      # Pass all requests not referring directly to files in the filesystem to
      # index.php. Clean URLs are handled in drupal_environment_initialize().
      RewriteCond %{REQUEST_FILENAME} !-f
      RewriteCond %{REQUEST_FILENAME} !-d
      RewriteCond %{REQUEST_URI} !=/favicon.ico
      RewriteRule ^ index.php [L]

      # Rules to correctly serve gzip compressed CSS and JS files.
      # Requires both mod_rewrite and mod_headers to be enabled.
      <IfModule mod_headers.c>
        # Serve gzip compressed CSS files if they exist and the client accepts gzip.
        RewriteCond %{HTTP:Accept-encoding} gzip
        RewriteCond %{REQUEST_FILENAME}\.gz -s
        RewriteRule ^(.*)\.css $1\.css\.gz [QSA]

        # Serve gzip compressed JS files if they exist and the client accepts gzip.
        RewriteCond %{HTTP:Accept-encoding} gzip
        RewriteCond %{REQUEST_FILENAME}\.gz -s
        RewriteRule ^(.*)\.js $1\.js\.gz [QSA]

        # Serve correct content types, and prevent mod_deflate double gzip.
        RewriteRule \.css\.gz$ - [T=text/css,E=no-gzip:1]
        RewriteRule \.js\.gz$ - [T=text/javascript,E=no-gzip:1]

        <FilesMatch "(\.js\.gz|\.css\.gz)$">
          # Serve correct encoding type.
          Header set Content-Encoding gzip
          # Force proxies to cache gzipped & non-gzipped css/js files separately.
          Header append Vary Accept-Encoding
        </FilesMatch>
      </IfModule>
    </IfModule>

    # Add headers to all responses.
    <IfModule mod_headers.c>
      # Disable content sniffing, since it's an attack vector.
      Header always set X-Content-Type-Options nosniff
    </IfModule>
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
  sudo -u apache sh -c "echo \# > ${SITEPATH}/etc/srv_${SITE}.conf" || exit 1;
fi

## Allow apache to read its config
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "$SITEPATH/etc(/.*)?" || exit 1;
sudo restorecon -R "$SITEPATH/etc" || exit 1;

## Set perms
echo "Setting permissions for config files."
d7_perms.sh --sticky "$SITEPATH/etc"

sudo systemctl restart httpd || exit 1;
