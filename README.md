# d7-ops
Drupal 7 Ops Scripts, Makefiles, and Docs

# Using LTP drupal utilities
All of these want SELinux

## Bootstrap to get a dumb drupal install

### Usage:
/opt/ltp/bootstrap_drupal.sh /srv/example

Expects a path.
Builds into 'drupal' subdir, eg. /srv/example/drupal  
Puts default site into 'default' subdir, eg. /srv/example/default  
settings.php and db install included.

## Deploy to get your modules, themes, etc added to sites/all

### Usage:
/opt/ltp/deploy_drupal.sh /srv/example /path/to/makefile/local/or/http

Expects a path and a makefile.  Leaves your default site alone, but blows away the Drupal codebase

## Sync to drag files and db from a remote Drupal site to a corresponding local site.

### Usage:
/opt/ltp/sync_drupal.sh /srv/example host-or-alias

Expects a path and a host. Can use ssh aliases.  
There should already be a Drupal site at the same path on the remote and local systems.
