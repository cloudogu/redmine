# Developer notes on the CAS plugin and the session store.
Since Redmine 5.x and the associated change to Rails 6, something was changed in the initialization mechanism of the plugins.
This resulted in the `redmine_activerecord_session_store` plugin no longer being able to run on its own.
The configuration of the session store was no longer attracted.
For this it was necessary to add the `resources/usr/share/webapps/redmine/config/initializers/session_store.rb` additionally.
Without this with the call `Rails.application.config.session_store :active_record_store` the session store was no longer recognized by Redmine.
This configuration is important for the backchannel logout to work with Redmine. In case of further developments and problems that might occur
problems, it could be useful to revise this mechanism again.