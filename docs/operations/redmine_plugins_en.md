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

Removing a Redmine plugin is easy. To remove a plugin, delete or move the directory of the corresponding plugin from Redmine's plugin directory. The next time the Dogu restarts, the plugin removal will take effect.

**Caution:**

When removing plugins, be very careful not to empty or delete Redmine's entire plugin directory. Also, critical infrastructure plugins (especially the Redmine CAS plugin / `redmine_cas`) must not be deleted, as this will result in a broken dogu. A common characteristic is an unfamiliar login screen or the inability to log in to Redmine via CAS.
