# Redmine plugins file management

Redmine can be extended with plugins. The management on the file level is simple.

## Adding new plugins

New plugins must be located as a directory inside the `plugins` volume of the Redmine Dogu. The path is

```
/var/lib/ces/redmine/volumes/plugins
```

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

To add a new plugin, copy the directory of the new plugin to Redmine's plugins volume. The next time the Dogu restarts, the plugin will be installed and can be used afterwards.

### Ruby Gem and an Internet connection

New plugins will most likely require additional Gem dependencies. Usually, these are delivered via https://rubygems.org.

In Cloudogu EcoSystem instances without Internet access available, this step is therefore **not easily possible**. One possible solution would be to copy the dependencies to the Ruby-Gem cache inside the container using `docker cp` and so on. Currently, the cache is located at `/usr/lib/ruby/gems/2.7.0`, but the location may change in feature releases. See `docker exec redmine gem environment` for more information.

Plugins included in the dogu by default are not affected since all required dependencies were installed during the docker image build.

## Removing plugins

The Redmine Dogu comes with an exposed command to uninstall plugins which can be executed via the cesapp. As the removal 
of installed plugins may result in database changes it is recommended to create a backup of the database beforce removing
the plugin.

The commend

```
cesapp command redmine delete-plugin <plugin name> --force
```

removes the plugin `<plugin name` completely from the current Redmine installation. To complete the uninstallation process,
you have to restart the Redmine Dogu once.

All plugins required to use Redmine will be installed or refreshed on each Dogu start:
- redmine_cas
- redmine_extended_rest_api
- redmine_activerecord_session_store

![UI](figures/uninstall_plugin_redmine.png)
