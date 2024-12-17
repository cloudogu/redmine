# Redmine ActiveRecord Session Store plugin

This plugin teaches Redmine to use ActiveRecord as session store. Session data is no longer stored in the cookie but instead in your database. Only a session ID is stored on the client which minifies the overall request size.

## Compatibilty

Patched from original (https://github.com/pencil/redmine_activerecord_session_store) to work with Redmine 4+

Tested with Redmine 5.0.5, but should be working fine with Redmine 4.x and possibly older versions too.

## Installation

1. Download or clone this repository and place it in the Redmine plugin directory
2. Run the plugin migrations (`rake redmine:plugins:migrate RAILS_ENV=production`)
3. Restart your webserver
4. Open Redmine and check if the plugin is visible under Administration > Plugins
5. Party

## Usage

It's all done automagically. Nothing to setup!
