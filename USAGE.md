
### d7_cc.sh


```
d7_cc.sh clears all Drupal caches for a site, and clears the localhost apc cache.

Usage: d7_cc.sh $SITEPATH
            
$SITEPATH  Drupal site  (eg. /srv/example).
```

### d7_clean.sh


```
d7_clean.sh removes a Drupal site and the database it connects to.

Usage: d7_clean.sh $SITEPATH
            
$SITEPATH  Drupal site to remove (eg. /srv/example).
```

### d7_composer.sh

```
d7_composer.sh installs or updates composer-managed dependencies for a site.

Usage: d7_composer.sh $SITEPATH
            
$SITEPATH  Drupal site  (eg. /srv/example).
```

### d7_dump.sh


```
d7_dump.sh performs a dump of the database for a Drupal site.

Usage: d7_dump.sh $SITEPATH
            
$SITEPATH  Drupal site to sql dump (eg. /srv/example).
```

### d7_httpd_conf.sh


```
d7_httpd_conf.sh generates the Apache config for a site.

Usage: d7_httpd_conf.sh $SITEPATH
            
$SITEPATH  Drupal site.
```

### d7_importdb.sh


```
d7_importdb.sh imports a Drupal database file. 

Usage: d7_importdb.sh.sh $SITEPATH [$DBFILE]
            
$SITEPATH  Drupal site path
$DBFILE    Drupal database file to load

If $DBFILE is not given, then $SITEPATH/db/drupal_$SITE_dump.sql will be used.
```

### d7_init.sh


```
d7_init.sh builds a Drupal site.

Usage: d7_init.sh $SITEPATH
            
$SITEPATH  Destination for Drupal site (eg. /srv/example).
```

### d7_make.sh


```
d7_make.sh applies a Drupal makefile to a Drupal site. 

Usage: d7_init.sh $SITEPATH []
            
$SITEPATH  Drupal site (eg. /srv/example).
$MAKEFILE  URI of Drupal makefike. Can be a file:// uri.
```

### d7_migrate.sh


```
d7_migrate.sh migrates a site between hosts.

Usage: d7_migrate.sh $SITEPATH $SRCHOST $ORIGIN_SITEPATH

$SITEPATH          local Drupal path for new migrated site
$SRCHOST           host of site to migrate    
$ORIGIN_SITEPATH   path of site to migrate on $SRCHOST  
```

### d7_perms_fix.sh


```
d7_perms_fix.sh sets our preferred permissions for all Drupal paths in a site folder. 

Usage: d7_perms_fix.sh $SITEPATH

$SITEPATH   Site to apply permissions (eg. /srv/example).
```

### d7_perms.sh


```
d7_perms.sh sets our preferred permissions for a Drupal path. 

Usage: d7_perms.sh [--sticky] $DIR
            
--sticky    Optional argument adds group write with sticky bit. 
            This is the default behavior for dev environments.  
$INPUTDIR      Folder to modify (eg. /srv/example/drupal).
```

### d7_restore.sh


```
d7_restore.sh restores an existing site snapshot backup.

Usage: d7_restore.sh $SITEPATH $DOW

$SITEPATH   path to Drupal site to restore
$DOW        lowercase day-of-week abbreviation indicating backup 
             to restore. Must be one of sun, mon, tue, wed, thu, fri, or sat.
```

### d7_snapshot.sh


```
d7_snapshot.sh creates a db dump and tar backup for a site.

Usage: d7_snapshot.sh $SITEPATH
            
$SITEPATH   Drupal site to tar (eg. /srv/example).

Backups will be stored at /snapshots/..tar.gz.  is
the lowercase day-of-week abbreviation for the current day.
```

### d7_sync.sh


```
d7_synch.sh syncs content files and database from a remote site to a
local Drupal site, creating it if it doesn't exist.

Usage: d7_sync.sh $SITEPATH $SRCHOST [$ORIGIN_SITEPATH]
    
$SITEPATH         local target of the sync
$SRCHOST          host from which to sync  
$ORIGIN_SITEPATH  optional argument, path to sync on the remote host. 
                   $SITEPATH will be used if a different  
                   is not specified. 
```

### d7_update.sh


```
d7_update.sh applies security (only) updates to a drupal site.

Usage: d7_update.sh $SITEPATH
            
$SITEPATH   Drupal site to update.
```
