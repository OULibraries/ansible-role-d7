OULibraries.d7
=========

OU Libraries Drupal Ops.

Role Variables
--------------

This role has quite a few variables. A few of the most frequently
adjusted are listed below:

### General PHP Config

```yaml
# Drupal related settings
d7_memory_limit: "128M"
d7_upload_max_filesize: "64M"
d7_post_max_size: "70M"
d7_date_timezone: "America/Chicago"
```
### PHP caching:

```yaml
# Set to 1 to enable Zend OpCache for PHP
d7_opcache_enable: "0"

# Set to 1 to enable Zend OpCache for CLI PHP
d7_opcache_enable_cli: "0"

```

For more variables, see `defaults/main.yml`.


Dependencies
------------

Requires OU Libraries centos7, mariadb, apache2, and users roles. To install:
```
ansible-galaxy install -r requirements.yml
```

Script Usage
----------------

To create an empty Drupal site:

```
d7_init.sh /srv/example
```

To install Drupal modules based on a makefile and sync with an existing site:

```
d7_make.sh /srv/example $MAKEURI
d7_sync.sh /srv/example $SRCHOST
d7_cc.ss /srv/example

```

See the full [USAGE](./USAGE.md) file for more usage information.


License
-------

[MIT](https://github.com/OULibraries/ansible-role-d7/blob/master/LICENSE)

Author Information
------------------

Jason Sherman
