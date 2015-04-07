# Drupal 7 Ops Scripts, Makefiles, and Docs

# NB
* All of these want SELinux

## Initializing a new Drupal site
 
This script will install a new clean drupal install on the box you are on in the directory you indicate.
- Log into the box you want the clean install
- Run the script below. You need to indicate what the name of the directory should be. To do this, change the part after /srv/____ to the new directory name. A directory with the same name cannot exist.
 
/opt/ltp/bootstrap_drupal.sh /srv/lib
 
- You will need the MYSQL password in Lastpass.
- In the end you will find your site at: http://____.webdev.libraries.ou.edu (lib-75 example)
- You will need to enable all the relevent modules and set the theme.

## Applying a Drush Makefile to sync code
 
Running this script will install the make script with our special drupal recipe. That includes the modules and libraries we use. This is the script you want to run to pull git updates down onto a site.
 - Log into box where you want to push our vesion of Drupal too.
 - Run the script below. Each library site will have its OWN make script. Use the notes below so that you run the right script. You must indicate the proper directory by changing the part after /srv/_____ to the directory you want to push the latest changes to.
 
 /opt/ltp/deploy_drupal.sh /srv/lib [add one of the make scripts below omiting the brackets in this message]
 
Document Registry Make Script 
https://gist.githubusercontent.com/jsnshrmn/d69d73570ffcb44776d9/raw/lib.make
 
Libraries Make Script
https://gist.githubusercontent.com/jsnshrmn/d208430e878b941fcb6c/raw/libraries.make
 
Example, update Document Registry:
/opt/ltp/deploy_drupal.sh /srv/lib https://gist.github.com/jsnshrmn/d69d73570ffcb44776d9/raw/lib.make
 
Example, update Libraries Main Site:
/opt/ltp/deploy_drupal.sh /srv/libraries https://gist.githubusercontent.com/jsnshrmn/d208430e878b941fcb6c/raw/libraries.make


## Syncing content (files and database) between sites
This will allow all content to be synced between sites.
- Log into the box you want to update
- Run the script below. Change the directory after /srv/_____ to the site you want to update.And change the box name at the end to the box you want to pull the changes from.
 
/opt/ltp/sync_drupal.sh /srv/lib lib-75
 
Example above would update lib (document registry) so that it matches the content on Lib-75 
