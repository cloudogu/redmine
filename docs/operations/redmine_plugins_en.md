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


Removing a Redmine plugin is simple. To remove a plugin, one deletes or moves the directory of the corresponding plugin from Redmine's plugin directory. The next time Dogu is restarted, the removal will take effect.

When removing plugins, one should refrain from emptying or deleting Redmine's entire plugin directory. To rule out a defect after the restart, the following infrastructure-relevant plugins are backed up in the container image so that they can be restored if necessary:
- redmine_cas
- redmine_extended_rest_api
- redmine_activerecord_session_store

The `startup.sh` takes over the installation of the plugins in case one or more of the plugin directories have been deleted or moved.
