OULibraries.d7
=========

OU Libraries Drupal Ops.

Role Variables
--------------

See defaults/main.yml

Dependencies
------------

Requires OU Libraries centos7, mariadb, and apache2 roles. To install:
```
ansible-galaxy install -r requirements.yml
```

Script Usage
----------------

## To initize a new Drupal site

```
d7_init.sh /srv/$site
```

This script will install a fresh Drupal site.
* Accepts a path as its sole argument and will install the site at that location. 
* You will be prompted for MySQL root credentials.
* You will find your site at: http://____.$hostname
* You will need to enable all the relevent modules and set the theme.

## To apply a Drush Makefile to sync code

```
d7_make.sh /srv/$site $makefile
```
This script will apply a Drush Makefile.
* You will need to specify the path to an existing Drupal site and the path or url of a Drush Makefile.
* Libraries and Drupal modules and themes will be replaced with those specified in the Makefile, but neither database content, nor your `sites/default` folder will be modified.

The [`make`](./make) directory of this repository contains our Makefiles. 

## To dump the DB of a Drupal site

```
d7_dump.sh /srv/$site
```

This script will dump the db in /srv/$site/db. Some of the other scripts also call this script to allow you to revert changes should something go wrong.


## To sync content (files and database) between sites

```
d7_sync.sh /srv/$site $remotehost
```

This script will sync content *to* a local site *from* a remote host
* you will need to specify a path and a remote host. 
* Sites on both the local and remote host be at the same path. 


## To delete site (files and database)

```
d7_clean.sh /srv/$site
```

Don't do this accidentally.

License
-------

TBD

Author Information
------------------

Jason Sherman
