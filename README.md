# Drupal 7 Ops Scripts, Makefiles, and Docs

# NB
* All of these want SELinux

## Initializing a new Drupal site
 
This script will install a new clean drupal install on the box you are on in the directory you indicate.
- Log into the box you want the clean install
- Run the script below. You need to indicate what the name of the directory should be. To do this, change the part after /srv/____ to the new directory name. A directory with the same name cannot exist.
 
```
d7_init.sh /srv/$site
```

- You will need the MYSQL password in Lastpass.
- In the end you will find your site at: http://____.webdev.libraries.ou.edu (lib-75 example)
- You will need to enable all the relevent modules and set the theme.

## Applying a Drush Makefile to sync code
 
Running this script will install the make script with our special drupal recipe. That includes the modules and libraries we use. This is the script you want to run to pull git updates down onto a site.
 - Log into box where you want to push our vesion of Drupal too.
 - Run the script below. Each library site will have its OWN make script. Use the notes below so that you run the right script. You must indicate the proper directory by changing the part after /srv/_____ to the directory you want to push the latest changes to.
 
 ```
d7_make.sh /srv/$site $makefile
```




## Syncing content (files and database) between sites
This will allow all content to be synced between sites.
- Log into the box you want to update
- Run the script below. Change the directory after /srv/_____ to the site you want to update.And change the box name at the end to the box you want to pull the changes from.
 
d7_sync.sh /srv/$site $remotehost
 
Example to update lib (document registry) so that it matches the content on Lib-75 

```
d7_sync.sh /srv/lib $lib-75
```


