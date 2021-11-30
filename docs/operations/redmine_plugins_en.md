# Redmine plugins file management

Redmine can be extended with plugins. The management on the file level is simple.

## Adding new plugins

New plugins must be located as a directory below Redmine's plugin directory. The paths are
- in the container `/usr/share/webapps/redmine/plugins`
- in the Cloudogu EcoSystem `/var/lib/ces/redmine/volumes/plugins`.

Example directory view using the CAS plugin:

```
/var/lib/ces/redmine/volumes/plugins/
├─ redmine_cas/
   ├─ app
      ├─ ...
   ├─ config
      ├─ ...
   ├─ lib
      ├─ ...
   ├─ Gemfile
   ├─ init.rb
```

To add a new plugin, just copy the directory of the new plugin to Redmine's plugin directory. The next time the Dogu restarts, the plugin change will take effect.

## Removing plugins


Removing a Redmine plugin is simple. To remove a plugin, one deletes or moves the directory of the corresponding plugin from Redmine's plugin directory. The next time Dogu is restarted, the removal will take effect.

When removing plugins, one should refrain from emptying or deleting Redmine's entire plugin directory. To rule out a defect after the restart, the following infrastructure-relevant plugins are backed up in the container image so that they can be restored if necessary:
- redmine_cas
- redmine_extended_rest_api
- redmine_activerecord_session_store

The `startup.sh` takes over the installation of the plugins in case one or more of the plugin directories have been deleted or moved.
