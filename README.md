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

Requires OU Libraries centos7, mariadb, and apache2 roles. To install:
```
ansible-galaxy install -r requirements.yml
```

Script Usage
----------------

See the [Usage](./USAGE.md) file for basic usage information.


License
-------

TBD

Author Information
------------------

Jason Sherman
