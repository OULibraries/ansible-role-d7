# Drupal 7 Ops Scripts, Makefiles, and Docs

## NB
* All of these want SELinux
* All of these commands should be run from the host where you want the change to occur.


## To install these tools

Clone this repository and add it to your path. 


## To initize a new Drupal site

```
d7_init.sh /srv/$site
```

This script will install a fresh Drupal site.
* This command path as it's single argument and will install the site at that location. 
* You will need the MYSQL password in Lastpass.
* In the end you will find your site at: http://____.$hostname
* You will need to enable all the relevent modules and set the theme.

## To apply a Drush Makefile to sync code

```
d7_make.sh /srv/$site $makefile
```
This script will apply a Drush Makefile.
* You will need to specify the path to an existing Drupal site and the path or url of a Drush Makefile.
* Libraries and Drupal modules and themes will be replaced with those specified in the Makefile, but neither database content, nor your `sites/default` folder will be modified.

The `make` directory of this repository contains our Makefiles. 




## To sync content (files and database) between sites

```
d7_sync.sh /srv/$site $remotehost
```

This scrypt will sync content *to* a local site *from* a remote host
* you will need to specify a path and a remote host. 
* Sites on both the local and remote host be at the same path. 



