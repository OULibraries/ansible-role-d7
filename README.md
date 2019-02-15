OULibraries.d7
=========

OU Libraries Drupal Ops.

Role Variables
--------------

APC credentials, we don't set a default because security.
```
apc_username: apc
apc_password: password
```

For more, see defaults/main.yml

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

OU Libraries
