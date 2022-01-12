# Redmine plugins file management

Redmine can be extended with plugins. The management on the file level is simple.

## Adding new plugins

New plugins must be located as a directory below Redmine's plugin directory. The paths are
- in the container `/usr/share/webapps/redmine/plugins_prod`
- in the Cloudogu EcoSystem `/var/lib/ces/redmine/volumes/plugins_prod`.

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

### Ruby Gem and an Internet connection

New plugins will most likely require additional Gem dependencies. Usually, these are delivered via https://rubygems.org.

In Cloudogu EcoSystem instances without Internet access, this step is therefore **not easily possible**. One possible solution would be to copy the dependencies to the Ruby-Gem cache inside the container using `docker cp` and so on. Currently the cache is located at `/usr/lib/ruby/gems/2.7.0`, but the location may change in further releases. See `docker exec redmine gem environment` for more information.

For plugins included in the dogu, no internet connection is needed, since this was already done during image building and Ruby apparently does not complain if the sums are correct.

## Removing plugins

Removing a Redmine plugin is easy. There is an exposed command that can be called via the cesapp. As the removal of the 
plugin may also result in changes to the database, it is recommended to make a backup of the database before removing 
the plugin.

The cesapp command is `cesapp command redmine delete-plugin <plugin name>`. To complete the removal of the plugin, the 
Dogu must be restarted once after executing the command.

To rule out a defect after the restart, the following infrastructure-relevant plugins are saved in the container image 
so that they can be restored if necessary:
- redmine_cas
- redmine_extended_rest_api
- redmine_activerecord_session_store